{
  modulesPath,
  username,
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };
  };

  hardware.asahi = {
    useExperimentalGPUDriver = true;
    experimentalGPUInstallMode = "replace";
    withRust = true;
  };

  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  users.mutableUsers = true;
  users.users."${username}" = {
    shell = "${pkgs.zsh}/bin/zsh";
    initialPassword = "${username}";
    isNormalUser = true;
    extraGroups = ["wheel"];
    packages = with pkgs; [
    ];
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "clean";
      plugins = ["zsh-navigation-tools" "eza"];
      extraConfig = ''
        zstyle ':omz:update' mode auto
        zstyle ':omz:update' frequency 13
      '';
    };
    shellAliases = {
      fuck = "sudo rm -rf";
      gst = "git status";
      gsur = "git submodule update --init --recursive";
      push = "git push";
      tree = "eza -aT -I '.git*'";
    };
  };

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    gh
    git
    eza
    fzf
    micro
    ripgrep
  ];

  system.stateVersion = "24.11";
}
