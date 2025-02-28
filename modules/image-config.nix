{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "usb_storage"
      "usbhid"
    ];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;

    postBootCommands =
      let
        binPath = lib.makeBinPath (
          with pkgs;
          [
            asahi-fwextract
            util-linux
            gawk
            parted
            btrfs-progs
            cpio
          ]
        );

        expandOnFirstBoot = ''
          if [ -f /nix-path-registration ]; then
            # Figure out device names for the boot device and root filesystem.
            rootPart=$(findmnt -nvo SOURCE /)
            firmwareDevice=$(lsblk -npo PKNAME $rootPart)
            partNum=$(
              lsblk -npo MAJ:MIN "$rootPart" |
              awk -F: '{print $2}' |
              tr -d '[:space:]'
            )

            # Resize the root partition and the filesystem to fit the disk
            echo ',+,' | sfdisk -N"$partNum" --no-reread "$firmwareDevice"
            partprobe
            btrfs filesystem resize max /

            # Register the contents of the initial Nix store
            ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration

            # Prevent this from running on later boots.
            rm -f /nix-path-registration
          fi
        '';
      in
      ''
        # Firmware can't legally be included in the image,
        # so we extract it manually at boot.
        PATH=${binPath}:$PATH

        ${expandOnFirstBoot}

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
  };

  documentation.enable = false;

  environment.systemPackages = with pkgs; [
    asahi-bless
    git
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "compress=zstd"
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

    "/home" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "compress=zstd"
        "noatime"
      ];
    };
  };

  hardware.asahi = {
    extractPeripheralFirmware = lib.mkForce false;
    useExperimentalGPUDriver = true;
    setupAsahiSound = true;
    withRust = true;
  };

  networking = {
    networkmanager.enable = true;
    networkmanager.wifi.backend = "iwd";
    wireless.iwd = {
      enable = true;
      settings.General.EnableNetworkConfiguration = true;
    };
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  programs.git.enable = true;
  security.sudo.wheelNeedsPassword = false;

  services = {
    getty.autologinUser = "nixos";
    openssh.enable = true;
  };

  system = {
    build.image = import ../lib/make-btrfs-disk-image.nix {
      inherit config lib pkgs;
    };

    stateVersion = "25.05";
  };

  users.mutableUsers = true;

  users.users.nixos = {
    isNormalUser = true;
    initialHashedPassword = "";
    extraGroups = [ "wheel" ];
  };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };
}
