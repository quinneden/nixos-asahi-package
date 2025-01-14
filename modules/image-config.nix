{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  system.build.image = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    configFile = "${../nixos/configuration.nix}";
    format = "raw";
    memSize = 4096;
    name = "nixos-asahi-image";
    partitionTableType = "efi";
  };

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "usb_storage"
      "usbhid"
    ];

    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;
  };

  boot.postBootCommands =
    let
      inherit (pkgs)
        asahi-fwextract
        util-linux
        gawk
        parted
        e2fsprogs
        cpio
        ;

      expandOnFirstBoot = ''
        if [[ ! -f /nix/var/nix/profiles/default/system ]]; then
          # Figure out device names for the boot device and root filesystem.
          rootPart=$(${util-linux}/bin/findmnt -nvo SOURCE /)
          firmwareDevice=$(lsblk -npo PKNAME $rootPart)
          partNum=$(lsblk -npo MAJ:MIN "$rootPart" | ${gawk}/bin/awk -F: '{print $2}' | tr -d '[:space:]')

          # Resize the root partition and the filesystem to fit the disk
          echo ',+,' | sfdisk -N"$partNum" --no-reread "$firmwareDevice"
          ${parted}/bin/partprobe
          ${e2fsprogs}/bin/resize2fs "$rootPart"
        fi
      '';
    in
    ''
      echo Extracting Asahi firmware...
      mkdir -p /tmp/.fwsetup/{esp,extracted}

      mount /dev/disk/by-partuuid/`cat /proc/device-tree/chosen/asahi,efi-system-partition` /tmp/.fwsetup/esp
      ${asahi-fwextract}/bin/asahi-fwextract /tmp/.fwsetup/esp/asahi /tmp/.fwsetup/extracted
      umount /tmp/.fwsetup/esp

      pushd /tmp/.fwsetup/
      cat /tmp/.fwsetup/extracted/firmware.cpio | ${cpio}/bin/cpio -id --quiet --no-absolute-filenames
      mkdir -p /lib/firmware
      mv vendorfw/* /lib/firmware
      popd
      rm -rf /tmp/.fwsetup

      ${expandOnFirstBoot}
    '';

  hardware.asahi = {
    extractPeripheralFirmware = false; # Extract the firmware during boot because it can't legally be included in the image.
    experimentalGPUInstallMode = "overlay";
    useExperimentalGPUDriver = true;
    setupAsahiSound = true;
    withRust = true;
  };

  documentation.enable = false;

  fileSystems."/" = {
    device = lib.mkForce "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  fileSystems."/boot" = {
    device = lib.mkForce "/dev/disk/by-label/ESP";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  nix.settings = {
    warn-dirty = false;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  networking = {
    networkmanager.enable = true;
    networkmanager.wifi.backend = "iwd";
    wireless.iwd = {
      enable = true;
      settings.General.EnableNetworkConfiguration = true;
    };
  };

  environment.systemPackages = with pkgs; [ git ];

  services = {
    getty.autologinUser = "nixos";
    openssh.enable = true;
  };

  users.mutableUsers = true;

  users.users.nixos = {
    isNormalUser = true;
    initialHashedPassword = "";
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.05";
}
