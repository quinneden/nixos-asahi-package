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
            config.allowUnfree = true;
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
                system = "aarch64-linux";

                specialArgs = {
                  inherit inputs;
                  modulesPath = inputs.nixpkgs + "/nixos/modules";
                };

                pkgs = import inputs.nixpkgs {
                  config.allowUnfree = true;
                  crossSystem.system = "aarch64-linux";
                  localSystem.system = system;
                  overlays = [ inputs.nixos-apple-silicon.overlays.default ];
                };

                modules = [
                  inputs.nixos-apple-silicon.nixosModules.default
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

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              (python3.withPackages (ps: [ ps.boto3 ]))
              jq
            ];
            shellHook = ''
              ROOT_PATH=$(git rev-parse --show-toplevel)
              exec $ROOT_PATH/scripts/upload.sh
            '';
          };
        }
      );
    };

  nixConfig = {
    extra-substituters = [ "https://nixos-asahi.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-asahi.cachix.org-1:CPH9jazpT/isOQvFhtAZ0Z18XNhAp29+LLVHr0b2qVk="
    ];
  };
}
