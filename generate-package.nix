{
  pkgs,
  stdenv,
  self,
  lib,
  ...
}: let
  generate-package = pkgs.writeShellScript "generate-package" ''
    TZ="America/Los_Angeles"
    DATE=`date "+%d%m%y"`
    filename="nixos-asahi-$DATE"

    start_root=`${pkgs.gptfdisk}/bin/sgdisk --info=2 ${self.packages.aarch64-linux.asahiImage}/nixos.img | grep '^First sector.*' | awk -F' ' '{print $3}'`
    sectors_root=`${pkgs.gptfdisk}/bin/sgdisk --info=2 ${self.packages.aarch64-linux.asahiImage}/nixos.img | grep '^Partition size.*' | awk -F' ' '{print $3}'`
    start_boot=`${pkgs.gptfdisk}/bin/sgdisk --info=1 ${self.packages.aarch64-linux.asahiImage}/nixos.img | grep '^First sector.*' | awk -F' ' '{print $3}'`
    sectors_boot=`${pkgs.gptfdisk}/bin/sgdisk --info=1 ${self.packages.aarch64-linux.asahiImage}/nixos.img | grep '^Partition size.*' | awk -F' ' '{print $3}'`

    mkdir -p $out/package
    cp ${self.packages.aarch64-linux.asahiImage}/nixos.img $out

    dd if=$out/nixos.img of=$out/root.img bs=512 skip="$start_root" count="$sectors_root"
    dd if=$out/nixos.img of=$out/boot.img bs=512 skip="$start_boot" count="$sectors_boot"

    ${pkgs.p7zip}/bin/7z x $out/boot.img -o$out/esp

    ${pkgs.coreutils}/bin/stat -c "%s" $out/root.img > $out/.tag_rootimg_size

    cd $out; ${pkgs.zip}/bin/zip -r ./package/"$filename".zip esp root.img
    chmod 644 $out/package/"$filename".zip

    rm -rf $out/{esp,root.img,boot.img,nixos.img}
      echo "$DATE" > $out/DATE
  '';
in
  stdenv.mkDerivation {
    name = "generate-package";
    src = ./.;
    buildInputs = [generate-package];
  }
