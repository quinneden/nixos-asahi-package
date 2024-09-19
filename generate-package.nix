{
  pkgs,
  stdenv,
  self,
  lib,
  ...
}: let
  version-tag = builtins.readFile ./.version_tag;
  generate-package = pkgs.writeShellScript "generate-package" ''
    DATE=$(date -u "+%Y%d%m")
    filename="nixos-asahi-$DATE"

    mkdir -p $out/package
    cp ${self.packages.aarch64-darwin.asahiImage}/nixos.img $out

    start_root=`${pkgs.gptfdisk}/bin/sgdisk --info=2 $out/nixos.img | grep '^First sector.*' | awk -F' ' '{print $3}'`
    sectors_root=`${pkgs.gptfdisk}/bin/sgdisk --info=2 $out/nixos.img | grep '^Partition size.*' | awk -F' ' '{print $3}'`
    start_boot=`${pkgs.gptfdisk}/bin/sgdisk --info=1 $out/nixos.img | grep '^First sector.*' | awk -F' ' '{print $3}'`
    sectors_boot=`${pkgs.gptfdisk}/bin/sgdisk --info=1 $out/nixos.img | grep '^Partition size.*' | awk -F' ' '{print $3}'`

    dd if=$out/nixos.img of=$out/root.img bs=512 skip="$start_root" count="$sectors_root"
    dd if=$out/nixos.img of=$out/boot.img bs=512 skip="$start_boot" count="$sectors_boot"

    ${pkgs.p7zip}/bin/7z x $out/boot.img -o$out/esp
    rm -rf $out/esp/EFI/nixos/.extra-files

    ${pkgs.coreutils}/bin/stat -c "%s" $out/root.img > $out/.tag_rootsize

    cd $out; ${pkgs.zip}/bin/zip -r ./package/"$filename".zip esp root.img
    chmod 644 $out/package/"$filename".zip

    rm -rf $out/{esp,root.img,boot.img,nixos.img}
  '';
in
  stdenv.mkDerivation {
    name = "nixos-asahi-package";
    version = version-tag;
    pname = "nixos-asahi-package-${version-tag}";
    src = ./.;
    buildInputs = [generate-package];
  }
