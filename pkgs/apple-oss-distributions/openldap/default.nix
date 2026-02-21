{
  stdenv,
  berkeleydb,
  source,
  ...
}:

stdenv.mkDerivation {
  inherit (source) pname src version;

  sourceRoot = "source/OpenLDAP";

  enableParallelBuilding = true;

  buildInputs = [ berkeleydb ];

  meta = {
    description = "Apple Open Source Distribution of OpenLDAP";
    broken = true;
  };
}
