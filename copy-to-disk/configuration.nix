{
  config,
  pkgs,
  ...
}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };

  nixpkgs.overlays = let
    nixos-apple-silicon = pkgs.fetchFromGithub {
      owner = "tpwrules";
      repo = "nixos-apple-silicon";
      rev = "main";
      sha256 = "";
    };
  in [nixos-apple-silicon.overlays.default];

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
