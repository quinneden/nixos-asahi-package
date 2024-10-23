#!/bin/sh

curl -sL "https://github.com/AsahiLinux/asahi-installer/raw/main/scripts/bootstrap-dev.sh" \
  | sed 's/INSTALLER_DATA=.*$/INSTALLER_DATA=https:\/\/github.com\/quinneden\/nixos-asahi-package\/raw\/main\/data\/installer_data.json/' \
  | sed 's/REPO_BASE=.*$/REPO_BASE=https:\/\/qeden.systems/' \
  | sh
