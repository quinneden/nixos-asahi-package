{
  lib,
  pkgs,
  self,
  stdenv,
  ...
}:

let
  inherit (self.packages.aarch64-linux) nixosImage;
  inherit (import ./version.nix) version;

  installerDataJSON =
    with lib;
    utils.generateInstallerData {
      espSize = readFile (nixosImage + "/esp_size");
      rootSize = readFile (nixosImage + "/root_size");
      inherit version;
    };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "nixos-asahi";
  inherit version;

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
    7z a -tzip -r -mx1 "$baseDir/$pkgZip" ./.
    popd > /dev/null

    echo -n ${lib.escapeShellArg installerDataJSON} > $pkgData

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out $pkgZip $pkgData
    runHook postInstall
  '';
})
