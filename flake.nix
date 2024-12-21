{
  description = "Flake for nixos package for the asahi-linux installer.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-asahi-starter.url = "github:quinneden/nixos-asahi-starter";
    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      nixos-apple-silicon,
      self,
      ...
    }@inputs:
    let
      systems = [ "aarch64-linux" ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            crossSystem.system = "aarch64-linux";
            localSystem.system = system;
            overlays = [
              nixos-apple-silicon.overlays.default
              (import inputs.rust-overlay)
            ];
          };
        in
        {
          installerPackage = pkgs.callPackage ./package.nix { inherit self pkgs; };

          nixosImage =
            let
              image-config = nixpkgs.lib.nixosSystem {
                system = "aarch64-linux";

                specialArgs = {
                  inherit inputs;
                  modulesPath = nixpkgs + "/nixos/modules";
                };

                pkgs = import nixpkgs {
                  inherit system;
                  # overlays = [ ];
                };

                modules = [
                  nixos-apple-silicon.nixosModules.default
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
