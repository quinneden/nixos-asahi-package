{
  description = "NixOS package for the Asahi-installer.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
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
      forEachSystem = lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
      ];

      lib = nixpkgs.lib.extend (
        self: super: { utils = import ./lib/utils.nix { inherit (nixpkgs) lib; }; }
      );

      pkgs = import nixpkgs { system = "aarch64-linux"; };

      versionInfo = import ./version.nix;
      version = versionInfo.version + (lib.optionalString (!versionInfo.released) "-dirty");
    in
    {
      packages.aarch64-linux =
        let
          imageConfig = lib.nixosSystem rec {
            system = "aarch64-linux";
            pkgs = import nixpkgs { inherit system; };

            specialArgs = {
              modulesPath = nixpkgs + "/nixos/modules";
              inherit version;
            };

            modules = [
              inputs.nixos-apple-silicon.nixosModules.default
              ./modules/image-config.nix
            ];
          };
        in
        rec {
          installerPackage = pkgs.callPackage ./package.nix {
            inherit lib version;
            image = btrfsImage;
          };

          btrfsImage = imageConfig.config.system.build.btrfsImage // {
            passthru = { inherit imageConfig; };
          };

          ext4Image = imageConfig.config.system.build.ext4Image // {
            passthru = { inherit imageConfig; };
          };
        };

      apps = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          create-release = {
            type = "app";
            program = lib.getExe (pkgs.callPackage ./scripts/create-release.nix { inherit version; });
          };

          upload = {
            type = "app";
            program = lib.getExe (
              pkgs.callPackage ./scripts/upload.nix {
                inherit (self.packages.aarch64-linux) installerPackage;
              }
            );
          };
        }
      );

      devShells = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {
          default = boto3;

          boto3 = pkgs.mkShell {
            name = "boto3";

            packages = with pkgs; [
              (python3.withPackages (ps: [ ps.boto3 ]))
            ];

            shellHook = ''
              source .env || true
            '';
          };
        }
      );

      formatter = forEachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };

  nixConfig = {
    download-buffer-size = 134217728;
    extra-substituters = [ "https://nixos-asahi.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-asahi.cachix.org-1:CPH9jazpT/isOQvFhtAZ0Z18XNhAp29+LLVHr0b2qVk="
    ];
  };
}
