{
  bash,
  git,
  gnused,
  writeShellApplication,
}:
let
  inherit (import ../../version.nix) version latestRelease;
in
writeShellApplication {
  name = "create-release";
  derivationArgs = { inherit version; };

  runtimeInputs = [
    bash
    git
    gnused
  ];

  text = ''
    version="${version}"; export version
    latestReleaseCommit="${latestRelease.commit}"; export latestReleaseCommit
    latestReleaseDate="${latestRelease.date}"; export latestReleaseDate
    latestReleaseVersion="${latestRelease.version}"; export latestReleaseVersion
    latestReleaseTag="${latestRelease.tag}"; export latestReleaseTag
    bash ${./create-release.sh}
  '';
}
