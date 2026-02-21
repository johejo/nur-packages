#!/usr/bin/env bun
import { $ } from "bun";
import { mkdir, rename } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";

type DecodeKind = "json" | "toml" | "yaml" | "nix" | "html";

type HtmlSelector = {
  selector: string;
  attr?: string;
};

type RuleConfig = {
  file: string;
  decode: DecodeKind;
  query?: string;
  selectors?: HtmlSelector[];
};

type PackageRule = { profile: string } & Partial<RuleConfig>;

type Rules = {
  profiles: Record<string, RuleConfig>;
  packages: Record<string, PackageRule>;
};

type GeneratedSources = Record<string, { version?: string }>;

type PackageMeta = {
  profile: string;
  version: string | null;
  description: string | null;
  source:
    | {
        file: string;
        decode: "html";
        selectors: HtmlSelector[];
      }
    | {
        file: string;
        decode: Exclude<DecodeKind, "html">;
        query: string;
      };
};

type ResolvedRule = {
  profileName: string;
  rule:
    | {
        file: string;
        decode: "html";
        selectors: HtmlSelector[];
      }
    | {
        file: string;
        decode: Exclude<DecodeKind, "html">;
        query: string;
      };
};

const scriptPath = fileURLToPath(import.meta.url);
const rootDir = path.dirname(scriptPath);

function usage(): void {
  console.log(`Usage: bun ./update-source-meta.ts [options]

Options:
  --rules <path>       Rules file path (default: meta-rules.json)
  --out <path>         Output path (default: _sources/meta.json)
  -h, --help           Show this help`);
}

function fail(message: string): never {
  console.error(`error: ${message}`);
  process.exit(1);
}

async function loadJsonFile<T>(filePath: string): Promise<T> {
  const raw = await Bun.file(filePath).text();
  return JSON.parse(raw) as T;
}

async function fileExists(filePath: string): Promise<boolean> {
  return Bun.file(filePath).exists();
}

async function decodeNixFile(filePath: string): Promise<unknown> {
  const expr = `
    let
      sanitize =
        value:
          if builtins.isAttrs value then
            builtins.listToAttrs (
              builtins.concatMap
                (name:
                  let v = value.\${name}; in
                  if builtins.isFunction v then
                    [ ]
                  else
                    [ { inherit name; value = sanitize v; } ])
                (builtins.attrNames value)
            )
          else if builtins.isList value then
            map sanitize value
          else if builtins.isPath value then
            builtins.toString value
          else
            value;
    in
      sanitize (import (builtins.toPath ${JSON.stringify(filePath)}))
  `;
  const out = await $.cwd(rootDir)`nix eval --json --impure --expr ${expr}`.quiet();
  return JSON.parse(await out.text());
}

function extractHtmlDescription(
  raw: string,
  selectors: HtmlSelector[],
  pkg: string,
): string {
  for (const selector of selectors) {
    const attr = selector.attr ?? "content";
    let value: string | null = null;
    new HTMLRewriter()
      .on(selector.selector, {
        element(el) {
          if (value !== null) {
            return;
          }
          const candidate = el.getAttribute(attr)?.trim();
          if (candidate) {
            value = candidate;
          }
        },
      })
      .transform(new Response(raw));
    if (value !== null) {
      return value;
    }
  }

  throw new Error(
    `package '${pkg}' html selectors did not match any non-empty value`,
  );
}

