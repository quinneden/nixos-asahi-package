{
  pkgs,
  ...
}:
with pkgs.lib;
let
  versionOld = (import ../version.nix).version;
  majorInt = toInt (versions.major versionOld);
  majorMinor = versions.majorMinor versionOld;
  minorInt = toInt (versions.minor versionOld);
  patchInt = toInt (versions.patch versionOld);

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
pkgs.mkShell {
  shellHook = ''
    # if [[ ! -f "flake.nix" ]]; then
    #   echo "This script must be run from the root of the repository" >&2
    #   exit 1
    # fi

    # if [[ "$(git symbolic-ref --short HEAD)" != "main" ]]; then
    #   echo "must be on main branch" >&2
    #   exit 1
    # fi

    # uncommited_changes=$(git diff --compact-summary)
    # if [[ -n "$uncommited_changes" ]]; then
    #   echo -e "There are uncommited changes, exiting:\n$uncommited_changes" >&2
    #   exit 1
    # fi

    echo '{ version = "${versionNew}"; }' > ./version.nix
    exit
  '';
}
