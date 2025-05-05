{
  description = "NixOS package for the Asahi-installer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, self, ... }@inputs:
    let
      forEachSystem =
        f:
        lib.genAttrs [
          "aarch64-darwin"
          "aarch64-linux"
        ] (system: f { pkgs = import nixpkgs { inherit system; }; });

      lib = nixpkgs.lib.extend (
        self: super: { utils = import ./lib/utils.nix { inherit (nixpkgs) lib; }; }
      );

      versionInfo = import ./version.nix;
      version = versionInfo.version + (lib.optionalString (!versionInfo.released) "-dirty");
    in
    {
      packages.aarch64-linux =
        let
          pkgs = import nixpkgs { system = "aarch64-linux"; };

          imageConfig =
            fsType:
            lib.nixosSystem {
              system = "aarch64-linux";

              specialArgs = {
                modulesPath = nixpkgs + "/nixos/modules";
                inherit fsType inputs version;
              };

              modules = [ ./modules/image-config.nix ];
            };
        in
        rec {
          installerPackage = pkgs.callPackage ./package.nix {
            inherit lib version;
            image = btrfsImage;
          };

          btrfsImage = (imageConfig "btrfs").config.system.build.btrfsImage // {
            passthru = { inherit (imageConfig "btrfs") config; };
          };

          ext4Image = (imageConfig "ext4").config.system.build.ext4Image // {
            passthru = { inherit (imageConfig "ext4") config; };
          };
        };

      apps = forEachSystem (
        { pkgs }:
        {
          create-release = {
            type = "app";
            program = lib.getExe (pkgs.callPackage ./scripts/create-release { inherit version; });
          };

          upload = {
            type = "app";
            program = lib.getExe (pkgs.callPackage ./scripts/upload { });
          };
        }
      );

      devShells = forEachSystem (
        { pkgs }:
        rec {
          default = boto3;

          boto3 = pkgs.mkShell {
            name = "boto3";
            packages = [
              (pkgs.python3.withPackages (
                ps: with ps; [
                  boto3
                  requests
                  tqdm
                ]
              ))
            ];
            shellHook = ''
              source .env || true
            '';
          };
        }
      );

      checks.aarch64-linux = { inherit (self.packages.aarch64-linux) installerPackage; };
      formatter = forEachSystem ({ pkgs }: pkgs.nixfmt-rfc-style);
    };

  nixConfig = {
    download-buffer-size = "128M";
    extra-substituters = [ "https://nixos-asahi.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-asahi.cachix.org-1:CPH9jazpT/isOQvFhtAZ0Z18XNhAp29+LLVHr0b2qVk="
    ];
  };
}
