#!/usr/bin/env bash

DATE=`date "+%d%m%y"`
PKG="nixos-asahi-$DATE.zip"
# OLD_URL=$(jq -r < installer/installer_data.json ".[].[].package")
# URL=$(rclone link r2:nixos-asahi/$PKG)
BASEURL="https://pub-4b458b0cfaa1441eb321ecefef7d540e.r2.dev"
RESULT=$(readlink ./result)

upload() {
  if [[ -e $RESULT/package/$PKG ]]; then
    cp -a $RESULT/package/$PKG /tmp/
    chmod 644 /tmp/$PKG
  fi

  rclone copy /tmp/$PKG r2:nixos-asahi

  rm -rf /tmp/$PKG
}

update_installer_data() {
  jq -r < src/installer_data.json ".[].[].package = \"$BASEURL/$PKG\"" > installer/installer_data.json
}

main() {
  upload && update_installer_data
}

main && exit 0