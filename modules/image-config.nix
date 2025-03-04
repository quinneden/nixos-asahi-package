{
  config,
  lib,
  modulesPath,
  pkgs,
  version,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  system.build = lib.genAttrs [ "btrfsImage" "ext4Image" ] (
    imageType:
    let
      fsType = lib.removeSuffix "Image" imageType;
    in
    import ../lib/make-disk-image.nix {
      copyConfig = "${../nixos}";
      fsType = fsType;
      inherit
        config
        lib
        pkgs
        version
        ;

    }
  );

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
      binPath = lib.makeBinPath (
        with pkgs;
        [
          asahi-fwextract
          btrfs-progs
          cpio
          e2fsprogs
          gawk
          parted
          util-linux
        ]
      );
    in
    ''
      PATH=${binPath}:$PATH

      if [[ -f /expand-on-first-boot ]]; then
        # Figure out device names for the boot device and root filesystem.
        rootPart=$(findmnt -nvo SOURCE /)
        rootFsType=$(lsblk -npo FSTYPE "$rootPart")
        firmwareDevice=$(lsblk -npo PKNAME $rootPart)
        partNum=$(lsblk -npo MAJ:MIN "$rootPart" | awk -F: '{print $2}' | tr -d '[:space:]')

        # Resize the root partition and the filesystem to fit the disk
        echo ',+,' | sfdisk -N"$partNum" --no-reread "$firmwareDevice"

        partprobe

        if [[ $rootFsType == "btrfs" ]]; then
          btrfs filesystem resize max /
        else
          resize2fs "$rootPart"
        fi

        rm -f /expand-on-first-boot
      fi

      echo Extracting Asahi firmware...
      mkdir -p /tmp/.fwsetup/{esp,extracted}

      mount /dev/disk/by-partuuid/`cat /proc/device-tree/chosen/asahi,efi-system-partition` /tmp/.fwsetup/esp
      asahi-fwextract /tmp/.fwsetup/esp/asahi /tmp/.fwsetup/extracted
      umount /tmp/.fwsetup/esp

      pushd /tmp/.fwsetup/
      cat /tmp/.fwsetup/extracted/firmware.cpio | cpio -id --quiet --no-absolute-filenames
      mkdir -p /lib/firmware
      mv vendorfw/* /lib/firmware
      popd
      rm -rf /tmp/.fwsetup
    '';

  hardware.asahi = {
    extractPeripheralFirmware = false; # Can't legally be included in the image.
    useExperimentalGPUDriver = true;
    withRust = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/12CE-A600";
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

  environment.systemPackages = [ ];

  programs.git.enable = true;

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
