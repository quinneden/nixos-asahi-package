# Don't run directly! Instead, use
# nix run .#create-release

# shellcheck disable=SC2154

# Check if we're running from the root of the repository
if [[ $(git rev-parse --show-toplevel) != "$PWD" ]]; then
  echo "This script must be run from the root of the repository" >&2
  exit 1
fi

# Check if the version matches the semver pattern (without suffixes)
semver_regex="^([0-9]+)\.([0-9]+)\.([0-9]+)$"
if [[ ! "$version" =~ $semver_regex ]]; then
  echo "Version must match the semver pattern (e.g., 1.0.0, 2.3.4)" >&2
  exit 1
fi

# Check if we're running on the main branch
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
git pull "git@github.com:quinneden/nixos-asahi-package" main
unpushed_commits=$(git log --format=oneline origin/main..main)
if [[ "$unpushed_commits" != "" ]]; then
  echo -e "\nThere are unpushed changes, exiting:\n$unpushed_commits" >&2
  exit 1
fi

# Update release.nix
sed -i 's/released = false/released = true/' version.nix

# Commit and tag the release
git commit -am "release: v$version"
git tag -a "v$version" -m "release: v$version"
git tag -d "latest" || true
git tag -a "latest" -m "release: v$version"

commit=$(git rev-parse HEAD)
date=$(date +%Y-%m-%d)

sed -i "s/$latestReleaseCommit/$commit/g" version.nix
sed -i "s/$latestReleaseDate/$date/g" version.nix
sed -i "s/$latestReleaseVersion/$version/g" version.nix
sed -i "s/$latestReleaseTag/v$version/g" version.nix
sed -i "s/released = true;/released = false;/g" version.nix

# Reset release.nix
git commit -am "chore: \`reset version.nix\`"

echo "Release was prepared successfully!"
read -rn1 -p "Push to remote? (Y/n): " input
if [[ $input != 'y' ]]; then
  echo "To push the release, run the following command:"
  echo
  echo "  git push origin main v$version && git push --force origin latest"
else
  git push origin main "v$version" && git push --force origin latest
fi
