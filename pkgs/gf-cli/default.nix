{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  installShellFiles,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "gf-cli";
  version = "0-unstable-2026-06-24";
  src = fetchFromGitHub {
    owner = "johejo";
    repo = "gf-cli";
    rev = "89564b4b04a01c5fdd9b495e2936f27bed4032db";
    hash = "sha256-jdzl9UxGJ/JYbKe4XeSwhHEDa3c6AtMv6AgQir1jNfo=";
  };
  subPackages = [ "cmd/gf" ];
  vendorHash = "sha256-6ROZ7oyZXA6QbQ0qoslr3NXAk82LOs1E4/WuZwj5p5A=";

  nativeBuildInputs = [ installShellFiles ];
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}"
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

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "Grafana API Client for command line operations";
    homepage = "https://github.com/johejo/gf-cli";
    license = lib.licenses.asl20;
    mainProgram = "gf";
  };
}
