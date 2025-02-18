{
  lib,
  pkgs,
  self,
  stdenv,
  ...
}:

let
  inherit (self.packages.${pkgs.system}) btrfsImage;
  inherit (import ./version.nix) version;

  installerDataJSON =
    with lib;
    utils.generateInstallerData {
      inherit version;
      inherit (import "${btrfsImage}/partinfo.nix")
        espSize
        rootSize
        ;
    };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "nixos-asahi";
  inherit version;

  src = btrfsImage;

  nativeBuildInputs = with pkgs; [
    coreutils
    gawk
    jq
    p7zip
    util-linux
  ];

  buildPhase = ''
    runHook preBuild

    diskImage="main.raw"

    pkgName="${finalAttrs.pname}-${finalAttrs.version}"
    pkgData="installer_data-${finalAttrs.version}.json"
    pkgZip="$pkgName.zip"

    eval "$(
      fdisk -Lnever -lu -b 512 "$diskImage" |
      awk "/^$diskImage/ { printf \"dd if=$diskImage of=%s skip=%s count=%s bs=512\\n\", \$1, \$2, \$4 }"
    )"

    mkdir -p "package/esp"

    7z x -o"package/esp" "''${diskImage}1"
    rm -rf package/esp/EFI/nixos/.extra-files

    mv "''${diskImage}2" package/root.img

    pushd package/ > /dev/null
    echo -n 'creating compressed archive:'
    7z a -tzip -r -mx1 -bso0 ../"$pkgZip" ./.
    popd > /dev/null

    jq <<< ${lib.escapeShellArg installerDataJSON} > $pkgData

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out $pkgZip $pkgData
    runHook postInstall
  '';
})
