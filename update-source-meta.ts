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

type FieldRule =
  | {
      query: string;
      selectors?: never;
    }
  | {
      selectors: HtmlSelector[];
      query?: never;
    };

type RuleFields = Record<string, FieldRule>;

type RuleConfig = {
  file: string;
  decode: DecodeKind;
  fields: RuleFields;
};

type PackageRule = {
  profile: string;
  file?: string;
  decode?: DecodeKind;
  fields?: RuleFields;
};

type Rules = {
  profiles: Record<string, RuleConfig>;
  packages: Record<string, PackageRule>;
};

type GeneratedSource = {
  version?: string;
  src?: {
    type?: string;
    rev?: string;
    owner?: string;
    repo?: string;
    url?: string;
  };
};

type GeneratedSources = Record<string, GeneratedSource>;

type PackageMeta = {
  version: string | null;
  git: {
    ref: string | null;
    commit: string | null;
  };
  profile?: string;
  fields?: Record<string, string>;
  source?:
    | {
        file: string;
        decode: "html";
        fields: RuleFields;
      }
    | {
        file: string;
        decode: Exclude<DecodeKind, "html">;
        fields: RuleFields;
      };
};

type ResolvedRule = {
  profileName: string;
  rule:
    | {
        file: string;
        decode: "html";
        fields: RuleFields;
      }
    | {
        file: string;
        decode: Exclude<DecodeKind, "html">;
        fields: RuleFields;
      };
};

const scriptPath = fileURLToPath(import.meta.url);
const rootDir = path.dirname(scriptPath);
const DECODE_KINDS = new Set<DecodeKind>(["json", "toml", "yaml", "nix", "html"]);

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

function isGitCommitHash(value: string): boolean {
  return /^[0-9a-f]{40}$/i.test(value);
}

function isDecodeKind(value: unknown): value is DecodeKind {
  return typeof value === "string" && DECODE_KINDS.has(value as DecodeKind);
}

function isNonNullObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
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
            builtins.mapAttrs (_: sanitize) (
              builtins.removeAttrs value (
                builtins.filter
                  (name: builtins.isFunction value.\${name})
                  (builtins.attrNames value)
              )
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

async function resolveGitMeta(
  pkg: string,
  generatedSource: GeneratedSource | undefined,
): Promise<{ ref: string | null; commit: string | null }> {
  const ref = generatedSource?.src?.rev ?? null;
  if (!ref) {
    return { ref: null, commit: null };
  }
  if (isGitCommitHash(ref)) {
    return { ref, commit: ref };
  }

  const src = generatedSource?.src;
  if (src?.type === "github" && src.owner && src.repo) {
    if (!Bun.which("gh")) {
      throw new Error(
        `package '${pkg}' requires gh to resolve commit from ref '${ref}'`,
      );
    }
    const resolved = (
      await (
        await $`gh api repos/${src.owner}/${src.repo}/commits/${ref} --jq .sha`.quiet()
      ).text()
    ).trim();
    if (!isGitCommitHash(resolved)) {
      throw new Error(
        `package '${pkg}' resolved non-commit value from GitHub API: '${resolved}'`,
      );
    }
    return { ref, commit: resolved };
  }

  return { ref, commit: null };
}

function resolveFallbackHomepage(
  generatedSource: GeneratedSource | undefined,
): string | null {
  const src = generatedSource?.src;
  if (src?.type === "github" && src.owner && src.repo) {
    return `https://github.com/${src.owner}/${src.repo}`;
  }
  return null;
}

function extractHtmlDescription(
  raw: string,
  selectors: HtmlSelector[],
  pkg: string,
  fieldName: string,
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
    `package '${pkg}' field '${fieldName}' html selectors did not match any non-empty value`,
  );
}

