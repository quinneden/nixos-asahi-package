#!/usr/bin/env bash

set -e

cd "$(dirname "$0")/.."

BASEDIR="$PWD"
BASEURL="https://cdn.qeden.systems"
DATE=$(date -u "+%Y%d%m")
PKG="nixos-asahi-${DATE}.zip"
RESULT=$(realpath "${BASEDIR}"/result)
ROOTSIZE=$(cat "${RESULT}"/.tag_rootsize)
VERSION_TAG=$(cat "${BASEDIR}"/.version_tag)

if [[ -f $RESULT/package/$PKG ]]; then
  PKG="nixos-asahi-${DATE}.zip"
elif [[ -e $RESULT ]]; then
  PKG=$(basename $(stat -c "%a %N" "$RESULT"/package/nixos-asahi-*.zip | sort -nr | head -n 1 | awk -F' ' '{print $2}') | tr -d \')
fi

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
  if [[ -e $RESULT/package/$PKG ]]; then
    mkdir -p /tmp/nixos-asahi-package
    cp -a "$RESULT"/package/"$PKG" /tmp/nixos-asahi-package
    sudo chmod 644 /tmp/"$PKG"
  fi
  rclone copy --progress /tmp/"$PKG" r2:nixos-asahi || exit 1
  [[ $? == 0 ]] && echo "Success! $PKG uploaded to bucket."
  [[ -e /tmp/"$PKG" ]] && rm -rf /tmp/"$PKG"
}

update_installer_data() {
  jq -r < "${BASEDIR}"/src/installer_data.json ".[].[].package = \"${BASEURL}/$PKG\" | .[].[].partitions.[1].size = \"${ROOTSIZE}B\"" > "${BASEDIR}"/data/installer_data.json
}

increment_version() {
  read -r VERSION < <(awk -vFS=. -vOFS=. '{$NF++;print}' <<<"${VERSION_TAG}")
  cat <<<"${VERSION}" > "${BASEDIR}"/.version_tag
}

main() {
  confirm "Begin upload?" || exit 0
  upload
  [[ $? == 0 ]] && confirm "Update package version and push to git?" || exit 0
  increment_version
  update_installer_data
  git add "${BASEDIR}"/data/installer_data.json "${BASEDIR}"/.version_tag
  git commit -m "update package: ${VERSION}"
  git tag "${VERSION}"
  git push -u origin "${VERSION}"
}

main && exit
