#! /usr/bin/env bash

set -e

cd "$(dirname "$0")/.."

RESULT=$(readlink ./result)
BASEURL="https://cdn.qeden.systems"
DATE_TAG=$(cat "${RESULT}"/.release_date)
PKG="nixos-asahi-"${DATE_TAG}".zip"
ROOTSIZE=$(cat "${RESULT}"/result/.tag_rootsize)

update_installer_data() {
  jq -r < ./data/template/installer_data.json ".[].[].package = \"$BASEURL/$PKG\" | .[].[].partitions.[1].size = \"${ROOTSIZE}B\"" > ./data/installer_data.json
}

update_installer_data && exit