function normalizeFields(
  pkg: string,
  decode: DecodeKind,
  fieldsValue: unknown,
): RuleFields {
  if (!isNonNullObject(fieldsValue)) {
    throw new Error(`package '${pkg}' resolved rule has invalid fields object`);
  }

  const fields: RuleFields = {};
  for (const [fieldName, value] of Object.entries(fieldsValue)) {
    if (!isNonNullObject(value)) {
      throw new Error(`package '${pkg}' field '${fieldName}' must be an object`);
    }

    const query = value.query;
    const selectorsValue = value.selectors;
    if (decode === "html") {
      if (query !== undefined) {
        throw new Error(
          `package '${pkg}' field '${fieldName}' uses decode=html but query is not supported`,
        );
      }
      if (!Array.isArray(selectorsValue) || selectorsValue.length === 0) {
        throw new Error(
          `package '${pkg}' field '${fieldName}' uses decode=html but selectors are missing`,
        );
      }

      const selectors: HtmlSelector[] = [];
      for (const selector of selectorsValue) {
        if (
          !isNonNullObject(selector)
          || typeof selector.selector !== "string"
          || !selector.selector
        ) {
          throw new Error(
            `package '${pkg}' field '${fieldName}' has invalid selector entry`,
          );
        }

        const attr = selector.attr;
        if (attr !== undefined && (typeof attr !== "string" || !attr)) {
          throw new Error(
            `package '${pkg}' field '${fieldName}' has invalid selector attr`,
          );
        }
        selectors.push(
          attr === undefined
            ? { selector: selector.selector }
            : { selector: selector.selector, attr },
        );
      }
      fields[fieldName] = { selectors };
      continue;
    }

    if (selectorsValue !== undefined) {
      throw new Error(
        `package '${pkg}' field '${fieldName}' uses selectors with decode=${decode}; selectors are supported only for html`,
      );
    }
    if (typeof query !== "string" || !query) {
      throw new Error(
        `package '${pkg}' field '${fieldName}' uses decode=${decode} but query is missing`,
      );
    }
    fields[fieldName] = { query };
  }

  if (Object.keys(fields).length === 0) {
    throw new Error(`package '${pkg}' resolved rule has no fields`);
  }
  return fields;
}

