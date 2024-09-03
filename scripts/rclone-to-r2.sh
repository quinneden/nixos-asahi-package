#!/usr/bin/env bash

DATE=$(date "+%d%m%y")
PKG="nixos-asahi-$DATE.zip"
BASEURL="https://cdn.qeden.systems"
BASEDIR=$(dirname "$0")/..
RESULT=$(realpath "$BASEDIR"/result)
ROOTSIZE=$(cat $BASEDIR/result/.tag_rootimg_size)

if [[ -e $RESULT/nixos-asahi-$DATE.zip ]]; then
  PKG="nixos-asahi-$DATE.zip"
else
  PKG=$(basename $(stat -f "%a %N" result/package/nixos-asahi-* | sort -nr | head -n 1 | awk -F' ' '{print $2}'))
fi


upload() {
  if [[ -e $RESULT/package/$PKG ]]; then
    cp -a "$RESULT"/package/"$PKG" /tmp/
    chmod 644 /tmp/"$PKG"
  fi

  rclone copy --progress /tmp/"$PKG" r2:nixos-asahi

  rm -rf /tmp/"$PKG"
}

update_installer_data() {
  jq -r < "$BASEDIR"/src/installer_data.json ".[].[].package = \"$PKG\" | .[].[].partitions.[1].size = \"${ROOTSIZE}B\"" > "$BASEDIR"/data/installer_data.json
}

main() {
  # upload
  update_installer_data
}

main && exit 0
