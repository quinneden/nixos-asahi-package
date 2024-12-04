{
  lib,
  pkgs,
  self,
  stdenv,
  system,
  ...
}:
let
  date = builtins.readFile (pkgs.runCommand "timestamp" { } "printf `date -u +%Y-%m-%d` > $out");

  asahiImage = self.packages.${system}.asahiImage;

  generate-package = pkgs.writeShellScript "generate-package" ''
    DATE=$(date -u +%Y-%m-%d)
    filename="nixos-asahi-$DATE"

    mkdir -p $out/build

    cd $out/build

    cp ${asahiImage}/nixos.img ./

    start_root=`${pkgs.gptfdisk}/bin/sgdisk --info=2 ./nixos.img | grep '^First sector.*' | awk -F' ' '{print $3}'`
    sectors_root=`${pkgs.gptfdisk}/bin/sgdisk --info=2 ./nixos.img | grep '^Partition size.*' | awk -F' ' '{print $3}'`
    start_boot=`${pkgs.gptfdisk}/bin/sgdisk --info=1 ./nixos.img | grep '^First sector.*' | awk -F' ' '{print $3}'`
    sectors_boot=`${pkgs.gptfdisk}/bin/sgdisk --info=1 ./nixos.img | grep '^Partition size.*' | awk -F' ' '{print $3}'`

    dd if=nixos.img of=root.img bs=512 skip="$start_root" count="$sectors_root"
    dd if=nixos.img of=boot.img bs=512 skip="$start_boot" count="$sectors_boot"

    ${pkgs.p7zip}/bin/7z x $out/build/boot.img -o'esp'
    rm -rf esp/EFI/nixos/.extra-files

    ${pkgs.coreutils}/bin/stat --printf '%s' root.img > $out/.root_part_size

    ${pkgs.zip}/bin/zip -r "$filename".zip esp root.img

    # rm -rf boot.img nixos.img

    ${pkgs.coreutils}/bin/printf '%s' "$DATE" > $out/.release_date
  '';
in
stdenv.mkDerivation rec {
  name = "nixos-asahi-installer-package";
  version = "0.0.2";
  pname = "nixos-asahi-installer-package-${version}";
  src = ./.;
  nativeBuildInputs = [
    asahiImage
    generate-package
  ];
  installPhase = ''
    mv $out/build/nixos-asahi-*.zip $out
  '';
}
