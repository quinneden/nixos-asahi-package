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
  inherit (pkgs) writeShellScript;

  pkgVersion = "1.0-beta.1";

  writeInstallerData = writeShellScript "write-installer-data" ''
    rootSize="$(cat $out/data/root_part_size)B"
    jq -r ".package = \"https://cdn.qeden.systems/os/nixos-asahi-${pkgVersion}.zip\"
      | .partitions.[1].size = \"$rootSize\"
      | .name = \"NixOS ${version} (nixos-asahi-${pkgVersion})\"" \
      < ${./data/installer_data.json}
  '';
in
stdenv.mkDerivation rec {
  pname = "nixos-asahi";
  version = "${pkgVersion}";

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
    mkdir -p $out/data

    7z x $src/nixos-asahi.img 
    7z x ESP.img -o'esp'

    rm -rf esp/EFI/nixos/.extra-files

    stat --printf '%s' root.img > $out/data/root_part_size
    printf '${pkgVersion}' > $out/data/version_tag

    zip -r $out/${pname}-${pkgVersion}.zip esp root.img

    ${writeInstallerData} > $out/data/${pname}-${pkgVersion}.json
    runHook postBuild
  '';
}
