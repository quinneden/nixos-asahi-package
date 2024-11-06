{
  description = "Flake for nixos package for the asahi-linux installer.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-asahi = {
      url = "github:zzywysm/nixos-asahi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-asahi-starter.url = "github:quinneden/nixos-asahi-starter";
  };

  outputs =
    {
      lix-module,
      nixos-asahi,
      nixos-generators,
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
                overlays = [ nixos-asahi.overlays.default ];
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
            specialArgs = {
              inherit inputs;
            };
            modules = [
              nixos-asahi.nixosModules.default
              lix-module.nixosModules.default
              ./nixos/config.nix
            ];
            format = "raw-efi";
          };
        }
      );

      templates.default = inputs.nixos-asahi-starter.templates.default;
    };
}
