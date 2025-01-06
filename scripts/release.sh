#!/usr/bin/env bash

version_tag="v$(nix eval --raw .#installerPackage.version)"

if ! git tag --list | grep "$version_tag"; then
  git tag "$version_tag"
  git push --tags "$version_tag"
fi
