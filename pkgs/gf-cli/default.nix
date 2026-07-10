{
  lib,
  buildGoModule,
  installShellFiles,
  versionCheckHook,
  source,
  ...
}:

buildGoModule rec {
  inherit (source) pname version src;
  subPackages = [ "cmd/gf" ];
  vendorHash = "sha256-6ROZ7oyZXA6QbQ0qoslr3NXAk82LOs1E4/WuZwj5p5A=";

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
    homepage = "https://github.com/johejo/gf-cli";
    license = lib.licenses.asl20;
    mainProgram = "gf";
  };
}
