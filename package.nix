{
  lib,
  pkgs,
  self,
  stdenv,
  ...
}:
with lib;
let
  inherit (self.packages.aarch64-linux) nixosImage;
  inherit (pkgs) runCommand writeShellScript;

  timestamp = readFile (runCommand "timestamp" { } "printf `date -u +%Y-%m-%d` > $out");

  writeInstallerData = writeShellScript "write-installer-data" ''
    rootSize="$(cat $out/root_part_size)B"
    jq -r ".package = \"https://cdn.qeden.systems/os/nixos-asahi-${timestamp}.zip\"
      | .partitions.[1].size = \"$rootSize\"
      | .name = \"NixOS (${timestamp})\"" \
      < ${./data/installer_data.json}
  '';
in
stdenv.mkDerivation rec {
  pname = "nixos-asahi";
  version = "1.0-beta.1";

  src = nixosImage;

  nativeBuildInputs = with pkgs; [
    coreutils
    gptfdisk
    jq
    p7zip
    zip
  ];

  buildPhase = ''
    runHook preBuild
    mkdir -p $out

    7z x $src/nixos-asahi.img
    7z x ESP.img -o'esp'

    rm -rf esp/EFI/nixos/.extra-files

    stat --printf '%s' root.img > $out/root_part_size
    printf "${timestamp}" > $out/timestamp

    zip -r $out/${pname}-${timestamp}.zip esp root.img

    ${writeInstallerData} > $out/${pname}-${timestamp}.json

    runHook postBuild
  '';
}
