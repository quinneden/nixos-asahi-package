{
  description = "Flake for nixos package for the asahi-linux installer.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nixos-asahi-starter.url = "github:quinneden/nixos-asahi-starter";
    nixos-asahi = {
      url = "github:zzywysm/nixos-asahi";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      self,
      ...
    }@inputs:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
      ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import inputs.nixpkgs {
            config.allowUnfree = true;
            crossSystem.system = "aarch64-linux";
            localSystem.system = system;
            overlays = [ inputs.nixos-asahi.overlays.default ];
          };
        in
        {
          asahiPackage = pkgs.callPackage ./generate-package.nix { inherit self pkgs inputs; };

          asahiImage =
            let
              image-config = inputs.nixpkgs.lib.nixosSystem {
                inherit system;

                specialArgs = {
                  inherit inputs;
                  modulesPath = inputs.nixpkgs + "/nixos/modules";
                };

                pkgs = import inputs.nixpkgs {
                  crossSystem.system = "aarch64-linux";
                  localSystem.system = system;
                  overlays = [ inputs.nixos-asahi.overlays.default ];
                };

                modules = [
                  inputs.nixos-asahi.nixosModules.default
                  inputs.lix-module.nixosModules.default
                  ./nixos
                ];
              };

              config = image-config.config;
            in
            config.system.build.image;
        }
      );

      templates.default = inputs.nixos-asahi-starter.templates.default;
    };
  nixConfig = {
    extra-substituters = [ "https://nixos-asahi.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-asahi.cachix.org-1:CPH9jazpT/isOQvFhtAZ0Z18XNhAp29+LLVHr0b2qVk="
    ];
  };
}
