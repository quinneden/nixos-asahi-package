{
  pkgs,
  installerPackage,
  ...
}:

pkgs.writeShellApplication {
  name = "upload-to-cdn";

  runtimeInputs = with pkgs; [
    curl
    jq
    (python3.withPackages (ps: [ ps.boto3 ]))
  ];

  text = ''
    pkgData="installer_data-${installerPackage.version}.json"
    pkgZip="${installerPackage.name}.zip"; export pkgZip
    tmpDir=$(mktemp -d)

    trap 'rm -rf $tmpDir' EXIT

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --testing)
          envFile="''${2:-.env.testing}"
          shift "$#"
          ;;
        *)
          echo "Unknown argument: $1"
          exit 1
          ;;
      esac
    done

    envFile="''${envFile:-.env}"

    # shellcheck disable=SC1090
    source "$envFile"

    pushd "$tmpDir" > /dev/null || exit 1
    cp ${installerPackage}/{"$pkgZip","$pkgData"} ./.
    chmod -R +w ./.

    if ! curl -sf -o os_list.json "https://cdn.qeden.systems/data/installer_data.json"; then
      echo -n '{"os_list": []}' > os_list.json
    fi

    jq '.os_list += [input]' os_list.json "$pkgData" > installer_data.json

    echo "Uploading package and installer data to bucket..."
    python3 ${./upload.py} || exit 1
    echo "Done!"
    popd > /dev/null
  '';
}
