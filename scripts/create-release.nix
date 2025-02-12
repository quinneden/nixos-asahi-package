{
  lib,
  writeShellApplication,
  bash,
  coreutils,
  git,
}:

with lib;

let
  curVer = (import ../version.nix).version;
  majorInt = toInt (versions.major curVer);
  majorMinor = versions.majorMinor curVer;
  minorInt = toInt (versions.minor curVer);
  patchInt = toInt (versions.patch curVer);

  newVer =
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

writeShellApplication {
  name = "create-release";
  runtimeInputs = [
    bash
    git
    coreutils
  ];
  text = ''
    version="${newVer}"
    ${readFile ./create-release.sh}
  '';
}
