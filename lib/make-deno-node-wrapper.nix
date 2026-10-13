{
  deno,
  extractNodeEnv,
  jq,
  lib,
  makeSetupHook,
  makeWrapper,
  patchDebugEnv,
}:

makeSetupHook {
  name = "make-deno-node-wrapper-hook";
  propagatedBuildInputs = [ makeWrapper ];
  substitutions = {
    deno = lib.getExe deno;
    extractNodeEnv = lib.getExe extractNodeEnv;
    jq = lib.getExe jq;
    patchDebugEnv = lib.getExe patchDebugEnv;
  };
} ./make-deno-node-wrapper.sh