function resolvePackageRule(
  pkg: string,
  pkgRule: PackageRule | undefined,
  rules: Rules,
): ResolvedRule | null {
  if (!pkgRule) {
    return null;
  }
  if (!isNonNullObject(pkgRule)) {
    console.error(
      `warning: package '${pkg}' has unsupported rule type; object is required`,
    );
    return null;
  }

  for (const key of Object.keys(pkgRule)) {
    if (key !== "profile" && key !== "file" && key !== "decode" && key !== "fields") {
      throw new Error(`package '${pkg}' has unsupported key '${key}'`);
    }
  }

  if (typeof pkgRule.profile !== "string" || !pkgRule.profile) {
    console.error(
      `warning: package '${pkg}' has object rule but no profile; skipping`,
    );
    return null;
  }
  const profileName = pkgRule.profile;

  const baseProfile = rules.profiles[profileName];
  if (!baseProfile) {
    console.error(
      `warning: package '${pkg}' references unknown profile '${profileName}'; skipping`,
    );
    return null;
  }

  if (!isNonNullObject(baseProfile)) {
    throw new Error(`profile '${profileName}' must be an object`);
  }
  if (typeof baseProfile.file !== "string" || !baseProfile.file) {
    throw new Error(`profile '${profileName}' has invalid file`);
  }
  if (!isDecodeKind(baseProfile.decode)) {
    throw new Error(`profile '${profileName}' has invalid decode`);
  }
  if (!isNonNullObject(baseProfile.fields)) {
    throw new Error(`profile '${profileName}' has invalid fields`);
  }

  if (
    pkgRule.file !== undefined
    && (typeof pkgRule.file !== "string" || !pkgRule.file)
  ) {
    throw new Error(`package '${pkg}' has invalid file`);
  }
  if (pkgRule.decode !== undefined && !isDecodeKind(pkgRule.decode)) {
    throw new Error(`package '${pkg}' has invalid decode`);
  }
  if (pkgRule.fields !== undefined && !isNonNullObject(pkgRule.fields)) {
    throw new Error(`package '${pkg}' has invalid fields override`);
  }

  const decode = pkgRule.decode ?? baseProfile.decode;
  const file = pkgRule.file ?? baseProfile.file;
  const fields = normalizeFields(pkg, decode, {
    ...baseProfile.fields,
    ...(pkgRule.fields ?? {}),
  });

  if (decode === "html") {
    return {
      profileName,
      rule: {
        file,
        decode: "html",
        fields,
      },
    };
  }

  return {
    profileName,
    rule: {
      file,
      decode,
      fields,
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

async function extractFields(
  pkg: string,
  rule: ResolvedRule["rule"],
  sourceFile: string,
  fallbackFields: Partial<Record<string, string>>,
): Promise<Record<string, string>> {
  if (!(await fileExists(sourceFile))) {
    throw new Error(`package '${pkg}' file not found: ${sourceFile}`);
  }

  const raw = await Bun.file(sourceFile).text();
  const fields: Record<string, string> = {};
  switch (rule.decode) {
    case "html": {
      for (const [fieldName, fieldRule] of Object.entries(rule.fields)) {
        if (!("selectors" in fieldRule)) {
          throw new Error(
            `package '${pkg}' field '${fieldName}' is invalid for decode=html`,
          );
        }
        try {
          fields[fieldName] = extractHtmlDescription(
            raw,
            fieldRule.selectors,
            pkg,
            fieldName,
          );
        } catch (error) {
          const fallback = fallbackFields[fieldName];
          if (!fallback) {
            throw error;
          }
          fields[fieldName] = fallback;
        }
      }
      return fields;
    }
    case "json":
    case "toml":
    case "yaml":
    case "nix":
      break;
    default:
      throw new Error(`package '${pkg}' has unsupported decode: ${rule.decode}`);
  }

  let decoded: unknown;
  switch (rule.decode) {
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

  for (const [fieldName, fieldRule] of Object.entries(rule.fields)) {
    if (!("query" in fieldRule)) {
      throw new Error(
        `package '${pkg}' field '${fieldName}' is invalid for decode=${rule.decode}`,
      );
    }
    const jqExpr = `${fieldRule.query} | if . == null then empty elif type == "string" then . else tostring end`;
    try {
      const jqResult = await $`printf %s ${JSON.stringify(decoded)} | jq -er ${jqExpr}`.quiet();
      const value = (await jqResult.text()).trim();
      if (!value) {
        const fallback = fallbackFields[fieldName];
        if (!fallback) {
          throw new Error(
            `package '${pkg}' field '${fieldName}' query returned empty value`,
          );
        }
        fields[fieldName] = fallback;
        continue;
      }
      fields[fieldName] = value;
    } catch (error) {
      const fallback = fallbackFields[fieldName];
      if (!fallback) {
        throw error;
      }
      fields[fieldName] = fallback;
    }
  }

  return fields;
}

async function processPackage(
  pkg: string,
  rules: Rules,
  generated: GeneratedSources,
): Promise<PackageMeta> {
  const generatedSource = generated[pkg];
  const version = generatedSource?.version ?? null;
  const git = await resolveGitMeta(pkg, generatedSource);
  const fallbackHomepage = resolveFallbackHomepage(generatedSource);
  const fallbackFields = fallbackHomepage ? { homepage: fallbackHomepage } : {};

  const resolvedRule = resolvePackageRule(pkg, rules.packages[pkg], rules);
  if (!resolvedRule) {
    if (fallbackHomepage) {
      return {
        version,
        git,
        fields: {
          homepage: fallbackHomepage,
        },
      };
    }
    return { version, git };
  }

  const { profileName, rule } = resolvedRule;
  console.log(`Processing ${pkg}...`);

  const srcOutPath = await resolveSourceOutPath(pkg);
  const sourceFile = path.join(srcOutPath, rule.file);
  const fields = await extractFields(pkg, rule, sourceFile, fallbackFields);
  if (fields.homepage === undefined && fallbackHomepage) {
    fields.homepage = fallbackHomepage;
  }

  return {
    profile: profileName,
    version,
    git,
    fields,
    source:
      rule.decode === "html"
        ? {
            file: rule.file,
            decode: "html",
            fields: rule.fields,
          }
        : {
            file: rule.file,
            decode: rule.decode,
            fields: rule.fields,
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
  let withFields = 0;

  for (const pkg of nvfetcherPackages) {
    const packageMeta = await processPackage(pkg, rules, generated);
    if (packageMeta.fields !== undefined) {
      withFields += 1;
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
  console.log(`Processed: ${processed}, withFields: ${withFields}`);
}

main().catch((error: unknown) => {
  fail(error instanceof Error ? error.message : String(error));
});
