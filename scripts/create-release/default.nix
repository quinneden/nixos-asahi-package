{
  bash,
  git,
  gnused,
  writeShellApplication,
}:
writeShellApplication {
  name = "create-release";

  runtimeInputs = [
    bash
    git
    gnused
  ];

  text = ''
    bash ${./create-release.sh}
  '';
}
