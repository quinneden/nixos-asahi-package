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

  major = toInt (versions.major thisVer);
  minor = toInt (versions.minor thisVer);
  patch = toInt (versions.patch thisVer);

  nextVer =
    if (patch != 9) then
      (concatStringsSep "." [
        (toString major)
        (toString minor)
        (toString (patch + 1))
      ])
    else if (minor != 9) then
      (concatStringsSep "." [
        (toString major)
        (toString (minor + 1))
        "0"
      ])
    else
      (concatStringsSep "." [
        (toString (major + 1))
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
