{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  ...
}:

buildGoModule rec {
  pname = "mdfix";
  version = "0-unstable-2026-04-24";

  src = fetchFromGitHub {
    owner = "johejo";
    repo = "mdfix";
    rev = "9e17f9a5b54bf022921cec4bf55de207d94eeb0e";
    hash = "sha256-QYSRI31xICVRyBSwF8XoH38/zRAqIhF/1GbnwT7lX5U=";
  };

  vendorHash = "sha256-trvRSKbW2qK1h2tutk6HqAvgwsbZlKQA/ErmbZx67TQ=";

  ldflags = [
    "-s"
    "-w"
  ];

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
