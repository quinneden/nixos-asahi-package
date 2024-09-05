{
  description = "Nix flake configuration for disk image to be used with asahi-linux installer.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.90.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    substituters = [
      "https://nixos-asahi.cachix.org"
      "https://nixos-apple-silicon.cachix.org"
    ];
    trusted-public-keys = [
      "nixos-asahi.cachix.org-1:CPH9jazpT/isOQvFhtAZ0Z18XNhAp29+LLVHr0b2qVk="
      "nixos-apple-silicon.cachix.org-1:xkpmN/hWmtMvApu5lYaNPy4sUXc/6Qfd+iTjdLX8HZ0="
    ];
  };

  outputs = {
    nixos-apple-silicon,
    nixos-generators,
    lix-module,
    nixpkgs,
    self,
    ...
  }: let
    system = "aarch64-linux";
    pkgsForSystem = system:
      import nixpkgs {
        inherit system;
        overlays = [nixos-apple-silicon.overlays.default];
      };
    allSystems = ["aarch64-linux"];
    forAllSystems = f:
      nixpkgs.lib.genAttrs allSystems (system:
        f {
          inherit system;
          pkgs = pkgsForSystem system;
        });
  in {
    packages = forAllSystems ({
      system,
      pkgs,
      ...
    }: {
      default = self.packages.aarch64-linux.asahiPackage;
      asahiImage = nixos-generators.nixosGenerate {
        system = system;
        specialArgs = {
          pkgs = pkgs;
          # diskSize = 5 * 1024;
        };
        modules = [
          ({...}: {nix.registry.nixpkgs.flake = nixpkgs;})
          nixos-apple-silicon.nixosModules.default
          lix-module.nixosModules.default
          ./configuration.nix
        ];
        format = "raw-efi";
      };
      asahiPackage = pkgs.callPackage ./generate-package.nix {inherit self pkgs;};
    });
  };
}
