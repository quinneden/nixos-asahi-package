{
  config,
  pkgs,
  ...
}: let
  nixos-apple-silicon = pkgs.fetchFromGithub {
    owner = "tpwrules";
    repo = "nixos-apple-silicon";
    rev = "main";
    sha256 = "sha256-2zPzPP9Eu5NxgJxTVcuCCX5xh7CWy7rYaLHfaAZS6H8=";
  };
in {
  imports = [
    ./hardware-configuration.nix
    nixos-apple-silicon.nixosModules.default
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

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f222513b-ded1-49fa-b591-20ce86a2fe7f";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/12CE-A600";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };

  nixpkgs.overlays = [nixos-apple-silicon.overlays.default];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  i18n.defaultLocale = "en_US.UTF-8";

  users.mutableUsers = true;
  users.users.root.initialPassword = "nixos";

  environment.systemPackages = with pkgs; [
    curl
    git
    gptfdisk
    parted
    ripgrep
    wget
  ];

  system.stateVersion = "24.11";
}
