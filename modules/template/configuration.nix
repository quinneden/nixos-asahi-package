{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-apple-silicon.nixosModules.default
    # Run `sudo nixos-generate-config --show-hardware-config | tee hardware-configuration.nix`
    # and uncomment this line.
    # ./hardware-configuration.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;
  };

  hardware.asahi = {
    peripheralFirmwareDirectory = /boot/asahi;
    setupAsahiSound = true;
    useExperimentalGPUDriver = true;
    withRust = true;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  nix.settings = {
    experimental-features = [
      "flakes"
      "nix-command"
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
