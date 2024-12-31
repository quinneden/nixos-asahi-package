{
  config,
  lib,
  modulesPath,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (inputs.nixpkgs + "/nixos/lib/make-disk-image.nix")
  ];

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
      expandOnBoot = ''
        rootPart=$(${util-linux}/bin/findmnt -n -o SOURCE /)
        bootDevice=$(lsblk -npo PKNAME $rootPart)
        partNum=$(lsblk -npo MAJ:MIN $rootPart | ${pkgs.gawk}/bin/awk -F: '{print $2}')

        # Resize the root partition and the filesystem to fit the disk
        echo ",+," | sfdisk -N$partNum --no-reread $bootDevice
        ${parted}/bin/partprobe
        ${e2fsprogs}/bin/resize2fs $rootPart
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

      if [[ ! -f /nix/var/nix/profiles/default/system ]]; then
        ${expandOnBoot}
      fi
    '';

  hardware.asahi = {
    extractPeripheralFirmware = false;
    experimentalGPUInstallMode = "replace";
    useExperimentalGPUDriver = true;
    setupAsahiSound = true;
    withRust = true;
  };

  documentation.enable = false;

  fileSystems."/" = {
    device = lib.mkForce "/dev/disk/by-uuid/f222513b-ded1-49fa-b591-20ce86a2fe7f";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = lib.mkForce "/dev/disk/by-uuid/12CE-A600";
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

  environment.systemPackages = with pkgs; [
    git
  ];

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
