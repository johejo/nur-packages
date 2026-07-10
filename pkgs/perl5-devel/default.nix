{
  lib,
  perl,
  source,
  ...
}:

perl.overrideAttrs (old: {
  version = lib.removePrefix "v" source.version;
  src = source.src;
  # drop nixpkgs security patches already applied upstream
  patches = builtins.filter (p: !(lib.hasInfix "CVE-2026-8376" (toString p))) (old.patches or [ ]);
  # nixpkgs swaps vendored cpan modules for pinned (older) CPAN releases,
  # which breaks the devel MANIFEST check; keep upstream's vendored copies
  postPatch = ''
    substituteInPlace dist/PathTools/Cwd.pm \
      --replace-warn "/bin/pwd" "$(type -P pwd)"
    unset src
  '';
  configureFlags = (old.configureFlags or [ ]) ++ [
    "-Dusedevel"
  ];
  meta = (old.meta or { }) // {
    homepage = "https://github.com/Perl/perl5";
  };
})
