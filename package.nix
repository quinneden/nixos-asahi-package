{
  lib,
  pkgs,
  self,
  stdenv,
  ...
}:
with lib;
let
  genInstallerData = import ./lib/gen-installer-data.nix { inherit pkgs lib; };

  inherit (self.packages.aarch64-linux) nixosImage;

  pkgVersion = "1.0-beta.3";

  espSize = readFile (nixosImage + "/esp_size");
  rootSize = readFile (nixosImage + "/root_size");

  installerData = genInstallerData pkgVersion espSize rootSize;
in

stdenv.mkDerivation (finalAttrs: {
  pname = "nixos-asahi";
  version = pkgVersion;

  src = nixosImage;

  nativeBuildInputs = with pkgs; [
    coreutils
    gawk
    jq
    p7zip
    util-linux
  ];

  buildPhase = ''
    runHook preBuild

    diskImage="nixos.img"
    baseDir="$PWD"

    pkgName="${finalAttrs.pname}-${finalAttrs.version}"
    pkgData="installer_data-${finalAttrs.version}.json"
    pkgZip="$pkgName.zip"

    pushd $src > /dev/null
    eval "$(
      fdisk -Lnever -lu -b 512 "$diskImage" | \
      awk "/^$diskImage/ { printf \"dd if=$diskImage of=$baseDir/%s skip=%s count=%s bs=512\\n\", \$1, \$2, \$4 }"
    )"
    popd > /dev/null

    mkdir -p "package/esp"

    7z x -o"package/esp" "''${diskImage}1"
    rm -rf package/esp/EFI/nixos/.extra-files

    mv "''${diskImage}2" package/root.img

    pushd "$baseDir/package" > /dev/null
    7z a -tzip -r -mx1 "$baseDir/$pkgZip" .
    popd > /dev/null

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out

    install -m 644 "$pkgZip" $out
    install -m 644 ${installerData} $out/$pkgData

    runHook postInstall
  '';
})
