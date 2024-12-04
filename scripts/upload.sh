#!/usr/bin/env bash

set -e

cd "$(dirname "$0")/.."

RESULT=$(realpath ./result)
BASEURL="https://cdn.qeden.systems"
DATE_TAG=$(cat "${RESULT}"/.release_date)
INSTALLER_DATA="data/installer_data.json"
PKG="nixos-asahi-${DATE_TAG}.zip"
ROOTSIZE=$(cat "${RESULT}"/.root_part_size)
TMP=$(mktemp -d /tmp/nixos-asahi-package.XXXXXXXXXX)

trap 'rm -rf ${TMP}' EXIT

export RESULT BASEURL DATE_TAG INSTALLER_DATA PKG ROOTSIZE TMP

source ./scripts/secrets.sh

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

# upload_pkg() {
#   if (curl --progress-bar \
#     --request PUT \
#     --url "${PRESIGNED_PKG_URL}" \
#     --header "Content-Type: application/zip" \
#     --header "accept: application/json" \
#     -T "${TMP}/${PKG}" | cat)
#   then
#     echo "uploaded ${PKG}"
#   else
#     exit 1
#   fi
# }

# upload_data() {
#   if (curl --progress-bar \
#     --request PUT \
#     --url "${PRESIGNED_DATA_URL}" \
#     --header "Content-Type: application/json" \
#     --header "accept: application/json" \
#     -T "${INSTALLER_DATA}" | cat)
#   then
#     echo "uploaded installer_data.json"
#   else
#     exit 1
#   fi
# }

upload_pkg() {
  rclone copy --progress "$TMP/$PKG" r2:nixos-asahi/os
}

upload_data() {
  rclone copy --progress "$INSTALLER_DATA" r2:nixos-asahi/data
}

if [[ -e ${RESULT}/${PKG} ]]; then
  cp -a "${RESULT}/${PKG}" "${TMP}"
  chmod 644 "${TMP}/${PKG}"
else
  echo "error: ${PKG}: file not found"; exit 1
fi

# if [[ ! -d ./scripts/.venv ]]; then
#   python3 -m venv ./scripts/.venv && source ./scripts/.venv/bin/activate
#   python3 -m pip install boto3
# else
#   source ./scripts/.venv/bin/activate
# fi

# read -r PRESIGNED_PKG_URL < <(python3 scripts/presign.py pkg 2>/dev/null)
# read -r PRESIGNED_DATA_URL < <(python3 scripts/presign.py data 2>/dev/null)

echo
  confirm "Begin upload?" || exit 0
echo

if upload_pkg; then
  confirm "Update installer data?" || exit 0

  jq -r < ./data/template/installer_data.json \
    ".[].[].package = \"${BASEURL}/os/${PKG}\" | .[].[].partitions.[1].size = \"${ROOTSIZE}B\" | .[].[].name = \"NixOS Asahi Package ${DATE_TAG}\"" \
    > "$INSTALLER_DATA"

  upload_data
fi

unset RESULT BASEURL DATE_TAG INSTALLER_DATA PKG ROOTSIZE TMP
