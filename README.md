# NixOS Asahi-Installer Package

A nix flake containing package expressions for a NixOS disk image utiziling NixOS modules from [nixos-apple-silicon](https://github.com/tpwrules/nixos-apple-silicon) to enable compatibility with Apple Silicon hardware, and a zipfile of the disk image which is intended to be used as a package payload with the [asahi-installer](https://github.com/asahilinux/asahi-installer), so that the user can bootstrap a NixOS install onto an Apple Silicon mac without the use of live installation media. 

#### CAUTION: This project is a work in progress. Code is subject to change, packages probably are not stable enough for use on non-test machines (yet). Contributions and issues are appreciated.

## Install using prebuilt image

Curl and run the bootstrap installer script from this repository:
```shell
curl -sL -o install.sh https://qeden.systems/install && chmod +x install.sh && ./install.sh

# or

curl -sL https://qeden.systems/install | sh
```

This is a modified copy of the bootstrap script from the [asahi-installer](https://github.com/asahilinux/asahi-installer) repository. Be sure to follow the instructions carefully, as it is possible a mistake could leave your system in an unbootable state.

## Building
###### NOTE: An aarch64-linux machine is required to build the NixOS disk image. See the [darwin-builder section](https://nixos.org/manual/nixpkgs/stable/#sec-darwin-builder) of the nixpkgs manual for information on building aarch64-linux packages on MacOS.

Building `installerPackage` will build the image and output the zipfile for the installer. The process involves extracting the efi and root partition images from from the whole disk image, extracting the EFI image to a directory, then zipping the root disk image and esp directory into one zipfile.
```shell
nix build --show-trace .#installerPackage
```

Building `.#nixosImage` will output only the disk image and forego repackaging into the zipfile.

## Credits

- [tpwrules/nixos-apple-silicon](https://github.com/tpwrules/nixos-apple-silicon)
- [Asahi Linux](https://github.com/asahilinux)

The Nix derivations and documentation in this repository are licensed under the MIT license as included in the LICENSE file. Patches included in this repository, and the files that Nix builds, are covered by separate licenses.
