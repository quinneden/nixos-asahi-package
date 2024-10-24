#!/usr/bin/env bash

set -e

cd "$(dirname "$0")/.."

RESULT=$(realpath ./result)
BASEURL="https://cdn.qeden.systems"
DATE_TAG=$(cat "${RESULT}"/.release_date)
PKG="nixos-asahi-${DATE_TAG}.zip"
ROOTSIZE=$(cat "${RESULT}"/.root_part_size)
TMP=$(mktemp -d /tmp/nixos-asahi-package.XXXXXXXXXX)

export RESULT BASEURL DATE_TAG PKG ROOTSIZE TMP

[[ -f ./scripts/secrets.sh ]] && source ./scripts/secrets.sh

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

upload() {
  if (curl --progress-bar \
    --request PUT \
    --url "${PRESIGNED_URL}" \
    --header "Content-Type: application/zip" \
    --header "accept: application/json" \
    -T "${TMP}/${PKG}" | cat)
  then
    echo "Success! ${PKG} uploaded to bucket."
  else
    exit 1
  fi
}

if [[ -e ${RESULT}/${PKG} ]]; then
  cp -a "${RESULT}"/"${PKG}" "${TMP}"
  chmod 644 "${TMP}/${PKG}"
else
  echo "error: ${PKG}: file not found"; exit 1
fi

if [[ ! -d ./scripts/.venv ]]; then
  python3 -m venv ./scripts/.venv && source ./scripts/.venv/bin/activate
  python3 -m pip install boto3
else
  source ./scripts/.venv/bin/activate
fi

read -r PRESIGNED_URL < <(python3 scripts/presign.py 2>/dev/null)

echo
  confirm "Begin upload?" || exit 0
echo

if upload; then
  confirm "Update installer data and push to git?" || exit 0

  jq -r < ./data/template/installer_data.json \
    ".[].[].package = \"${BASEURL}/${PKG}\" | .[].[].partitions.[1].size = \"${ROOTSIZE}B\" | .[].[].name = \"NixOS Asahi Package ${DATE_TAG}\"" \
    > ./data/installer_data.json

    git add ./data/installer_data.json
    git commit -m "release: NixOS Asahi-Installer Package ${DATE_TAG}"
    git tag "release-${DATE_TAG}"
    git push -u origin "release-${DATE_TAG}"
fi

unset RESULT DATE_TAG PKG TMP

rm -rf "${TMP}"
