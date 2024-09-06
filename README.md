# NixOS Asahi-Installer Package

A Nix flake that defines a nixos disk image compatible with apple silicon hardware and
can package the image into a zipfile that can be used as a payload for the [asahi-installer](https://github.com/asahilinux/asahi-installer).

## Flake outputs

Build raw-efi NixOS disk image.
```bash
nix build .#packages.aarch64-linux.asahiImage
```

Build disk image and package for asahi-installer.
```bash
nix build .#packages.aarch64-linux.asahiPackage
```

## Credit

This project utilizes modules/packages from [tpwrules/nixos-apple-silicon](https://github.com/tpwrules/nixos-apple-silicon),
which in turn is based on the incredible work done by the [Asahi Linux](https://github.com/asahilinux) team.

The disk image configuration is based on [nixos-generators](https://github.com/nix-community/nixos-generators).

## License

[MIT](https://choosealicense.com/licenses/mit/)
