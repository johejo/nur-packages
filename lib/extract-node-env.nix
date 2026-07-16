{
  ast-grep,
  coreutils,
  gnused,
  jq,
  writeShellApplication,
}:

writeShellApplication {
  name = "extract-node-env";

  runtimeInputs = [
    ast-grep
    coreutils
    gnused
    jq
  ];

  text = builtins.readFile ./extract-node-env.sh;
}
