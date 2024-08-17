{
  modulesPath,
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/clone-config.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = ["xhci_pci" "usb_storage" "usbhid"];
      kernelModules = [];
    };
    kernelModules = [];
    extraModulePackages = [];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;
  };

  installer.cloneConfig = true;
  installer.cloneConfigIncludes = [
    "./copy-to-disk/configuration.nix"
  ];

  boot.postBootCommands = let
    inherit (pkgs) asahi-fwextract;
  in ''
    echo Extracting Asahi firmware...
    mkdir -p /tmp/.fwsetup/{esp,extracted}

    mount /dev/disk/by-partuuid/`cat /proc/device-tree/chosen/asahi,efi-system-partition` /tmp/.fwsetup/esp
    ${asahi-fwextract}/bin/asahi-fwextract /tmp/.fwsetup/esp/asahi /tmp/.fwsetup/extracted
    umount /tmp/.fwsetup/esp

    pushd /tmp/.fwsetup/
    cat /tmp/.fwsetup/extracted/firmware.cpio | ${pkgs.cpio}/bin/cpio -id --quiet --no-absolute-filenames
    mkdir -p /lib/firmware
    mv vendorfw/* /lib/firmware
    popd
    rm -rf /tmp/.fwsetup

    if [ ! -f /etc/nixos/configuration.nix ]; then
      mkdir -p /etc/nixos
      cp ${./copy-to-disk/configuration.nix} /etc/nixos/configuration.nix
    fi
  '';

  hardware.asahi.extractPeripheralFirmware = false;

  documentation = {
    enable = false;
  };

  fileSystems."/" = {
    device = lib.mkForce "/dev/disk/by-uuid/f222513b-ded1-49fa-b591-20ce86a2fe7f";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = lib.mkForce "/dev/disk/by-uuid/12CE-A600";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  nix.settings = {
    warn-dirty = false;
    experimental-features = ["nix-command" "flakes"];
  };

  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };

  users.mutableUsers = true;
  users.users.root.initialPassword = "nixos";

  system.stateVersion = "24.11";
}
