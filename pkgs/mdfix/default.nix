{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
  ...
}:

buildGoModule rec {
  pname = "mdfix";
  version = "0-unstable-2026-09-25";

  src = fetchFromGitHub {
    owner = "johejo";
    repo = "mdfix";
    rev = "90294d567de1fee6981aa9758608c5129bab6202";
    hash = "sha256-ZaflGVQHsukYstJ/dMBZu8rBOmHXZRfBwGAbtpAcLB0=";
  };

  vendorHash = "sha256-trvRSKbW2qK1h2tutk6HqAvgwsbZlKQA/ErmbZx67TQ=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}+rev.${builtins.substring 0 12 src.rev}"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "-version";

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch=main" ];
  };

  meta = {
    description = "Apply regex-based rewrite rules to Markdown safely";
    homepage = "https://github.com/johejo/mdfix";
    license = lib.licenses.mit;
    mainProgram = "mdfix";
    platforms = lib.platforms.unix;
  };
}
