{
  lib,
  rustPlatform,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
  patchelf,
  ...
}:

rustPlatform.buildRustPackage rec {
  pname = "libz-rs-sys-cdylib";
  version = "0.6.7";
  src = fetchFromGitHub {
    owner = "trifectatechfoundation";
    repo = "zlib-rs";
    tag = "v${version}";
    hash = "sha256-xp/5DIFhcNTpSJfy3vJnZytzh1Ls6V3PKlIl6Pep2o0=";
  };

  cargoRoot = "libz-rs-sys-cdylib";
  buildAndTestSubdir = "libz-rs-sys-cdylib";
  cargoLock.lockFile = "${src}/libz-rs-sys-cdylib/Cargo.lock";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ patchelf ];

  doCheck = false;

  postBuild = lib.optionalString stdenv.hostPlatform.isLinux ''
    targetDir="target/${stdenv.hostPlatform.rust.rustcTarget}/release"

    ${stdenv.cc.targetPrefix}cc \
      -shared \
      -Wl,-soname,libz.so.1 \
      -Wl,--version-script=libz-rs-sys/include/zlib.map \
      -Wl,--whole-archive "$targetDir/libz_rs.a" -Wl,--no-whole-archive \
      -ldl -lpthread -lm \
      -o "$targetDir/libz.so.1"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
  ''
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    install -Dm755 target/${stdenv.hostPlatform.rust.rustcTarget}/release/libz.so.1 $out/lib/libz.so.1
    ln -s libz.so.1 $out/lib/libz.so
    patchelf --set-soname libz.so.1 $out/lib/libz.so.1
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    install -Dm755 target/${stdenv.hostPlatform.rust.rustcTarget}/release/libz_rs.dylib $out/lib/libz.1.dylib
    ln -s libz.1.dylib $out/lib/libz.dylib
  ''
  + ''
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A memory-safe zlib implementation written in rust";
    homepage = "https://github.com/trifectatechfoundation/zlib-rs";
    license = lib.licenses.zlib;
  };
}
