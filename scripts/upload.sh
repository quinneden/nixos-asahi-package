#!/usr/bin/env bash

set -e

cd "$(dirname "$0")/.."

RESULT=$(readlink ./result)
BASEURL="https://cdn.qeden.systems"
DATE_TAG=$(cat "${RESULT}"/.release_date)
PKG="nixos-asahi-${DATE_TAG}.zip"
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
  if [[ -e ${RESULT}/${PKG} ]]; then
    mkdir -p /tmp/nixos-asahi-package
    cp -a "${RESULT}"/"${PKG}" /tmp/nixos-asahi-package
    chmod 644 /tmp/nixos-asahi-package/"${PKG}"
  fi
  if (rclone copy --progress /tmp/nixos-asahi-package/"${PKG}" r2:nixos-asahi || exit 1); then
    echo "Success! ${PKG} uploaded to bucket."
    [[ -e /tmp/nixos-asahi-package ]] && rm -rf /tmp/nixos-asahi-package
  fi
}

update_installer_data() {
  jq -r < ./data/template/installer_data.json ".[].[].package = \"${BASEURL}/${PKG}\" | .[].[].partitions.[1].size = \"${ROOTSIZE}B\" | .[].[].name = \"NixOS Asahi Package ${DATE_TAG}\"" > ./data/installer_data.json || exit 1
}

main() {
  confirm "Begin upload?" || exit 0
  if (upload || exit 1); then
    confirm "Update package version and push to git?" || exit 0
  else
    exit 1
  fi
  update_installer_data
  if git add ./data/installer_data.json; then
    git commit -m "release: NixOS Asahi-Installer Package ${DATE_TAG}"
    git tag "release-${DATE_TAG}"
    git push -u origin "release-${DATE_TAG}"
  fi
}

main || exit 1
