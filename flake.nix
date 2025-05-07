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
      inherit (nixpkgs) lib;

      versionInfo = import ./version.nix;
      version =
        if (versionInfo.released == true) then
          versionInfo.version
        else
          (versionInfo.latestRelease.version + "-dirty");

      forEachSystem =
        f:
        lib.genAttrs [ "aarch64-darwin" "aarch64-linux" ] (
          system: f { pkgs = import nixpkgs { inherit system; }; }
        );

      buildPackages = import ./lib/build-packages.nix {
        inherit
          inputs
          lib
          nixpkgs
          version
          ;
      };
    in
    {
      packages.aarch64-linux = buildPackages.mkPackageVariants [
        "btrfs"
        "ext4"
      ];

      apps = forEachSystem (
        { pkgs }:
        {
          create-release = {
            type = "app";
            program = lib.getExe (pkgs.callPackage ./scripts/create-release { });
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

      checks.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.symlinkJoin {
        name = "nixos-asahi-metapackage";
        paths = with self.packages.aarch64-linux.installerPackage; [
          btrfs
          ext4
        ];
      };

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
