# Don't run directly! Instead, use
# nix run .#create-release

# shellcheck disable=SC2154

# Check if we're running from the root of the repository
if [[ ! -f "flake.nix" || ! -f "version.nix" ]]; then
  echo "This script must be run from the root of the repository" >&2
  exit 1
fi

# Check if the version matches the semver pattern (without suffixes)
semver_regex="^([0-9]+)\.([0-9]+)\.([0-9]+)$"
if [[ ! "$cur_version" =~ $semver_regex ]]; then
  echo "Version must match the semver pattern (e.g., 1.0.0, 2.3.4)" >&2
  exit 1
fi

if [[ "$(git symbolic-ref --short HEAD)" != "main" ]]; then
  echo "must be on main branch" >&2
  exit 1
fi

# Ensure there are no uncommitted or unpushed changes
uncommited_changes=$(git diff --compact-summary)
if [[ -n "$uncommited_changes" ]]; then
  echo -e "There are uncommited changes, exiting:\n${uncommited_changes}" >&2
  exit 1
fi
git pull git@github.com:quinneden/nixos-asahi-package main
unpushed_commits=$(git log --format=oneline origin/main..main)
if [[ "$unpushed_commits" != "" ]]; then
  echo -e "\nThere are unpushed changes, exiting:\n$unpushed_commits" >&2
  exit 1
fi

# Update the version file
echo -e "{\n  version = \"$cur_version\";\n  released = true;\n}" > version.nix

# Commit and tag the release
git commit -am "release: v$cur_version"
git tag -a "v$cur_version" -m "release: v$cur_version"
git tag -d "latest" || true
git tag -a "latest" -m "release: v$cur_version"

echo -e "{\n  version = \"$new_version\";\n  released = false;\n}" > version.nix
git commit -am "release: reset released flag"

echo "Release was prepared successfully!"
echo "To push the release, run the following command:"
echo
echo "  git push origin main v$cur_version && git push --force origin latest"
