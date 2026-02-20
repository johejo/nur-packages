#!/usr/bin/env bun
import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

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

type CommandResult = {
  stdout: string;
  stderr: string;
  exitCode: number;
};

const scriptPath = fileURLToPath(import.meta.url);
const rootDir = path.dirname(scriptPath);

function usage(): void {
  console.log(`Usage: bun ./update-source-meta.ts [options]

Options:
  --filter <regex>     Process only package names matching regex
  --rules <path>       Rules file path (default: meta-rules.json)
  --out <path>         Output path (default: _sources/meta.json)
  -h, --help           Show this help`);
}

function fail(message: string): never {
  console.error(`error: ${message}`);
  process.exit(1);
}

async function runCommand(
  args: string[],
  options: { cwd?: string; input?: string; allowFailure?: boolean } = {},
): Promise<CommandResult> {
  const proc = Bun.spawn(args, {
    cwd: options.cwd,
    stdin: options.input === undefined ? "ignore" : "pipe",
    stdout: "pipe",
    stderr: "pipe",
  });

  if (options.input !== undefined) {
    proc.stdin.write(options.input);
    proc.stdin.end();
  }

  const [stdout, stderr, exitCode] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ]);

  if (exitCode !== 0 && !options.allowFailure) {
    throw new Error(
      `command failed (${exitCode}): ${args.join(" ")}\n${stderr.trim()}`,
    );
  }

  return { stdout, stderr, exitCode };
}

async function loadJsonFile<T>(filePath: string): Promise<T> {
  const raw = await readFile(filePath, "utf8");
  return JSON.parse(raw) as T;
}

async function fileExists(filePath: string): Promise<boolean> {
  return Bun.file(filePath).exists();
}

async function main(): Promise<void> {
  let rulesFile = path.join(rootDir, "meta-rules.json");
  let outFile = path.join(rootDir, "_sources", "meta.json");
  let filterRegex = "";

  const args = process.argv.slice(2);
  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg === "--filter") {
      filterRegex = args[i + 1] ?? "";
      i += 1;
      continue;
    }
    if (arg === "--rules") {
      rulesFile = path.resolve(rootDir, args[i + 1] ?? "");
      i += 1;
      continue;
    }
    if (arg === "--out") {
      outFile = path.resolve(rootDir, args[i + 1] ?? "");
      i += 1;
      continue;
    }
    if (arg === "-h" || arg === "--help") {
      usage();
      return;
    }
    fail(`unknown option: ${arg}`);
  }

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

  const nvfetcherToml = await readFile(nvfetcherFile, "utf8");
  const nvfetcherConfig = Bun.TOML.parse(nvfetcherToml) as Record<string, unknown>;
  const nvfetcherPackages = Object.keys(nvfetcherConfig);
  if (nvfetcherPackages.length === 0) {
    fail(`no package sections were found in ${nvfetcherFile}`);
  }

  let packageFilter: RegExp | null = null;
  if (filterRegex !== "") {
    try {
      packageFilter = new RegExp(filterRegex);
    } catch (error) {
      fail(`invalid --filter regex: ${String(error)}`);
    }
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
    if (packageFilter && !packageFilter.test(pkg)) {
      continue;
    }

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
    const srcResult = await runCommand(
      [
        "nix",
        "build",
        "--no-link",
        "--print-out-paths",
        "--impure",
        "--expr",
        expr,
      ],
      { cwd: rootDir },
    );
    const srcOutPath = srcResult.stdout.trim();
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
        const raw = await readFile(sourceFile, "utf8");
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
        const jqResult = await runCommand(
          ["jq", "-er", jqExpr],
          {
            input: JSON.stringify(decoded),
            allowFailure: true,
          },
        );
        if (jqResult.exitCode === 0) {
          description = jqResult.stdout.trimEnd();
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
  await writeFile(
    tmpFile,
    JSON.stringify(
      {
        packages,
      },
      null,
      2,
    ) + "\n",
    "utf8",
  );
  await rename(tmpFile, outFile);

  console.log(`Wrote: ${outFile}`);
  console.log(`Processed: ${processed}, skipped: ${skipped}`);
}

main().catch((error: unknown) => {
  fail(error instanceof Error ? error.message : String(error));
});
