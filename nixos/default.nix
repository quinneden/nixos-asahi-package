{
  modulesPath,
  make-disk-image,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "usb_storage"
      "usbhid"
    ];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;
    growPartition = true;
  };

  boot.postBootCommands =
    let
      inherit (pkgs) asahi-fwextract;
    in
    ''
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

  system.build.image = (
    import "${toString modulesPath} + /../lib/make-disk-image.nix" {
      inherit lib config pkgs;
      partitionTableType = "efi";
      fsType = "ext4";
      # configFile = "";
      memSize = 2048;
      name = "nixos-asahi-image";
      format = "raw";
    }
  );

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
    extra-substituters = [ "https://cache.lix.systems" ];
    extra-trusted-public-keys = [ "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=" ];
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

  users.mutableUsers = true;

  # users.users.nixos = {
  #   isNormalUser = true;
  #   initialHashedPassword = "";
  #   extraGroups = [ "wheel" ];
  # };

  users.users.root.initialHashedPassword = "";

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "24.11";
}
