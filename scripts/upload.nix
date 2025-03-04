{
  pkgs,
  installerPackage,
  ...
}:

let
  uploadPy = pkgs.writeScript "upload.py" ''
    import boto3
    import os
    from botocore.config import Config

    pkg_zip = "${installerPackage.name}.zip"
    pkg_data = "installer_data.json"

    obj_list = [pkg_zip, pkg_data]

    s3 = boto3.client(
        "s3",
        region_name="auto",
        config=Config(signature_version="s3v4"),
        aws_access_key_id=os.getenv("ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("SECRET_ACCESS_KEY"),
        endpoint_url=os.getenv("ENDPOINT_URL"),
    )

    transfer_config = boto3.s3.transfer.TransferConfig(
        multipart_threshold=8 * 1024 * 1024,
        multipart_chunksize=8 * 1024 * 1024,
    )

    def upload_to_r2(file):
        content_type = (
            "text/plain" if file.endswith(".json") else "application/octet-stream"
        )
        prefix = "data" if file.endswith(".json") else "os"
        with open(file, "rb") as fb:
            s3.upload_fileobj(
                fb,
                ExtraArgs={"ContentType": content_type},
                Bucket=os.getenv("BUCKET_NAME"),
                Key=os.path.join(prefix, file),
                Config=transfer_config,
            )

    for obj in obj_list:
        upload_to_r2(obj)
  '';
in

pkgs.writeShellApplication {
  name = "upload-to-cdn";

  runtimeInputs = with pkgs; [
    curl
    jq
    (python3.withPackages (ps: [ ps.boto3 ]))
  ];

  text = ''
    pkgData="installer_data-${installerPackage.version}.json"
    pkgZip="${installerPackage.name}.zip"
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
    python3 ${uploadPy} || exit 1
    echo "Done!"
    popd > /dev/null
  '';
}
