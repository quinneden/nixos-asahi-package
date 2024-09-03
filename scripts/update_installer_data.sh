#! /usr/bin/env bash

BASE=$(basename "$0")/..
jq -r < "$BASE"/src/installer_data.json ".[].[].package = \"$BASEURL/$PKG\"" > "$BASE"/data/installer_data.json
