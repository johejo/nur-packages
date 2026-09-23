// Patch debug's src/node.js for Deno's per-variable environment permissions.
// Print the required environment names for the caller's allowlist.
// Only uppercase names derived from this runtime's inspect options are supported.
import { inspect } from "node:util";

function main(args) {
  let format = "lines";
  if (args[0] === "--format") {
    format = args[1];
    args = args.slice(2);
  }
  if (args[0] === "--") args = args.slice(1);
  if (!["lines", "json"].includes(format) || !args.length || args.some(arg => arg.startsWith("-"))) {
    throw new Error("usage: patch-debug-env [--format lines|json] FILE...");
  }

  const options = new Set([...Object.keys(inspect.defaultOptions), "hideDate", "colors"]);
  const names = [...options].map(option =>
    "DEBUG_" + option.replace(/[A-Z]/g, letter => "_" + letter).toUpperCase()
  ).sort();
  const before = "Object.keys(process.env)";
  const after = `${JSON.stringify(names)}.filter(key => process.env[key] !== undefined)`;

  // Validate every input before writing; fail if upstream changes the implementation.
  const patches = [...new Set(args)].map(path => {
    const source = Deno.readTextFileSync(path);
    if (!source.includes(`exports.inspectOpts = ${before}`) || source.split(before).length !== 2) {
      throw new Error(`${path}: expected exactly one debug inspectOpts environment enumeration`);
    }
    return [path, source.replace(before, after)];
  });
  for (const [path, source] of patches) Deno.writeTextFileSync(path, source);
  console.log(format === "json" ? JSON.stringify(names) : names.join("\n"));
}

try {
  main(Deno.args);
} catch (error) {
  console.error(`patch-debug-env: ${error.message}`);
  Deno.exit(1);
}
