{
  image,
  lib,
  pkgs,
  stdenv,
  version,
  ...
}:

let
  partInfo = import (image + "/partinfo.nix");

  installerDataJSON = lib.utils.generateInstallerData {
    baseUrl = "https://pub-fde369a15aa048a4862bc80e0af2e747.r2.dev";
    inherit version;
    inherit (partInfo)
      espSize
      fsType
      rootSize
      ;
  };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "nixos-asahi";
  version = version + "-${partInfo.fsType}";

  src = image;

  nativeBuildInputs = with pkgs; [
    coreutils
    gawk
    jq
    p7zip
    util-linux
  ];

  buildPhase = ''
    runHook preBuild

    diskImage="${image.name}.img"
    pkgData="installer_data-${finalAttrs.version}.json"
    pkgZip="${finalAttrs.pname}-${finalAttrs.version}.zip"

    eval "$(
      fdisk -Lnever -lu -b 512 "$diskImage" |
      awk "/^$diskImage/ { printf \"dd if=$diskImage of=%s skip=%s count=%s bs=512\\n\", \$1, \$2, \$4 }"
    )"

    mkdir -p package/esp

    7z x -o"package/esp" "''${diskImage}1"
    mv "''${diskImage}2" package/root.img

    pushd package/ > /dev/null || exit 1

    echo -n 'creating compressed archive:'
    7z a -tzip -r -mx1 -bso0 ../"$pkgZip" ./.

    popd > /dev/null || exit 1

    jq <<< ${lib.escapeShellArg installerDataJSON} > "$pkgData"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out $pkgZip $pkgData
    runHook postInstall
  '';
})
