{
  modulesPath,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports =
    let
      nixos-apple-silicon = builtins.getFlake "github:tpwrules/nixos-apple-silicon";
    in
    [ (toString nixos-apple-silicon + "/apple-silicon-support") ];

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
    experimentalGPUInstallMode = "replace";
    useExperimentalGPUDriver = true;
    setupAsahiSound = true;
    withRust = true;
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

  services.openssh.enable = true;

  users.mutableUsers = true;

  system.stateVersion = "25.05";
}
