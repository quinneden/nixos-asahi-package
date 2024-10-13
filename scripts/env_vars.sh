#!/usr/bin/env bash

cd "$(dirname "$0")/.."

RESULT=$(readlink ./result)
BASEURL="https://cdn.qeden.systems"
DATE_TAG=$(cat "${RESULT}"/.release_date)
PKG="nixos-asahi-${DATE_TAG}.zip"
ROOTSIZE=$(cat "${RESULT}"/.root_part_size)
TMP=$(mktemp -d /tmp/nixos-asahi-package.XXXXXXXXXX)

export RESULT BASEURL DATE_TAG PKG ROOTSIZE TMP

test -e ./scripts/secrets.sh && source ./scripts/secrets.sh
