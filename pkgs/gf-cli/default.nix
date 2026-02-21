{
  buildGoModule,
  installShellFiles,
  versionCheckHook,
  source,
  ...
}:

buildGoModule rec {
  inherit (source) pname version src;
  subPackages = [ "cmd/gf" ];
  vendorHash = "sha256-xOoujvNhBYLgTkpdML6bxQhNsRVOINbpNXIAEAqLsl0=";

  nativeBuildInputs = [ installShellFiles ];
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];
  postInstall = ''
    installManPage man/gf*
    installShellCompletion --cmd gf \
      --bash <($out/bin/gf completion bash) \
      --zsh <($out/bin/gf completion zsh) \
      --fish <($out/bin/gf completion fish) \
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Grafana API Client for command line operations";
    mainProgram = "gf";
  };
}
