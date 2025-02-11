#!/usr/bin/env bash

version_nix=$(nix build --no-link --print-out-paths -f ./scripts/bump-version.nix)
version_new=$(nix eval --raw --impure --expr 'let inherit (import ./version.nix) version; in version')

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

cat "$version_nix" > ./version.nix

git commit -am "release: v$version_new"
git tag -a "v$version_new" -m "release: v$version_new"
git tag -d "latest"
git tag -a "latest" -m "release: v$version_new"

echo "To push the release, run the following command:"
echo "  git push origin main v$version_new && git push --force origin latest"
