{ lib, ... }:
{
  generateInstallerData =
    {
      baseUrl ? "https://pub-4b458b0cfaa1441eb321ecefef7d540e.r2.dev",
      espSize,
      fsType,
      rootSize,
      version ? (import ./version.nix).version,
    }:
    let
      nixpkgsVersion = lib.versions.majorMinor lib.version;
      pkgName = "nixos-asahi-" + version + "-" + fsType;
    in
    lib.generators.toJSON { } {
      name = "NixOS ${nixpkgsVersion} (${pkgName})";
      default_os_name = "NixOS";

      boot_object = "m1n1.bin";
      next_object = "m1n1/boot.bin";

      package = baseUrl + "/os/" + pkgName + ".zip";

      supported_fw = [
        "12.3"
        "12.3.1"
        "13.5"
      ];

      partitions = [
        {
          name = "EFI";
          type = "EFI";
          size = "${toString espSize}B";
          format = "fat";
          volume_id = "0x12cea600";
          copy_firmware = true;
          copy_installer_data = true;
          source = "esp";
        }
        {
          name = "Root";
          type = "Linux";
          size = "${toString rootSize}B";
          expand = true;
          image = "root.img";
        }
      ];
    };
}
