#!/usr/bin/env bash

set -e

cd "$(dirname "$0")/.."

RESULT=${RESULT:-"$(realpath ./result)"}
BASEURL="https://cdn.qeden.systems"
DATE_TAG=${DATE_TAG:-"$(cat "${RESULT}"/timestamp)"}
PKG="nixos-asahi-${DATE_TAG}.zip"
ROOTSIZE=${ROOTSIZE:-"$(cat "${RESULT}"/root_part_size)"}
TMP=$(mktemp -d /tmp/nixos-asahi-package.XXXXXXXXXX)

trap 'rm -rf ${TMP}' EXIT

export RESULT BASEURL DATE_TAG PKG ROOTSIZE TMP

source scripts/secrets.sh

confirm() {
  if ${CONFIRM:-true}; then
    while true; do
      read -r -n 1 -p "$1 [y/n]: " REPLY
      case $REPLY in
        [yY]) echo ; return 0 ;;
        [nN]) echo ; return 1 ;;
        *) echo ;;
      esac
    done
  fi
}

if [[ -e ${RESULT}/${PKG} ]]; then
  cp -a "${RESULT}/${PKG}" "${TMP}"
  chmod 644 "${TMP}/${PKG}"
else
  echo "error: ${PKG}: file not found"; exit 1
fi

echo
  confirm "Begin upload?" || exit 0
echo

python3 scripts/main.py pkg

confirm "Update installer data?" || exit 0

cp data/installer_data.json "$TMP"/old_installer_data.json

if [[ $(jq -r '.os_list | last | .package' data/installer_data.json) != "$BASEURL/os/$PKG" ]]; then
  jq -r < ./data/template/installer_data.json \
    ".[].[].package = \"${BASEURL}/os/${PKG}\" | .[].[].partitions.[1].size = \"${ROOTSIZE}B\" | .[].[].name = \"NixOS Asahi Package ${DATE_TAG}\"" \
    > "$TMP/new_installer_data.json"

  jq '.os_list += (input | .os_list)' "$TMP"/old_installer_data.json "$TMP"/new_installer_data.json > data/installer_data.json
fi

python3 scripts/main.py data

unset RESULT BASEURL DATE_TAG PKG ROOTSIZE TMP
