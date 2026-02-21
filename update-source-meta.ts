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

type StructuredDecodeKind = Exclude<DecodeKind, "html">;

type CliOptions = {
  help: boolean;
  rulesFile: string;
  outFile: string;
};

type InputPaths = {
  rulesFile: string;
  outFile: string;
  nvfetcherFile: string;
  generatedJsonFile: string;
};

type LoadedInputs = {
  rules: Rules;
  generated: GeneratedSources;
  nvfetcherPackages: string[];
};

type BuildMetaResult = {
  packages: Record<string, PackageMeta>;
  processed: number;
  withFields: number;
};

const scriptPath = fileURLToPath(import.meta.url);
const rootDir = path.dirname(scriptPath);
const DECODE_KINDS = new Set<DecodeKind>(["json", "toml", "yaml", "nix", "html"]);

function resolveOutputPath(pathOrDefault: string | undefined, fallback: string): string {
  return pathOrDefault ? path.resolve(rootDir, pathOrDefault) : fallback;
}

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

function parseCliOptions(args: string[]): CliOptions {
  try {
    const parsed = parseArgs({
      args,
      options: {
        rules: { type: "string" },
        out: { type: "string" },
        help: { type: "boolean", short: "h" },
      },
      strict: true,
      allowPositionals: false,
    });
    return {
      help: Boolean(parsed.values.help),
      rulesFile: resolveOutputPath(
        parsed.values.rules,
        path.join(rootDir, "meta-rules.json"),
      ),
      outFile: resolveOutputPath(
        parsed.values.out,
        path.join(rootDir, "_sources", "meta.json"),
      ),
    };
  } catch (error) {
    usage();
    fail(error instanceof Error ? error.message : String(error));
  }
}

function resolveInputPaths(cli: CliOptions): InputPaths {
  return {
    rulesFile: cli.rulesFile,
    outFile: cli.outFile,
    nvfetcherFile: path.join(rootDir, "nvfetcher.toml"),
    generatedJsonFile: path.join(rootDir, "_sources", "generated.json"),
  };
}

function isGitCommitHash(value: string): boolean {
  return /^[0-9a-f]{40}$/i.test(value);
}

function normalizeRepoName(repo: string): string {
  return repo.replace(/\.git$/i, "");
}

function parseGithubOwnerRepoFromUrl(urlValue: string): { owner: string; repo: string } | null {
  try {
    const url = new URL(urlValue);
    if (url.hostname !== "github.com" && url.hostname !== "www.github.com") {
      return null;
    }
    const [owner, rawRepo] = url.pathname.split("/").filter(Boolean);
    const repo = rawRepo ? normalizeRepoName(rawRepo) : "";
    if (!owner || !repo) {
      return null;
    }
    return { owner, repo };
  } catch {
    return null;
  }
}

