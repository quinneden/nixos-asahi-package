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
      nixos-apple-silicon,
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
          create-release = pkgs.callPackage ./scripts/create-release.nix { };

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
            program = import ./app.nix { inherit pkgs self; };
          };
        }
      );

      devShells = forEachSystem (
        { pkgs }:
        rec {
          default = boto3;

          boto3 = pkgs.mkShell {
            name = "boto3";

            packages = with pkgs; [
              (python3.withPackages (ps: [
                ps.boto3
                ps.python-dotenv
              ]))
            ];

            shellHook = ''
              source .env || true
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
