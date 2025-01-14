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
    util-linux
    zip
  ];

  buildPhase = ''
    runHook preBuild
    mkdir -p $out/data

    diskImage=$src/nixos.img

    ESP_START=$(partx $diskImage -go START --nr 1)
    ESP_SECTORS=$(partx $diskImage -go SECTORS --nr 1)
    ROOT_SECTORS=$(partx $diskImage -go START --nr 2)
    ROOT_SECTORS=$(partx $diskImage -go SECTORS --nr 2)

    dd if=nixos.img of=esp.img bs=512 skip="$ESP_START" count="$ESP_SECTORS"
    dd if=nixos.img of=root.img bs=512 skip="$ROOT_START" count="$ROOT_SECTORS"

    7z x esp.img -o'esp'
    rm -f esp.img

    rm -rf esp/EFI/nixos/.extra-files

    stat --printf '%s' root.img > $out/data/root_part_size
    printf '${pkgVersion}' > $out/data/version_tag

    zip -r $out/${pname}-${pkgVersion}.zip esp root.img

    ${writeInstallerData} > $out/data/${pname}-${pkgVersion}.json
    runHook postBuild
  '';
}
