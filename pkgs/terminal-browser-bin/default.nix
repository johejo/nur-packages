{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  versionCheckHook,
  autoPatchelfHook,
  makeWrapper,
  coreutils,
  fontconfig,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libgcc,
  libgbm,
  libGL,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxkbcommon,
  nss,
  nspr,
  pango,
  systemd,
  ...
}:

let
  version = "0.11.1";
  sources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/zenbu-labs/terminal-browser/releases/download/v${version}/terminal-browser-darwin-arm64.tar.gz";
      hash = "sha256-myFynke8wH6WmRMiNwXOGuW8qo5JCU1slwXEzKgxHZA=";
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/zenbu-labs/terminal-browser/releases/download/v${version}/terminal-browser-linux-x64.tar.gz";
      hash = "sha256-sIMnZVqjGQJgzzSAcpS+fHxmhaomOaOTBVt8ZJ7rOko=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/zenbu-labs/terminal-browser/releases/download/v${version}/terminal-browser-linux-arm64.tar.gz";
      hash = "sha256-7zTGgzPENS5RB9W9bFz3/oQKBcmkijcIS5/GX8mGOFw=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "terminal-browser-bin";
  inherit version;
  src = sources.${stdenvNoCC.hostPlatform.system};

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [
    autoPatchelfHook
    wrapGAppsHook3
  ];
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libgcc
    libgbm
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxkbcommon
    nss
    nspr
    pango
    systemd
  ];
  runtimeDependencies = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    (lib.getLib libGL)
    (lib.getLib systemd)
  ];

  dontBuild = true;
  dontStrip = true;
  dontWrapGApps = true;

  # The UI renderer uses a single font without system font fallback. On Linux,
  # ask the user's fontconfig for a monospace font that also covers Japanese.
  postPatch = ''
    substituteInPlace browser/dist/main.js \
      --replace-fail 'fontFile: () => bundledFontPath()' \
        'fontFile: () => process.env.TERMINAL_BROWSER_UI_FONT || bundledFontPath()'
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
    substituteInPlace bin/terminal-browser \
      --replace-fail 'export ELECTRON_RUN_AS_NODE=1' 'export ELECTRON_RUN_AS_NODE=1
    if [ -z "''${TERMINAL_BROWSER_UI_FONT:-}" ]; then
      TERMINAL_BROWSER_UI_FONT="$(${lib.getBin fontconfig}/bin/fc-match --format="%{file}" "monospace:charset=3042" 2>/dev/null || true)"
      export TERMINAL_BROWSER_UI_FONT
    fi'
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/libexec/terminal-browser $out/bin
    cp -a . $out/libexec/terminal-browser/
    runHook postInstall
  '';

  preFixup = ''
    makeWrapper $out/libexec/terminal-browser/bin/terminal-browser $out/bin/terminal-browser \
      --prefix PATH : ${lib.makeBinPath [ coreutils ]} \
      ${lib.optionalString stdenvNoCC.hostPlatform.isLinux ''"''${gappsWrapperArgs[@]}"''}
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  passthru = {
    aarch64DarwinSrc = sources.aarch64-darwin;
    x86_64LinuxSrc = sources.x86_64-linux;
    aarch64LinuxSrc = sources.aarch64-linux;
    updateScript = nix-update-script {
      extraArgs = [
        "--custom-dep=aarch64DarwinSrc"
        "--custom-dep=x86_64LinuxSrc"
        "--custom-dep=aarch64LinuxSrc"
      ];
    };
  };

  meta = {
    description = "A real browser that runs inside your terminal";
    homepage = "https://github.com/zenbu-labs/terminal-browser";
    changelog = "https://github.com/zenbu-labs/terminal-browser/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "terminal-browser";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames sources;
  };
}
