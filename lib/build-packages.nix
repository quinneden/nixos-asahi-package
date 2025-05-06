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
  mkPackageVariants =
    variants:
    let
      # Create configurations for each variant
      variantConfigs = builtins.listToAttrs (
        map (variant: {
          name = variant;
          value = (mkNixosConfig variant).config;
        }) variants
      );

      # Build the image for each variant
      imageVariants = builtins.mapAttrs (
        variant: config:
        config.system.build.asahi-image
        // {
          passthru = { inherit config; };
        }
      ) variantConfigs;

      # Build the installer package for each variant
      installerPackagesVariants = builtins.mapAttrs (variant: image: mkInstallerPkg image) imageVariants;
    in
    {
      image = imageVariants;
      installerPackage = installerPackagesVariants;
    };
}
