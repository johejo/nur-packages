{
  lib,
  llvmPackages,
  cmake,
  darwin,
  gnused,
  ninja,
  python314,
  zlib,
}:

let
  llvmPkgs = llvmPackages;
  isSupportedSystem = llvmPkgs.stdenv.hostPlatform.system == "aarch64-darwin";
  standaloneLibclangCmakeFlags = [
    "-G"
    "Ninja"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_SHARED_LIBS=OFF"
    "-DLLVM_ENABLE_PROJECTS=clang"
    "-DLLVM_ENABLE_BINDINGS=OFF"
    "-DLLVM_BUILD_LLVM_DYLIB=OFF"
    "-DLLVM_LINK_LLVM_DYLIB=OFF"
    "-DLLVM_INCLUDE_TESTS=OFF"
    "-DLLVM_INCLUDE_BENCHMARKS=OFF"
    "-DLLVM_INCLUDE_EXAMPLES=OFF"
    "-DCLANG_INCLUDE_TESTS=OFF"
    "-DCLANG_BUILD_EXAMPLES=OFF"
    "-DCLANG_BUILD_TOOLS=OFF"
    "-DLLVM_TARGETS_TO_BUILD=host"
    "-DLLVM_ENABLE_ZSTD=OFF"
    "-DLLVM_ENABLE_LIBXML2=OFF"
    "-DLLVM_ENABLE_FFI=OFF"
    "-DLLVM_ENABLE_TERMINFO=OFF"
    "-DLLVM_ENABLE_LIBEDIT=OFF"
    "-DZLIB_INCLUDE_DIR=${zlib.dev}/include"
    "-DZLIB_LIBRARY=${zlib.static}/lib/libz.a"
  ];
in
if !isSupportedSystem then
  null
else
  llvmPkgs.stdenv.mkDerivation {
    pname = "standalone-libclang";
    version = llvmPkgs.clang-unwrapped.version;

    dontUnpack = true;
    strictDeps = true;
    enableParallelBuilding = true;
    doInstallCheck = true;

    nativeBuildInputs = [
      cmake
      darwin.cctools
      gnused
      ninja
      python314
    ];

    configurePhase = ''
      runHook preConfigure

      source_root="$PWD/llvm-project"
      mkdir -p "$source_root"

      cp -R ${llvmPkgs.llvm.src}/llvm "$source_root/llvm"
      cp -R ${llvmPkgs.llvm.src}/cmake "$source_root/cmake"
      cp -R ${llvmPkgs.llvm.src}/third-party "$source_root/third-party"
      if [ -d ${llvmPkgs.llvm.src}/libc ]; then
        cp -R ${llvmPkgs.llvm.src}/libc "$source_root/libc"
      fi
      cp -R ${llvmPkgs.clang-unwrapped.src}/clang "$source_root/clang"
      cp -R ${llvmPkgs.clang-unwrapped.src}/clang-tools-extra "$source_root/clang-tools-extra"

      ls -1 "$source_root" | sed -n '1,20p'
      cmake -S "$source_root/llvm" -B build ${lib.escapeShellArgs standaloneLibclangCmakeFlags}

      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      cmake --build build --target libclang
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib"
      cp build/lib/libclang.dylib "$out/lib/libclang.dylib"
      runHook postInstall
    '';

    installCheckPhase = ''
      runHook preInstallCheck

      while read -r dep; do
        [ -n "$dep" ] || continue
        printf '%s\n' "$dep"

        case "$dep" in
          "$out/lib/libclang.dylib" | @rpath/libclang.dylib | /usr/lib/libSystem.B.dylib | /usr/lib/libc++.1.dylib)
            ;;
          /nix/store/*)
            echo "runtime dependencies must not reference Nix store dylibs: $dep" >&2
            exit 1
            ;;
          *)
            echo "unexpected runtime dependency detected: $dep" >&2
            exit 1
            ;;
        esac
      done < <(${darwin.cctools}/bin/otool -L "$out/lib/libclang.dylib" | sed -n '2,$p' | awk '{ print $1 }')

      runHook postInstallCheck
    '';

    meta = {
      description = "Standalone libclang dylib built without a libLLVM runtime dependency";
      homepage = "https://clang.llvm.org/";
      license = lib.licenses.ncsa;
      platforms = [ "aarch64-darwin" ];
    };
  }
