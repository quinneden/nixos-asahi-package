#!/usr/bin/env bash

set -xeu -o pipefail

tmpDir=$(mktemp -dp /tmp -t upload-package)

result=$(readlink ./result)
dateTag=$(cat "$result"/timestamp)

pkgZip="nixos-asahi-$dateTag.zip"; export pkgZip
pkgData="nixos-asahi-$dateTag.json"; export pkgData

trap 'rm -rf $tmpDir' EXIT

cp "$result"/{"$pkgZip","$pkgData"} "$tmpDir"
chmod 644 "$tmpDir"/*

echo "Uploading package..."
python3 scripts/main.py pkg

echo "Uploading installer data..."
python3 scripts/main.py data

json_files=($(python3 scripts/list_obj.py))

[[ -n ${json_files[@]} ]] || exit 0

mkdir -p "$tmpDir"/data
cd "$tmpDir"/data

for f in "${json_files[@]}"; do
  curl -LO "https://cdn.qeden.systems/$f"
done

jq -s '{os_list: .}' "${json_files[@]#os/}" > installer_data.json

cd -
python3 scripts/main.py data_joined