{
  description = "Flake for nixos package for the asahi-linux installer.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-asahi-starter.url = "github:quinneden/nixos-asahi-starter";
    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.1-2.tar.gz";
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
            # config.allowUnfree = true;
            crossSystem.system = "aarch64-linux";
            localSystem.system = system;
            overlays = [ inputs.nixos-apple-silicon.overlays.default ];
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
                  # config.allowUnfree = true;
                  crossSystem.system = "aarch64-linux";
                  localSystem.system = system;
                  overlays = [ inputs.nixos-apple-silicon.overlays.default ];
                };

                modules = [
                  inputs.nixos-apple-silicon.nixosModules.default
                  inputs.lix-module.nixosModules.lixFromNixpkgs
                  ./nixos
                ];
              };

              config = image-config.config;
            in
            config.system.build.image;
        }
      );

      templates.default = inputs.nixos-asahi-starter.templates.default;

      devShells = forAllSystems (
        system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          secrets = builtins.fromJSON (builtins.readFile .secrets/secrets.json);
          inherit (self.packages.${system}) asahiPackage;
        in
        {
          default = import ./shell.nix { inherit pkgs asahiPackage secrets; };
        }
      );

      # apps = forAllSystems (
      #   system:
      #   let
      #     inherit system;
      #     pkgs = import nixpkgs {
      #       crossSystem.system = "aarch64-linux";
      #       localSystem.system = system;
      #     };
      #     secrets = builtins.fromJSON (builtins.readFile .secrets/secrets.json);
      #   in
      #   {
      #     upload = import ./upload.nix { inherit self pkgs secrets; };
      #   }
      # );
    };

  nixConfig = {
    extra-substituters = [
      "https://nixos-asahi.cachix.org"
      "https://nixpkgs-cross-overlay.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-asahi.cachix.org-1:CPH9jazpT/isOQvFhtAZ0Z18XNhAp29+LLVHr0b2qVk="
      "nixpkgs-cross-overlay.cachix.org-1:TjKExGN4ys960TlsGqNOI/NBdoz2Jdr2ow1VybWV5JM="
    ];
  };
}
