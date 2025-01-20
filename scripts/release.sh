#!/usr/bin/env bash

version="v$(nix eval --raw .#installerPackage.version)"

if [[ ! -f "flake.nix" ]]; then
  echo "This script must be run from the root of the repository" >&2
  exit 1
fi

if [[ "$(git symbolic-ref --short HEAD)" != "main" ]]; then
  echo "must be on main branch" >&2
  exit 1
fi

uncommited_changes=$(git diff --compact-summary)
if [[ -n "$uncommited_changes" ]]; then
  echo -e "There are uncommited changes, exiting:\n${uncommited_changes}" >&2
  exit 1
fi

if (git tag --list | grep "$version"); then
  echo "version already exists" >&2
  exit 1
fi

git commit -am "release: v$version"
git tag -a "v$version" -m "release: v$version"
git tag -d "latest"
git tag -a "latest" -m "release: v$version"
