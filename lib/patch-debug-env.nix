{ deno, writeShellApplication }:

writeShellApplication {
  name = "patch-debug-env";

  runtimeInputs = [ deno ];

  text = ''
    exec deno run --allow-read --allow-write ${./patch-debug-env.js} "$@"
  '';
}
