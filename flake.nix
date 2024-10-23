{
  description = "Flake for nixos package for the asahi-linux installer.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-asahi-starter.url = "github:quinneden/nixos-asahi-starter";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixos-apple-silicon,
      nixos-generators,
      lix-module,
      nixpkgs,
      self,
      ...
    }@inputs:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs
          [
            "aarch64-linux"
            "aarch64-darwin"
          ]
          (
            system:
            function (
              import nixpkgs {
                system = "aarch64-linux";
                config.allowUnfree = true;
                overlays = [ nixos-apple-silicon.overlays.default ];
              }
            )
          );
    in
    {
      packages = forAllSystems (
        {
          system,
          pkgs,
          ...
        }:
        {
          default = self.packages.${system}.asahiPackage;

          asahiPackage = pkgs.callPackage ./generate-package.nix { inherit self pkgs inputs; };

          asahiImage = nixos-generators.nixosGenerate {
            system = "aarch64-linux";
            pkgs = import nixpkgs {
              system = "aarch64-linux";
              config.allowUnfree = true;
              overlays = [ nixos-apple-silicon.overlays.default ];
            };
            specialArgs = {
              inherit inputs;
            };
            modules = [
              nixos-apple-silicon.nixosModules.default
              lix-module.nixosModules.lixFromNixpkgs
              ./nixos
            ];
            format = "raw-efi";
          };
        }
      );

      templates.default = inputs.nixos-asahi-starter.templates.default;
    };
}
