{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:
with lib;
let
  inherit (import ../version.nix) version;
  majorInt = toInt (versions.major version);
  majorMinor = versions.majorMinor version;
  minorInt = toInt (versions.minor version);
  patchInt = toInt (versions.patch version);

  versionNew =
    if (patchInt != 9) then
      majorMinor + "." + (toString (patchInt + 1))
    else if (minorInt != 9) then
      (concatStringsSep "." [
        (toString majorInt)
        (toString (minorInt + 1))
        "0"
      ])
    else
      (concatStringsSep "." [
        (toString (majorInt + 1))
        "0"
        "0"
      ]);
in
pkgs.runCommand "increment-version" { } ''
  echo -n '{ version = "${versionNew}"; }' > $out
''