function resolvePackageRule(
  pkg: string,
  pkgRule: PackageRule | undefined,
  rules: Rules,
): ResolvedRule | null {
  if (!pkgRule) {
    return null;
  }
  if (typeof pkgRule !== "object" || pkgRule === null) {
    console.error(
      `warning: package '${pkg}' has unsupported rule type; object is required`,
    );
    return null;
  }

  const profileName = pkgRule.profile ?? "";
  if (!profileName) {
    console.error(
      `warning: package '${pkg}' has object rule but no profile; skipping`,
    );
    return null;
  }

  const baseProfile = rules.profiles[profileName];
  if (!baseProfile) {
    console.error(
      `warning: package '${pkg}' references unknown profile '${profileName}'; skipping`,
    );
    return null;
  }

  const rule: RuleConfig = {
    ...baseProfile,
    ...(pkgRule.file !== undefined ? { file: pkgRule.file } : {}),
    ...(pkgRule.decode !== undefined ? { decode: pkgRule.decode } : {}),
    ...(pkgRule.query !== undefined ? { query: pkgRule.query } : {}),
    ...(pkgRule.selectors !== undefined ? { selectors: pkgRule.selectors } : {}),
  };
  if (!rule.file) {
    console.error(`warning: package '${pkg}' resolved rule has no file; skipping`);
    return null;
  }

  if (rule.decode === "html") {
    if (rule.query !== undefined) {
      throw new Error(
        `package '${pkg}' uses decode=html but query is not supported; use selectors instead`,
      );
    }
    const selectors = rule.selectors;
    if (!selectors || selectors.length === 0) {
      throw new Error(
        `package '${pkg}' uses decode=html but selectors are missing`,
      );
    }
    for (const selector of selectors) {
      if (!selector || typeof selector.selector !== "string" || !selector.selector) {
        throw new Error(`package '${pkg}' has an invalid html selector entry`);
      }
      if (
        selector.attr !== undefined
        && (typeof selector.attr !== "string" || !selector.attr)
      ) {
        throw new Error(
          `package '${pkg}' has an invalid html selector attr`,
        );
      }
    }
    return {
      profileName,
      rule: {
        file: rule.file,
        decode: "html",
        selectors,
      },
    };
  }

  if (rule.selectors !== undefined) {
    throw new Error(
      `package '${pkg}' uses selectors with decode=${rule.decode}; selectors are supported only for html`,
    );
  }
  if (!rule.query) {
    throw new Error(
      `package '${pkg}' uses decode=${rule.decode} but query is missing`,
    );
  }

  return {
    profileName,
    rule: {
      file: rule.file,
      decode: rule.decode,
      query: rule.query,
    },
  };
}

async function resolveSourceOutPath(pkg: string): Promise<string> {
  const expr = `
    let
      flake = builtins.getFlake (toString ./.);
      pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; };
      sources = pkgs.callPackage ./_sources/generated.nix { };
    in
      (builtins.getAttr ${JSON.stringify(pkg)} sources).src
  `;
  const srcResult = await $.cwd(rootDir)`nix build --no-link --print-out-paths --impure --expr ${expr}`.quiet();
  return (await srcResult.text()).trim();
}

async function extractDescription(
  pkg: string,
  rule: ResolvedRule["rule"],
  sourceFile: string,
): Promise<string> {
  if (!(await fileExists(sourceFile))) {
    throw new Error(`package '${pkg}' file not found: ${sourceFile}`);
  }

  const raw = await Bun.file(sourceFile).text();
  let decoded: unknown;
  switch (rule.decode) {
    case "html":
      return extractHtmlDescription(raw, rule.selectors, pkg);
    case "json":
      decoded = JSON.parse(raw);
      break;
    case "toml":
      decoded = Bun.TOML.parse(raw);
      break;
    case "yaml":
      decoded = Bun.YAML.parse(raw);
      break;
    case "nix":
      decoded = await decodeNixFile(sourceFile);
      break;
    default:
      throw new Error(`package '${pkg}' has unsupported decode: ${rule.decode}`);
  }

  const jqExpr = `${rule.query} | if . == null then empty elif type == "string" then . else tostring end`;
  const jqResult = await $`printf %s ${JSON.stringify(decoded)} | jq -er ${jqExpr}`.quiet();
  return (await jqResult.text()).trimEnd();
}

