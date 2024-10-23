{ pkgs, ... }:
{
  services = {
    desktopManager.plasma6.enable = true;

    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
      autoLogin = {
        enable = true;
        user = "nixos";
      };
    };
  };

  environment.systemPackages = [
    pkgs.maliit-framework
    pkgs.maliit-keyboard
  ];

  programs.xwayland.enable = true;
}
