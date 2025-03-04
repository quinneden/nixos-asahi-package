{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-apple-silicon.nixosModules.default
    # ./hardware-configuration.nix
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

  hardware.asahi = {
    useExperimentalGPUDriver = true;
    setupAsahiSound = true;
    withRust = true;
  };

  fileSystems = {
    "/".options = [ "compress=zstd" ];
    "/home".options = [ "compress=zstd" ];
    "/nix".options = [
      "compress=zstd"
      "noatime"
    ];
  };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
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
    asahi-bless
    git
  ];

  users.mutableUsers = true;

  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ];
  # };

  system.stateVersion = "25.05";
}