function resolveGithubOwnerRepo(
  src: GeneratedSource["src"] | undefined,
): { owner: string; repo: string } | null {
  if (!src) {
    return null;
  }
  if (src.type === "github" && src.owner && src.repo) {
    const repo = normalizeRepoName(src.repo);
    if (!repo) {
      return null;
    }
    return { owner: src.owner, repo };
  }
  if (typeof src.url === "string") {
    return parseGithubOwnerRepoFromUrl(src.url);
  }
  return null;
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

const STRUCTURED_DECODERS: Record<
  StructuredDecodeKind,
  (raw: string, sourceFile: string) => Promise<unknown>
> = {
  json: async (raw) => JSON.parse(raw),
  toml: async (raw) => Bun.TOML.parse(raw),
  yaml: async (raw) => Bun.YAML.parse(raw),
  nix: async (_raw, sourceFile) => decodeNixFile(sourceFile),
};

async function decodeStructuredSource(
  decode: StructuredDecodeKind,
  raw: string,
  sourceFile: string,
): Promise<unknown> {
  return STRUCTURED_DECODERS[decode](raw, sourceFile);
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

  const githubRepo = resolveGithubOwnerRepo(generatedSource?.src);
  if (githubRepo) {
    if (!Bun.which("gh")) {
      throw new Error(
        `package '${pkg}' requires gh to resolve commit from ref '${ref}'`,
      );
    }
    const resolved = (
      await (
        await $`gh api repos/${githubRepo.owner}/${githubRepo.repo}/commits/${ref} --jq .sha`.quiet()
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
  const githubRepo = resolveGithubOwnerRepo(generatedSource?.src);
  if (githubRepo) {
    return `https://github.com/${githubRepo.owner}/${githubRepo.repo}`;
  }
  return null;
}

function buildFallbackFields(
  generatedSource: GeneratedSource | undefined,
): Partial<Record<string, string>> {
  const homepage = resolveFallbackHomepage(generatedSource);
  return homepage ? { homepage } : {};
}

async function extractFieldWithFallback(
  pkg: string,
  fieldName: string,
  fallbackFields: Partial<Record<string, string>>,
  extractor: () => Promise<string> | string,
): Promise<string> {
  try {
    const value = (await extractor()).trim();
    if (!value) {
      throw new Error(`package '${pkg}' field '${fieldName}' resolved empty value`);
    }
    return value;
  } catch (error) {
    const fallback = fallbackFields[fieldName]?.trim();
    if (fallback) {
      return fallback;
    }
    throw error;
  }
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
  if (rule.decode === "html") {
    for (const [fieldName, fieldRule] of Object.entries(rule.fields)) {
      if (!("selectors" in fieldRule)) {
        throw new Error(
          `package '${pkg}' field '${fieldName}' is invalid for decode=html`,
        );
      }
      fields[fieldName] = await extractFieldWithFallback(
        pkg,
        fieldName,
        fallbackFields,
        () => extractHtmlDescription(raw, fieldRule.selectors, pkg, fieldName),
      );
    }
    return fields;
  }

  const decoded = await decodeStructuredSource(rule.decode, raw, sourceFile);

  for (const [fieldName, fieldRule] of Object.entries(rule.fields)) {
    if (!("query" in fieldRule)) {
      throw new Error(
        `package '${pkg}' field '${fieldName}' is invalid for decode=${rule.decode}`,
      );
    }
    const jqExpr = `${fieldRule.query} | if . == null then empty elif type == "string" then . else tostring end`;
    fields[fieldName] = await extractFieldWithFallback(
      pkg,
      fieldName,
      fallbackFields,
      async () => {
        const jqResult = await $`printf %s ${JSON.stringify(decoded)} | jq -er ${jqExpr}`.quiet();
        return await jqResult.text();
      },
    );
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
  const fallbackFields = buildFallbackFields(generatedSource);
  const fallbackHomepage = fallbackFields.homepage;

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

async function validateEnvironment(paths: InputPaths): Promise<void> {
  if (!Bun.which("jq")) {
    fail("required command not found: jq");
  }
  if (!Bun.which("nix")) {
    fail("required command not found: nix");
  }
  if (!(await fileExists(paths.nvfetcherFile))) {
    fail(`nvfetcher.toml not found: ${paths.nvfetcherFile}`);
  }
  if (!(await fileExists(paths.rulesFile))) {
    fail(`rules file not found: ${paths.rulesFile}`);
  }
  if (!(await fileExists(paths.generatedJsonFile))) {
    fail(`generated source file not found: ${paths.generatedJsonFile}`);
  }
}

async function loadInputs(paths: InputPaths): Promise<LoadedInputs> {
  const rules = await loadJsonFile<Rules>(paths.rulesFile);
  const generated = await loadJsonFile<GeneratedSources>(paths.generatedJsonFile);

  const nvfetcherToml = await Bun.file(paths.nvfetcherFile).text();
  const nvfetcherConfig = Bun.TOML.parse(nvfetcherToml) as Record<string, unknown>;
  const nvfetcherPackages = Object.keys(nvfetcherConfig);
  if (nvfetcherPackages.length === 0) {
    fail(`no package sections were found in ${paths.nvfetcherFile}`);
  }

  return { rules, generated, nvfetcherPackages };
}

function warnRulesNotInNvfetcher(rules: Rules, nvfetcherPackages: string[]): void {
  const nvfetcherSet = new Set(nvfetcherPackages);
  for (const pkg of Object.keys(rules.packages)) {
    if (!nvfetcherSet.has(pkg)) {
      console.error(
        `warning: package '${pkg}' exists in rules but not in nvfetcher.toml; skipping`,
      );
    }
  }
}

async function buildMeta(
  nvfetcherPackages: string[],
  rules: Rules,
  generated: GeneratedSources,
): Promise<BuildMetaResult> {
  const packages: Record<string, PackageMeta> = {};
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

  return { packages, processed, withFields };
}

async function writeMetaFile(
  outFile: string,
  packages: Record<string, PackageMeta>,
): Promise<void> {
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
}

async function main(): Promise<void> {
  const cli = parseCliOptions(Bun.argv.slice(2));
  if (cli.help) {
    usage();
    return;
  }

  const paths = resolveInputPaths(cli);
  await validateEnvironment(paths);
  const { rules, generated, nvfetcherPackages } = await loadInputs(paths);
  warnRulesNotInNvfetcher(rules, nvfetcherPackages);

  const { packages, processed, withFields } = await buildMeta(
    nvfetcherPackages,
    rules,
    generated,
  );
  await writeMetaFile(paths.outFile, packages);

  console.log(`Wrote: ${paths.outFile}`);
  console.log(`Processed: ${processed}, withFields: ${withFields}`);
}

main().catch((error: unknown) => {
  fail(error instanceof Error ? error.message : String(error));
});
