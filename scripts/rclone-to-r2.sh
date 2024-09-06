#!/usr/bin/env bash

set -e

DATE=$(date -u "+%d%m%y")
PKG="nixos-asahi-$DATE.zip"
BASEURL="https://cdn.qeden.systems"
BASEDIR=$(dirname "$0")/..
RESULT=$(realpath "$BASEDIR"/result)
ROOTSIZE=$(cat $BASEDIR/result/.tag_rootimg_size)

if [[ -e $RESULT/nixos-asahi-$DATE.zip ]]; then
  PKG="nixos-asahi-$DATE.zip"
else
  PKG=$(basename $(stat -f "%a %N" "$RESULT"/package/nixos-asahi-*.zip | sort -nr | head -n 1 | awk -F' ' '{print $2}'))
fi


upload() {
  if [[ -e $RESULT/package/$PKG ]]; then
    cp -a "$RESULT"/package/"$PKG" /tmp/
    sudo chmod 644 /tmp/"$PKG"
  fi

  rclone copy --progress /tmp/"$PKG" r2:nixos-asahi && echo "Success! $PKG uploaded to bucket."

  rm -rf /tmp/"$PKG"
}

update_installer_data() {
  jq -r < "$BASEDIR"/src/installer_data.json ".[].[].package = \"$BASEURL/$PKG\" | .[].[].partitions.[1].size = \"${ROOTSIZE}B\"" > "$BASEDIR"/data/installer_data.json
}

main() {
  upload
  update_installer_data
  git add "$BASEDIR"/data/installer_data.json &>/dev/null || true
  git commit -m "Update data/installer_data.json" &>/dev/null || true
  printf "\nPush to git?"
  read
  git push
}

main && exit
