#!/usr/bin/env bash

set -e

result=$(readlink ./result)
dateTag=$(cat $result/timestamp)

pkgZip="nixos-asahi-${dateTag}.zip"; export pkgZip
pkgData="nixos-asahi-${dateTag}.json"; export pkgData

trap 'rm -rf $TMPDIR' EXIT

cp $result/nixos-asahi-* $TMPDIR
chmod 644 $TMPDIR/nixos-asahi-*

echo "Uploading package..."
python3 scripts/main.py pkg

echo "Uploading installer data..."
python3 scripts/main.py data

json_files=($(python3 scripts/list_obj.py))

[[ -n ${json_files[@]} ]] || exit 0

mkdir -p $TMPDIR/data
cd $TMPDIR/data

for f in ${json_files[@]}; do
  curl -LO "https://cdn.qeden.systems/$f"
done

jq -s '{os_list: .}' ${json_files[@]#os/} > installer_data.json

cd -
python3 scripts/main.py data_joined