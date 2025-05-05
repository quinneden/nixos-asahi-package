{
  inputs,
  lib,
  nixpkgs,
  version,
}:
let
  pkgs = import nixpkgs { system = "aarch64-linux"; };

  mkNixosConfig =
    fsType:
    lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        modulesPath = nixpkgs + "/nixos/modules";
        inherit fsType inputs version;
      };
      modules = [ ../modules/image-config.nix ];
    };

  mkInstallerPkg = image: pkgs.callPackage ../package.nix { inherit image lib version; };
in
{
  buildVariants =
    variants:
    builtins.listToAttrs (
      map (variant: {
        name = variant;
        value =
          let
            inherit (mkNixosConfig variant) config;
          in
          rec {
            image = config.system.build.asahi-image // {
              passthru = { inherit config; };
            };
            installerPackage = mkInstallerPkg image;
          };
      }) variants
    );
}
