#!/usr/bin/env bash

BASEDIR="$(dirname "$0")/.."
VERSION=$(cat "${BASEDIR}"/version.tag)

increment_version() {
  read -r VERSION < <(awk -vFS=. -vOFS=. '{$NF++;print}' <<<"${VERSION}")
  echo "${VERSION}"
}

increment_version > "${BASEDIR}/version.tag"
