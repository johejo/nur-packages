#!/usr/bin/env bun
import { $ } from "bun";
import { mkdir, rename } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";

type DecodeKind = "json" | "toml" | "text";

type Profile = {
  file: string;
  decode: DecodeKind;
  query: string;
};

type PackageRule = string | ({ profile: string } & Partial<Profile>);

type Rules = {
  profiles: Record<string, Profile>;
  packages: Record<string, PackageRule>;
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
  const generated = await loadJsonFile<Record<string, { version?: string }>>(
    generatedJsonFile,
  );

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
    const pkgRule = rules.packages[pkg];
    if (!pkgRule) {
      skipped += 1;
      continue;
    }

    let profileName = "";
    let overrides: Partial<Profile> = {};
    if (typeof pkgRule === "string") {
      profileName = pkgRule;
    } else if (pkgRule && typeof pkgRule === "object") {
      profileName = pkgRule.profile ?? "";
      if (!profileName) {
        console.error(
          `warning: package '${pkg}' has object rule but no profile; skipping`,
        );
        skipped += 1;
        continue;
      }
      overrides = {
        file: pkgRule.file,
        decode: pkgRule.decode,
        query: pkgRule.query,
      };
    } else {
      console.error(`warning: package '${pkg}' has unsupported rule type; skipping`);
      skipped += 1;
      continue;
    }

    const baseProfile = rules.profiles[profileName];
    if (!baseProfile) {
      console.error(
        `warning: package '${pkg}' references unknown profile '${profileName}'; skipping`,
      );
      skipped += 1;
      continue;
    }

    const rule: Profile = {
      ...baseProfile,
      ...overrides,
    };
    if (!rule.file) {
      console.error(`warning: package '${pkg}' resolved rule has no file; skipping`);
      skipped += 1;
      continue;
    }

    console.log(`Processing ${pkg}...`);

    const expr = `
      let
        flake = builtins.getFlake (toString ./.);
        pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; };
        sources = pkgs.callPackage ./_sources/generated.nix { };
      in
        (builtins.getAttr ${JSON.stringify(pkg)} sources).src
    `;
    const srcResult = await $.cwd(rootDir)`nix build --no-link --print-out-paths --impure --expr ${expr}`.quiet();
    const srcOutPath = (await srcResult.text()).trim();
    const sourceFile = path.join(srcOutPath, rule.file);
    const version = generated[pkg]?.version ?? null;

    let status = "ok";
    let description: string | null = null;

    if (!(await fileExists(sourceFile))) {
      status = "missing-file";
      console.error(`warning: package '${pkg}' file not found: ${sourceFile}`);
    } else {
      let decoded: unknown;
      try {
        const raw = await Bun.file(sourceFile).text();
        if (rule.decode === "json") {
          decoded = JSON.parse(raw);
        } else if (rule.decode === "toml") {
          decoded = Bun.TOML.parse(raw);
        } else if (rule.decode === "text") {
          decoded = raw;
        } else {
          status = "unsupported-decode";
          console.error(
            `warning: package '${pkg}' has unsupported decode: ${rule.decode}`,
          );
        }
      } catch (error) {
        status = "query-empty";
        console.error(`warning: package '${pkg}' failed to decode ${rule.file}: ${error}`);
      }

      if (status === "ok") {
        const jqExpr = `${rule.query} | if . == null then empty elif type == "string" then . else tostring end`;
        const jqResult = await $`printf %s ${JSON.stringify(decoded)} | jq -er ${jqExpr}`
          .nothrow()
          .quiet();
        if (jqResult.exitCode === 0) {
          description = (await jqResult.text()).trimEnd();
        } else {
          status = "query-empty";
        }
      }
    }

    packages[pkg] = {
      profile: profileName,
      version,
      description,
      status,
      source: {
        outPath: srcOutPath,
        file: rule.file,
        decode: rule.decode,
        query: rule.query,
      },
    };
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
