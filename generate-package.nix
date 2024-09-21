{
  pkgs,
  stdenv,
  self,
  lib,
  ...
}: let
  date = builtins.readFile (pkgs.runCommand "timestamp" {} "echo -n `date -u +%Y-%m-%d` > $out");
  generate-package = pkgs.writeShellScript "generate-package" ''
    filename="nixos-asahi-${date}"

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

    ${pkgs.coreutils}/bin/stat -c "%s" $out/root.img > $out/.root_part_size

    cd $out; ${pkgs.zip}/bin/zip -r ./package/"$filename".zip esp root.img

    rm -rf $out/{esp,root.img,boot.img,nixos.img}

    printf "${date}" > $out/.release_date
  '';
in
  stdenv.mkDerivation {
    name = "nixos-asahi-installer-package";
    version = date;
    pname = "nixos-asahi-installer-package-${date}";
    src = ./.;
    buildInputs = [generate-package];
  }
