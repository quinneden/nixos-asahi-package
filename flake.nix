{
  description = "Configuration for a NixOS disk image and zipfile to be consumed by the asahi-installer.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    secrets = {
      url = "git+ssh://git@github.com/quinneden/secrets.git?ref=main&shallow=1";
      inputs = { };
    };

    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixos-apple-silicon,
      secrets,
      self,
      ...
    }:
    let
      forEachSystem =
        function:
        nixpkgs.lib.genAttrs
          [
            "aarch64-darwin"
            "aarch64-linux"
          ]
          (
            system:
            function {
              pkgs = import nixpkgs {
                inherit system;
                overlays = [ nixos-apple-silicon.overlays.default ];
              };
            }
          );
    in
    {
      packages = forEachSystem (
        { pkgs }:
        {
          installerPackage = pkgs.callPackage ./package.nix { inherit self pkgs; };

          nixosImage =
            let
              image-config = nixpkgs.lib.nixosSystem rec {
                system = "aarch64-linux";
                pkgs = import nixpkgs { inherit system; };

                specialArgs = {
                  modulesPath = nixpkgs + "/nixos/modules";
                };

                modules = [
                  nixos-apple-silicon.nixosModules.default
                  ./modules/image-config.nix
                ];
              };

              config = image-config.config;
            in
            config.system.build.image;
        }
      );

      apps = forEachSystem (
        { pkgs }:
        rec {
          default = upload;

          upload = {
            type = "app";
            program = import ./app.nix { inherit pkgs secrets self; };
          };

          decrypt =
            let
              inherit (pkgs) lib writeShellApplication;
            in
            with lib;
            {
              type = "app";
              program = getExe (writeShellApplication {
                name = "decrypt-secrets";
                runtimeInputs = [ pkgs.git-crypt ];
                text = ''
                  [[ $# -gt 0 ]] || exit 1
                  base64 -d <<< "$1" | git-crypt unlock -
                '';
              });
            };
        }
      );

      devShells = forEachSystem (
        { pkgs }:
        rec {
          default = boto3;

          boto3 = pkgs.mkShell {
            name = "boto3";

            packages = with pkgs; [ (python3.withPackages (ps: [ ps.boto3 ])) ];

            shellHook = ''
              ACCESS_KEY_ID="${secrets.nixos-asahi-package.accessKeyId}"; export ACCESS_KEY_ID
              ACCOUNT_ID="${secrets.nixos-asahi-package.accountId}"; export ACCOUNT_ID
              BUCKET_NAME="${secrets.nixos-asahi-package.bucketName}"; export BUCKET_NAME
              ENDPOINT_URL="https://$ACCOUNT_ID.r2.cloudflarestorage.com"; export ENDPOINT_URL
              SECRET_ACCESS_KEY="${secrets.nixos-asahi-package.secretAccessKey}"; export SECRET_ACCESS_KEY
            '';
          };
        }
      );

      formatter = forEachSystem (pkgs: pkgs.nixfmt-rfc-style);
    };

  nixConfig = {
    extra-substituters = [
      "https://nixos-asahi.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-asahi.cachix.org-1:CPH9jazpT/isOQvFhtAZ0Z18XNhAp29+LLVHr0b2qVk="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    download-buffer-size = 134217728;
  };
}
