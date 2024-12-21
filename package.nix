{
  pkgs,
  self,
  stdenv,
  ...
}:
let
  timestamp = builtins.readFile (pkgs.runCommand "timestamp" { } "printf `date -u +%Y-%m-%d` > $out");

  inherit (self.packages.aarch64-linux) nixosImage;
in
stdenv.mkDerivation rec {
  pname = "nixos-asahi";
  version = "${timestamp}";

  src = nixosImage;

  nativeBuildInputs = with pkgs; [
    gptfdisk
    p7zip
    zip
    coreutils
  ];

  buildPhase = ''
    runHook preBuild
    mkdir -p $out

    7z x $src/nixos.img
    7z x ESP.img -o'esp'

    mv primary.img root.img

    rm -rf esp/EFI/nixos/.extra-files

    stat --printf '%s' root.img > $out/root_part_size
    cat <<<${timestamp} > $out/timestamp

    zip -r $out/${pname}-${timestamp}.zip esp root.img

    # rm -rf ESP.img nixos.img root.img esp

    runHook postBuild
  '';
}
