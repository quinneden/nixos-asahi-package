{ pkgs, ... }:
let
  rootFsUUID = "4ca0bf87-f6f9-48e7-96b8-3dd0437a6703";
in
{
  disko = {
    enableConfig = false;
    memSize = 4096;

    imageBuilder = {
      kernelPackages = pkgs.linuxPackages_latest;
      extraPostVM = ''
        printf '{ espSize = "%s"; rootSize = "%s"; }' \
          $(${pkgs.util-linux}/bin/partx "$out/main.raw" -rgo SIZE -b --nr 1:2) \
        > "$out/partinfo.nix"
      '';
    };

    devices = {
      disk = {
        main = {
          imageSize = "8G";
          type = "disk";
          device = "/dev/vda";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                label = "boot";
                name = "ESP";
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "fmask=0022"
                    "dmask=0022"
                  ];
                };
              };
              root = {
                size = "100%";
                label = "root";
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-L"
                    "nixos"
                    "-U"
                    rootFsUUID
                    "-f"
                  ];
                  subvolumes = {
                    "root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd"
                      ];
                    };
                    "nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/${rootFsUUID}";
      fsType = "btrfs";
      options = [
        "subvol=root"
        "compress=zstd"
        "noatime"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/12CE-A600";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/${rootFsUUID}";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "compress=zstd"
        "noatime"
      ];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/${rootFsUUID}";
      fsType = "btrfs";
      options = [
        "subvol=home"
        "compress=zstd"
      ];
    };
  };
}
