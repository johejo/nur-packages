{
  lib,
  stdenv,
  buildGoModule,
  versionCheckHook,
  installShellFiles,
  source,
  sourceMeta ? { },
  ...
}:

let
  installShellCompletions = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
in

buildGoModule rec {
  inherit (source) pname version src;
  vendorHash = "sha256-WGRlv3UsK3SVBQySD7uZ8+FiRl03p0rzjBm9Se1iITs=";

  checkFlags =
    let
      # Network/OAuth dependent test patterns
      skippedPatterns = [
        "TestAuthorize_"
        "TestManageServer_"
        "TestFetchUserEmail"
        "TestStartManageServer_"
        "TestCheckRefreshToken"
        "TestGmailWatch"
      ];
    in
    [ "-skip=^(${lib.concatStringsSep "|" skippedPatterns})" ];

  ldflags =
    let
      mod = "github.com/steipete/gogcli/internal/cmd";
      sourceGit = sourceMeta.git or { };
      commit = sourceGit.commit or sourceGit.ref or source.rev;
    in
    [
      "-s"
      "-w"
      "-X ${mod}.version=${version}"
      "-X ${mod}.commit=${commit}"
    ];

  nativeBuildInputs = [ installShellFiles ];

  nativeInstallCheckInputs = [ versionCheckHook ];

  doInstallCheck = true;

  postInstall = lib.optionalString installShellCompletions ''
    installShellCompletion --cmd gog \
      --bash <($out/bin/gog completion bash) \
      --fish <($out/bin/gog completion fish) \
      --zsh <($out/bin/gog completion zsh)
  '';

  meta = {
    mainProgram = "gog";
  };
}
