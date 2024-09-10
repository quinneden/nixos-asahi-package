#!/usr/bin/env bash

BASEDIR="$(dirname "$0")/.."
VERSION_TAG="$(cat "${BASEDIR}"/.version_tag)"

increment_version() {
  read -r VERSION < <(awk -vFS=. -vOFS=. '{$NF++;print}' <<<"${VERSION_TAG}")
  cat <<<"${VERSION}" > "${BASEDIR}"/.version_tag
}

increment_version > "${BASEDIR}/.version_tag"; exit
