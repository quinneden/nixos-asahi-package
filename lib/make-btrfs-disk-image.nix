{
  lib,
  pkgs,
  # The NixOS configuration to be installed onto the disk image.
  config,

  # size of the ESP partition, in megabytes.
  bootSize ? 512,

  memSize ? 4096,

  # The size of the root partition, in megabytes.
  rootSize ? 5120,

  initConfig ? "${../nixos}",

  name ? "nixos-asahi-btrfs-image",

  includeChannel ? true,

  rootGPUID ? "3AD9C8C5-F96B-4648-9591-E23884A0D3D9",
  rootFSUID ? rootGPUID,
}:
let
  rootFilename = "nixos.img";

  channelSources =
    let
      nixpkgs = lib.cleanSource pkgs.path;
    in
    pkgs.runCommand "nixos-${config.system.nixos.version}" { } ''
      mkdir -p $out
      cp -prd ${nixpkgs.outPath} $out/nixos
      chmod -R u+w $out/nixos
      if [ ! -e $out/nixos/nixpkgs ]; then
        ln -s . $out/nixos/nixpkgs
      fi
      rm -rf $out/nixos/.git
      echo -n ${config.system.nixos.versionSuffix} > $out/nixos/.version-suffix
    '';

  closureInfo = pkgs.closureInfo {
    rootPaths = [ config.system.build.toplevel ] ++ (lib.optional includeChannel channelSources);
  };

  tools = lib.makeBinPath (
    with pkgs;
    [
      btrfs-progs
      config.system.build.nixos-install
      dosfstools
      e2fsprogs
      git
      gptfdisk
      nix
      nixos-enter
      parted
      util-linux
    ]
  );

  image =
    (pkgs.vmTools.override {
      rootModules = [
        "9p"
        "9pnet_virtio"
        "btrfs"
        "virtio_blk"
        "virtio_pci"
        "virtiofs"
      ];
      # kernel = pkgs.linuxPackages_latest.kernel;
    }).runInLinuxVM
      (
        pkgs.runCommand name
          {
            inherit memSize;
            QEMU_OPTS = "-drive file=$rootDiskImage,if=virtio,cache=unsafe,werror=report";
            preVM = ''
              mkdir $out

              rootDiskImage=nixos.raw
              ${pkgs.vmTools.qemu}/bin/qemu-img \
                create -f raw $rootDiskImage ${toString (bootSize + rootSize)}M
            '';

            postVM = ''
              mv $rootDiskImage $out/${rootFilename}
              rootDiskImage=$out/${rootFilename}

              printf '{ espSize = "%s"; rootSize = "%s"; }' \
                $(${pkgs.util-linux}/bin/partx "$rootDiskImage" -rgo SIZE -b --nr 1:2) \
              > "$out/partinfo.nix"
            '';
          }
          ''
            export PATH=${tools}:$PATH
            set -x

            round_to_nearest() {
              echo $(( ( $1 / $2 + 1) * $2 ))
            }

            bootSize=$(round_to_nearest $(numfmt --from=iec '${bootSize}') $mebibyte)
            bootSizeMiB=$(( bootSize / 1024 / 1024 ))MiB

            parted --script /dev/vda -- \
              mklabel gpt \
              mkpart ESP fat32 8MiB $bootSizeMiB \
              set 1 boot on \
              align-check optimal 1 \
              mkpart primary btrfs $bootSizeMiB 100% \
              align-check optimal 2 \
              print

            sgdisk \
              --disk-guid=97FD5997-D90B-4AA3-8D16-C1723AEA73C \
              --partition-guid=1:1C06F03B-704E-4657-B9CD-681A087A2FDC \
              --partition-guid=2:${rootGPUID} \
              /dev/vda

            sfdisk --dump /dev/vda

            mkfs.btrfs -L nixos -U ${rootFSUID} /dev/vda2

            mkdir /mnt /btrfs
            mount -t btrfs -o 'compress=zstd' /dev/vda2 /btrfs
            btrfs filesystem resize max /btrfs

            btrfs subvolume create /btrfs/@
            btrfs subvolume create /btrfs/@home
            btrfs subvolume create /btrfs/@nix

            umount -R /btrfs

            mount -t btrfs -o 'compress=zstd,subvol=@' /dev/vda2 /mnt

            mkdir -p /mnt/{boot,home,nix}

            mount -t btrfs -o 'compress=zstd,subvol=@home' /dev/vda2 /mnt/home
            mount -t btrfs -o 'compress=zstd,subvol=@nix,noatime' /dev/vda2 /mnt/nix

            mkfs.vfat -n ESP /dev/vda1
            mount /dev/vda1 /mnt/boot

            # Init a git repo at /etc/nixos and install a flake config.
            install -Dm644 -t /mnt/etc/nixos ${initConfig}/*
            pushd /mnt/etc/nixos >/dev/null || exit 1
            git init -b main
            git add .
            popd >/dev/null

            export NIX_STATE_DIR=$TMPDIR/state
            nix-store \
              --load-db < ${closureInfo}/registration \
              --option build-users-group ""

            cp ${closureInfo}/registration /mnt/nix-path-registration

            nixos-install \
              --max-jobs auto \
              --cores 0 \
              --root /mnt \
              --no-root-passwd \
              --system ${config.system.build.toplevel} \
              --substituters "" \
              --option build-users-group ""

            rm -rf /mnt/boot/EFI/nixos/.extra-files || true

            umount -R /mnt
          ''
      );
in
image
