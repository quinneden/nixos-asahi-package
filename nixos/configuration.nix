{ pkgs, ... }:
{
  imports =
    # Import nixos-apple-silicon using fetchTarball since this is a standalone
    # configuration. If using flakes, just add it to inputs.
    let
      nixos-apple-silicon = fetchTarball {
        url = "https://github.com/tpwrules/nixos-apple-silicon/archive/refs/tags/release-2024-12-25.tar.gz";
        sha256 = "sha256-a6n8RsiAolz6p24Fsr/gTndx9xr9USpKqKK6kzBeXQc=";
      };
    in
    [
      (toString nixos-apple-silicon + "/apple-silicon-support")
      ./hardware-configuration.nix
    ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;

    plymouth.enable = true;

    initrd.availableKernelModules = [
      "xhci_pci"
      "usb_storage"
      "usbhid"
    ];
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

  # users.users."FIXME" = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ];
  # };

  users.mutableUsers = true;

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    asahi-bless # reboot to macOS
    firefox
    git
    gparted
    maliit-framework
    maliit-keyboard
    micro
    vim
  ];

  system.stateVersion = "25.05";
}
