{
  pkgs,
  self,
  stdenv,
  ...
}:
let
  timestamp = builtins.readFile (pkgs.runCommand "timestamp" { } "printf `date -u +%Y-%m-%d` > $out");

  substDataJSON = pkgs.writeShellScriptBin "write-installer-data" ''
    rootSize="$(cat $out/root_part_size)B"
    jq -r < ${./data/installer_data.json} \
      ".package = \"https://cdn.qeden.systems/os/nixos-asahi-${timestamp}.zip\" |
      .partitions.[1].size = \"$rootSize\" |
      .name = \"NixOS (${timestamp})\""
  '';

  inherit (self.packages.aarch64-linux) nixosImage;
in
stdenv.mkDerivation rec {
  pname = "nixos-asahi";
  version = "${timestamp}";

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
    mkdir -p $out

    7z x $src/nixos.img
    7z x ESP.img -o'esp'

    mv primary.img root.img

    rm -rf esp/EFI/nixos/.extra-files

    stat --printf '%s' root.img > $out/root_part_size
    cat <<<${timestamp} > $out/timestamp

    zip -r $out/${pname}-${timestamp}.zip esp root.img

    ${substDataJSON}/bin/write-installer-data > $out/${pname}-${timestamp}.json

    runHook postBuild
  '';
}
