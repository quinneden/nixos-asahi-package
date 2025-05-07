# NixOS Asahi-Installer Package

A package that enables easy installation of NixOS onto bare metal Apple Silicon Macs using the [asahi-installer](https://asahilinux.org/)
and derivations from [nixos-apple-silicon](https://github.com/tpwrules/nixos-apple-silicon).

> [!NOTE]
> This project is a work in progress and code will change. Contributions and issues are appreciated.

## Installation

Using the installer script:

```bash
curl -sL -o install-nixos.sh "https://nixos-asahi.qeden.dev/install"
sh ./install-nixos.sh

# or if you're feeling reckless
sh <(curl -sL "https://nixos-asahi.qeden.dev/install")
```

This is a modified copy of the bootstrap script from the [asahi-installer](https://github.com/asahilinux/asahi-installer)
repository. Be sure to follow the instructions carefully, as it is possible a mistake could leave your system in an unbootable state.

## Building

> [!NOTE]
> An aarch64-linux machine is required to build the NixOS disk image.
> See the [darwin-builder section](https://nixos.org/manual/nixpkgs/stable/#sec-darwin-builder)
> of the nixpkgs manual for information on setting up a nix builder vm on MacOS.

```bash
nix build .#packages.aarch64-linux.installerPackage.btrfs # or .ext4
# builds the package derived from the disk image

nix build .#packages.aarch64-linux.image.btrfs # or .ext4
# builds just the disk image
```

## Credits

Credits go to:

- [tpwrules/nixos-apple-silicon](https://github.com/tpwrules/nixos-apple-silicon) for providing the derivations for all of the Asahi packages as well as the NixOS module that implements them.
- [Asahi Linux](https://github.com/asahilinux) for providing the necessary tools and infrastructure for enabling Linux on Apple Silicon.

## License

The Nix derivations, scripts, and documentation in this repository are licensed under the MIT license as
included in the LICENSE file.
