# NixOS Asahi-Installer Package

A nix flake containing package expressions for a NixOS disk image utiziling NixOS modules from [nixos-apple-silicon](https://github.com/tpwrules/nixos-apple-silicon) to enable compatibility with Apple Silicon hardware, and a zipfile of the disk image which is intended to be used as a package payload with the [asahi-installer](https://github.com/asahilinux/asahi-installer), so that the user can bootstrap a NixOS install onto an Apple Silicon mac without the use of live installation media. 

##### CAUTION: This project is a work in progress. Code is subject to change not necessarily stable. PR's and contributions are welcome!

## Install using prebuilt image
NOTE: Currently, any package available has been built locally on my Mac mini M4. They're mostly for testing as I work on a hosted installation process so use with caution. I plan to create CI workflow to automate building the package and uploading to cloudflare.

Clone the repository and run `install.sh` in a terminal or use the one-liner:
```shell
curl -sL https://qeden.systems/install | sh
```

The script is a modified copy of `bootstrap-prod.sh` from the [asahi-installer](https://github.com/asahilinux/asahi-installer) repo. Be sure to follow the instructions carefully, failure to do so could potentially leave your system in an unbootable state.

## Building
##### NOTE: An aarch64-linux machine is required to build the NixOS disk image. See the [darwin-builder section](https://nixos.org/manual/nixpkgs/stable/#sec-darwin-builder) of the nixpkgs manual for information on building aarch64-linux packages on MacOS.

Building `installerPackage` will build the image and output the zipfile for the installer. The process involves extracting the efi and root partition images from from the whole disk image, extracting the EFI image to a directory, then zipping the root disk image and esp directory into one zipfile.
```shell
nix build --show-trace .#installerPackage
```

Building `.#nixosImage` will output only the disk image and forego repackaging into the zipfile.

## Credits

- [tpwrules/nixos-apple-silicon](https://github.com/tpwrules/nixos-apple-silicon)
- [Asahi Linux](https://github.com/asahilinux)

The Nix derivations and documentation in this repository are licensed under the MIT license as included in the LICENSE file. Patches included in this repository, and the files that Nix builds, are covered by separate licenses.