async function processPackage(
  pkg: string,
  rules: Rules,
  generated: GeneratedSources,
): Promise<PackageMeta | null> {
  const resolvedRule = resolvePackageRule(pkg, rules.packages[pkg], rules);
  if (!resolvedRule) {
    return null;
  }

  const { profileName, rule } = resolvedRule;
  console.log(`Processing ${pkg}...`);

  const srcOutPath = await resolveSourceOutPath(pkg);
  const sourceFile = path.join(srcOutPath, rule.file);
  const version = generated[pkg]?.version ?? null;
  const description = await extractDescription(pkg, rule, sourceFile);

  return {
    profile: profileName,
    version,
    description,
    source:
      rule.decode === "html"
        ? {
            file: rule.file,
            decode: "html",
            selectors: rule.selectors,
          }
        : {
            file: rule.file,
            decode: rule.decode,
            query: rule.query,
          },
  };
}

async function main(): Promise<void> {
  let parsed:
    | ReturnType<typeof parseArgs<{
        rules: { type: "string" };
        out: { type: "string" };
        help: { type: "boolean"; short: "h" };
      }>>
    | undefined;
  try {
    parsed = parseArgs({
      args: Bun.argv.slice(2),
      options: {
        rules: { type: "string" },
        out: { type: "string" },
        help: { type: "boolean", short: "h" },
      },
      strict: true,
      allowPositionals: false,
    });
  } catch (error) {
    usage();
    fail(error instanceof Error ? error.message : String(error));
  }

  if (parsed.values.help) {
    usage();
    return;
  }

  const rulesFile = parsed.values.rules
    ? path.resolve(rootDir, parsed.values.rules)
    : path.join(rootDir, "meta-rules.json");
  const outFile = parsed.values.out
    ? path.resolve(rootDir, parsed.values.out)
    : path.join(rootDir, "_sources", "meta.json");

  const nvfetcherFile = path.join(rootDir, "nvfetcher.toml");
  const generatedJsonFile = path.join(rootDir, "_sources", "generated.json");

  if (!Bun.which("jq")) {
    fail("required command not found: jq");
  }
  if (!Bun.which("nix")) {
    fail("required command not found: nix");
  }
  if (!(await fileExists(nvfetcherFile))) {
    fail(`nvfetcher.toml not found: ${nvfetcherFile}`);
  }
  if (!(await fileExists(rulesFile))) {
    fail(`rules file not found: ${rulesFile}`);
  }
  if (!(await fileExists(generatedJsonFile))) {
    fail(`generated source file not found: ${generatedJsonFile}`);
  }

  const rules = await loadJsonFile<Rules>(rulesFile);
  const generated = await loadJsonFile<GeneratedSources>(generatedJsonFile);

  const nvfetcherToml = await Bun.file(nvfetcherFile).text();
  const nvfetcherConfig = Bun.TOML.parse(nvfetcherToml) as Record<string, unknown>;
  const nvfetcherPackages = Object.keys(nvfetcherConfig);
  if (nvfetcherPackages.length === 0) {
    fail(`no package sections were found in ${nvfetcherFile}`);
  }

  const nvfetcherSet = new Set(nvfetcherPackages);
  for (const pkg of Object.keys(rules.packages)) {
    if (!nvfetcherSet.has(pkg)) {
      console.error(
        `warning: package '${pkg}' exists in rules but not in nvfetcher.toml; skipping`,
      );
    }
  }

  const packages: Record<string, unknown> = {};
  let processed = 0;
  let skipped = 0;

  for (const pkg of nvfetcherPackages) {
    const packageMeta = await processPackage(pkg, rules, generated);
    if (!packageMeta) {
      skipped += 1;
      continue;
    }
    packages[pkg] = packageMeta;
    processed += 1;
  }

  await mkdir(path.dirname(outFile), { recursive: true });
  const tmpFile = path.join(
    path.dirname(outFile),
    `.meta.${process.pid}.${Date.now()}.tmp`,
  );
  await Bun.write(
    tmpFile,
    JSON.stringify(
      {
        packages,
      },
      null,
      2,
    ) + "\n",
  );
  await rename(tmpFile, outFile);

  console.log(`Wrote: ${outFile}`);
  console.log(`Processed: ${processed}, skipped: ${skipped}`);
}

main().catch((error: unknown) => {
  fail(error instanceof Error ? error.message : String(error));
});
