{
  lib,
  stdenv,
  buildGoModule,
  versionCheckHook,
  installShellFiles,
  source,
  ...
}:

let
  installShellCompletions = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
in

buildGoModule rec {
  inherit (source) pname version src;
  vendorHash = "sha256-vzsG+rEjbAuIyQAwn8Th4e2W+In+oGQ2wPCax1l34EU=";

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
    in
    [
      "-s"
      "-w"
      "-X ${mod}.version=${version}"
      "-X ${mod}.commit=${src.rev}"
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
    description = "Fast, script-friendly CLI for Google Workspace (Gmail, Calendar, Drive, Docs, etc.)";
    homepage = "https://github.com/steipete/gogcli";
    license = lib.licenses.mit;
    mainProgram = "gog";
  };
}
