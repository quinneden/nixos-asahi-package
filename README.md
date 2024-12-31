# NixOS Asahi-Installer Package

A Nix flake that defines a nixos disk image compatible with apple silicon hardware and
can package the image into a zipfile that can be used as a payload for the [asahi-installer](https://github.com/asahilinux/asahi-installer).

## Flake outputs

Build raw-efi NixOS disk image.
```bash
nix build .#packages.aarch64-linux.nixosImage
```

Build disk image and package for asahi-installer.
```bash
nix build .#packages.aarch64-linux.installerPackage
```

## Credits

This project utilizes modules/packages from [tpwrules/nixos-apple-silicon](https://github.com/tpwrules/nixos-apple-silicon),
which in turn is based on the incredible work done by the [Asahi Linux](https://github.com/asahilinux) team.

## License

[MIT](https://choosealicense.com/licenses/mit/)
