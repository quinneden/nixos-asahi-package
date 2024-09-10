#!/usr/bin/env bash

BASEDIR="$(dirname "$0")/.."
BASEURL="https://cdn.qeden.systems"
DATE=$(date -u "+%Y%d%m")
PKG="nixos-asahi-${DATE}.zip"
RESULT=$(realpath "${BASEDIR}"/result)
ROOTSIZE=$(cat ${BASEDIR}/result/.tag_rootsize)
VERSION_TAG=$(cat "${BASEDIR}"/.version_tag)

if [[ -e $RESULT/nixos-asahi-${DATE}.zip ]]; then
  PKG="nixos-asahi-${DATE}.zip"
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
  jq -r < "${BASEDIR}"/src/installer_data.json ".[].[].package = \"${BASEURL}/$PKG\" | .[].[].partitions.[1].size = \"${ROOTSIZE}B\"" > "${BASEDIR}"/data/installer_data.json
}

increment_version() {
  read -r VERSION < <(awk -vFS=. -vOFS=. '{$NF++;print}' <<<"${VERSION_TAG}")
  cat <<<"${VERSION}" > "${BASEDIR}"/.version_tag
}

main() {
  upload
  printf "\nUpdate package version and push to git? (press enter x2)"
  read -r
  read -r
  increment_version
  update_installer_data
  git add "${BASEDIR}"/data/installer_data.json "${BASEDIR}"/.version_tag
  git commit -m "update package: ${VERSION}"
  git tag "${VERSION}"
  git push
}

main && exit
