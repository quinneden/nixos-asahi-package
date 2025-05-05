{
  bash,
  git,
  lib,
  version,
  writeShellApplication,
}:
with lib;
let
  thisVer = removeSuffix "-dirty" version;
  majorInt = toInt (versions.major thisVer);
  majorMinor = versions.majorMinor thisVer;
  minorInt = toInt (versions.minor thisVer);
  patchInt = toInt (versions.patch thisVer);

  nextVer =
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
  derivationArgs.version = thisVer;

  runtimeInputs = [
    bash
    git
  ];

  text = ''
    this_version="${thisVer}"; export this_version
    next_version="${nextVer}"; export next_version
    bash ${./create-release.sh}
  '';
}
