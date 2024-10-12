#!/usr/bin/env bash

set -e

cd "$(dirname "$0")/.."

RESULT=$(readlink ./result)
BASEURL="https://cdn.qeden.systems"
DATE_TAG=$(cat "${RESULT}"/.release_date)
PKG="nixos-asahi-${DATE_TAG}.zip"
ROOTSIZE=$(cat "${RESULT}"/.root_part_size)
TMP=$(mktemp -d /tmp/nixos-asahi-package.XXXXXXXXXX)

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
    cp -a "${RESULT}"/"${PKG}" "${TMP}"
    chmod 644 "${TMP}/${PKG}"
  else
    echo 'error: ${PKG}: file not found'; exit 1
  fi
  if (python3 scripts/upload_to_r2.py || exit 1); then
    echo "Success! ${PKG} uploaded to bucket."
    rm -rf "${TMP}"
  fi
}

update_installer_data() {
  jq -r < ./data/template/installer_data.json ".[].[].package = \"${BASEURL}/${PKG}\" | .[].[].partitions.[1].size = \"${ROOTSIZE}B\" | .[].[].name = \"NixOS Asahi Package ${DATE_TAG}\"" > ./data/installer_data.json
}

main() {
  if [[ -d "${TMP}"/venv ]]; then
    source "${TMP}"/venv/bin/activate
  else
    python3 -m venv "${TMP}"/venv && source "${TMP}"/venv/bin/activate
    python3 -m pip install boto3 tqdm colorthon
  fi

  if [[ ! -e scripts/env_vars.sh ]]; then
    echo 'error: env vars file not found'; exit 1
  else
    source scripts/env_vars.sh
  fi

  confirm "Begin upload?" || exit 0

  if (upload || exit 1); then
    confirm "Update package version and push to git?" || exit 0
  else
    exit 1
  fi

  # update_installer_data || exit 1

  # if git add ./data/installer_data.json; then
  #   git commit -m "release: NixOS Asahi-Installer Package ${DATE_TAG}"
  #   git tag "release-${DATE_TAG}"
  #   git push -u origin "release-${DATE_TAG}"
  # fi
}

main || exit 1
