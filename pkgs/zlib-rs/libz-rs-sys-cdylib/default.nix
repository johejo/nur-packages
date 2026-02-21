{
  lib,
  rustPlatform,
  stdenv,
  source,
  patchelf,
  ...
}:

rustPlatform.buildRustPackage {
  pname = "libz-rs-sys-cdylib";
  inherit (source) version src;

  cargoRoot = "libz-rs-sys-cdylib";
  buildAndTestSubdir = "libz-rs-sys-cdylib";
  cargoLock = source.cargoLock."libz-rs-sys-cdylib/Cargo.lock";

  nativeBuildInputs = lib.optionals stdenv.isLinux [ patchelf ];

  doCheck = false;

  postBuild = lib.optionalString stdenv.isLinux ''
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
  + lib.optionalString stdenv.isLinux ''
    install -Dm755 target/${stdenv.hostPlatform.rust.rustcTarget}/release/libz.so.1 $out/lib/libz.so.1
    ln -s libz.so.1 $out/lib/libz.so
    patchelf --set-soname libz.so.1 $out/lib/libz.so.1
  ''
  + lib.optionalString stdenv.isDarwin ''
    install -Dm755 target/${stdenv.hostPlatform.rust.rustcTarget}/release/libz_rs.dylib $out/lib/libz.1.dylib
    ln -s libz.1.dylib $out/lib/libz.dylib
  ''
  + ''
    runHook postInstall
  '';

}
