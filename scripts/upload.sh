#!/usr/bin/env bash

set -e

cd "$(dirname "$0")/.."

BASEDIR="$PWD"
BASEURL="https://cdn.qeden.systems"
DATE_TAG=$(cat "${RESULT}"/.release_date)
PKG="nixos-asahi-${DATE_TAG}.zip"
RESULT=$(realpath "${BASEDIR}"/result)
ROOTSIZE=$(cat "${RESULT}"/.root_part_size)

confirm() {
  while true; do
    read -r -n 1 -p "${1:-Continue?} [y/n]: " REPLY
    case $REPLY in
      [yY]) echo ; return 0 ;;
      [nN]) echo ; return 1 ;;
      *) printf " \033[31m %s \n\033[0m" "invalid input"
    esac
  done
}

upload() {
  if [[ -e $RESULT/package/$PKG ]]; then
    mkdir -p /tmp/nixos-asahi-package
    cp -a "$RESULT"/package/"$PKG" /tmp/nixos-asahi-package
    sudo chmod 644 /tmp/"$PKG"
  fi
  if (rclone copy --progress /tmp/"$PKG" r2:nixos-asahi || exit 1); then
    echo "Success! $PKG uploaded to bucket."
    [[ -e /tmp/"$PKG" ]] && rm -rf /tmp/"$PKG"
  fi
}

update_installer_data() {
  jq -r < "${BASEDIR}"/data/template/installer_data.json ".[].[].package = \"${BASEURL}/$PKG\" | .[].[].partitions.[1].size = \"${ROOTSIZE}B\" | .[].[].name = \"NixOS Asahi Package $DATE_TAG\"" > "${BASEDIR}"/data/installer_data.json
}

main() {
  confirm "Begin upload?" || exit 0
  # if upload; then (confirm "Update package version and push to git?" || exit 0); fi
  echo update_installer_data
  echo git add "${BASEDIR}"/data/installer_data.json
  echo git commit -m "release: NixOS Asahi-Installer Package ${DATE_TAG}"
  echo git tag "release-${DATE_TAG}"
  echo git push -u origin "release-${DATE_TAG}"
}

main || exit 1
