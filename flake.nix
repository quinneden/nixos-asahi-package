{
  description = "Nix flake configuration for disk image to be used with asahi-linux installer.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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

  # nixConfig = {
  #   substituters = [
  #     "https://nixos-asahi.cachix.org"
  #   ];
  #   trusted-public-keys = [
  #     "nixos-asahi.cachix.org-1:CPH9jazpT/isOQvFhtAZ0Z18XNhAp29+LLVHr0b2qVk="
  #   ];
  # };

  outputs = {
    nixos-apple-silicon,
    nixos-generators,
    lix-module,
    nixpkgs,
    self,
    ...
  } @ inputs: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "aarch64-darwin"
      ] (system:
        function (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [nixos-apple-silicon.overlays.default];
        }));
  in {
    packages = forAllSystems ({
      system,
      pkgs,
      ...
    }: {
      default = self.packages.${self.system}.asahiPackage;
      asahiImage = nixos-generators.nixosGenerate {
        system = "aarch64-linux";
        pkgs = import nixpkgs {
          system = "aarch64-linux";
          config.allowUnfree = true;
          overlays = [nixos-apple-silicon.overlays.default];
        };
        specialArgs = {inherit inputs;};
        modules = [
          ({...}: {nix.registry.nixpkgs.flake = nixpkgs;})
          nixos-apple-silicon.nixosModules.default
          lix-module.nixosModules.lixFromNixpkgs
          ./configuration.nix
        ];
        format = "raw-efi";
      };
      asahiPackage = pkgs.callPackage ./generate-package.nix {inherit self pkgs;};
    });

    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        pkgs = import nixpkgs {
          config.allowUnfree = true;
          overlays = [nixos-apple-silicon.overlays.default];
        };
        specialArgs = {
          inherit self inputs;
          username = "FIXME"; # Replace with your username.
        };
        modules = [
          nixos-apple-silicon.nixosModules.default
          lix-module.nixosModules.default
          ./configuration.nix
          {
            boot.postBootCommands = ''
              if [[ ! -e /etc/nixos ]]; then
                cp -r ${./nixos} /etc/
              fi
            '';
          }
        ];
      };
    };
  };
}
