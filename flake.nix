{
  description = "NixOS disk image with apple silicon support and zip archive of the image for the asahi-installer.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
      systems = [
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSystem = inputs.nixpkgs.lib.genAttrs systems;

      secrets = builtins.fromJSON (builtins.readFile ./secrets.json);
    in
    {
      packages = forEachSystem (
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
                pkgs = import nixpkgs { inherit system; };

                specialArgs = {
                  inherit inputs;
                  modulesPath = nixpkgs + "/nixos/modules";
                };

                modules = [
                  nixos-apple-silicon.nixosModules.default
                  ./nixos/image-config.nix
                ];
              };

              config = image-config.config;
            in
            config.system.build.image.override {
              partitionTableType = "efi";
              configFile = "${./nixos/configuration.nix}";
              fsType = "ext4";
              memSize = 4096;
              name = "nixos-asahi";
              format = "raw";
            };
        }
      );

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem rec {
        system = "aarch64-linux";

        specialArgs = {
          inherit inputs;
          modulesPath = nixpkgs + "/nixos/modules";
        };

        pkgs = import nixpkgs {
          inherit system;
        };

        modules = [
          nixos-apple-silicon.nixosModules.default
          ./nixos/configuration.nix
        ];
      };

      apps = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) lib writeShellApplication;
        in
        with lib;
        rec {
          default = upload;

          upload = {
            type = "app";
            program = getExe (writeShellApplication {
              name = "upload";
              runtimeInputs = with pkgs; [ (python3.withPackages (ps: [ ps.boto3 ])) ];
              text = ''
                ACCESS_KEY_ID="${secrets.accessKeyId}"; export ACCESS_KEY_ID
                ACCOUNT_ID="${secrets.accountId}"; export ACCOUNT_ID
                BUCKET_NAME="${secrets.bucketName}"; export BUCKET_NAME
                ENDPOINT_URL="https://$ACCOUNT_ID.r2.cloudflarestorage.com"; export ENDPOINT_URL
                SECRET_ACCESS_KEY="${secrets.secretAccessKey}"; export SECRET_ACCESS_KEY

                echo 'Press enter to continue...'
                read -r
                exec ${./scripts/upload.sh}
              '';
            });
          };
        }
      );

      devShells.aarch64-darwin =
        let
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          inherit (pkgs) mkShell;
        in
        {
          default = mkShell {
            name = "boto3";
            packages = with pkgs; [
              (python3.withPackages (ps: [ ps.boto3 ]))
            ];

            shellHook = ''
              ACCESS_KEY_ID="${secrets.accessKeyId}"; export ACCESS_KEY_ID
              ACCOUNT_ID="${secrets.accountId}"; export ACCOUNT_ID
              BUCKET_NAME="${secrets.bucketName}"; export BUCKET_NAME
              ENDPOINT_URL="https://$ACCOUNT_ID.r2.cloudflarestorage.com"; export ENDPOINT_URL
              SECRET_ACCESS_KEY="${secrets.secretAccessKey}"; export SECRET_ACCESS_KEY

              exec zsh
              exit
            '';
          };
        };
    };

  nixConfig = {
    extra-substituters = [ "https://nixos-asahi.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-asahi.cachix.org-1:CPH9jazpT/isOQvFhtAZ0Z18XNhAp29+LLVHr0b2qVk="
    ];
  };
}
