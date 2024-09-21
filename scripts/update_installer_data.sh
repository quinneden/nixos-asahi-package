#! /usr/bin/env bash

set -e

DATE=$(date -u "+%Y-%m-%d")
PKG="nixos-asahi-$DATE.zip"
BASEURL="https://cdn.qeden.systems"
BASEDIR=$(dirname "$0")/..
ROOTSIZE=$(cat $BASEDIR/result/.tag_rootsize)

update_installer_data() {
  jq -r < "$BASEDIR"/data/template/installer_data.json ".[].[].package = \"$BASEURL/$PKG\" | .[].[].partitions.[1].size = \"${ROOTSIZE}B\"" > "$BASEDIR"/data/installer_data.json
}

update_installer_data && exit
