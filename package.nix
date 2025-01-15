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

  pkgVersion = "1.0-beta.2";

  writeInstallerData = writeShellScript "write-installer-data" ''
    rootSize="$(cat ./root_part_size)B"
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

    diskImage=$src/nixos.img

    7z x $src/nixos.img
    mv primary.img root.img

    7z x -sdel ESP.img -o'esp'
    rm -rf esp/EFI/nixos/.extra-files

    zip -r "${pname}-${pkgVersion}".zip esp root.img

    stat --printf '%s' root.img > root_part_size
    printf '${pkgVersion}' > version_tag

    ${writeInstallerData} > "${pname}-${pkgVersion}".json

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/data

    install -m 755 ./"${pname}-${pkgVersion}.zip" $out
    install -m 755 ./"${pname}-${pkgVersion}.json" $out/data
    install -m 755 ./version_tag $out/data

    runHook postInstall
  '';
}
