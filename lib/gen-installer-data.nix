{ pkgs, lib }:
let
  baseUrl = "https://pub-4b458b0cfaa1441eb321ecefef7d540e.r2.dev";
  majorMinor = lib.versions.majorMinor lib.version;
  inherit (pkgs) writeText;
in
with lib;
pkgVersion: espSize: rootSize:
let
  pkgName = "nixos-asahi-" + pkgVersion;
in
writeText (pkgName + ".json") (
  generators.toJSON { } {
    name = "NixOS ${majorMinor} (${pkgName})";
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
        size = espSize + "B";
        format = "fat";
        volume_id = "0x12cea600";
        copy_firmware = true;
        copy_installer_data = true;
        source = "esp";
      }
      {
        name = "Root";
        type = "Linux";
        size = rootSize + "B";
        expand = true;
        image = "root.img";
      }
    ];
  }
)
