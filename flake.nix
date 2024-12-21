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
      devShells.aarch64-darwin =
        let
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          secrets = builtins.fromJSON (builtins.readFile ./secrets.json);
          inherit (pkgs) mkShell;
        in
        {
          default = mkShell {
            packages = with pkgs; [ (python3.withPackages (ps: [ ps.boto3 ])) ];
            shellHook = ''
              ACCESS_KEY_ID="${secrets.accessKeyId}"; export ACCESS_KEY_ID
              ACCOUNT_ID="${secrets.accountId}"; export ACCOUNT_ID
              BUCKET_NAME="${secrets.bucketName}"; export BUCKET_NAME
              ENDPOINT_URL="https://$ACCOUNT_ID.r2.cloudflarestorage.com"; export ENDPOINT_URL
              SECRET_ACCESS_KEY="${secrets.secretAccessKey}"; export SECRET_ACCESS_KEY

              confirm() {
                while true; do
                  read -r -n 1 -p "Begin upload? [y/n]: " REPLY
                  case $REPLY in
                    [yY]) echo ; return 0 ;;
                    [nN]) echo ; return 1 ;;
                    *) echo ;;
                  esac
                done
              }

              if confirm; then
                ./scripts/upload.sh
              fi

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
