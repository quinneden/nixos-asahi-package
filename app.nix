{
  pkgs,
  secrets,
  self,
  ...
}:
let
  inherit (pkgs) lib writeShellApplication writeScript;
  inherit (self.packages.${pkgs.system}) installerPackage;
  inherit (installerPackage) version;
  inherit (secrets)
    accessKeyId
    accountId
    bucketName
    secretAccessKey
    ;

  newData = "${toString installerPackage}/data/nixos-asahi-${version}.json";

  uploadPy = writeScript "upload.py" ''
    import boto3
    import os
    import sys
    from botocore.config import Config

    aws_access_key_id = "${accessKeyId}"
    aws_secret_access_key = "${secretAccessKey}"
    r2_endpoint = f"https://${accountId}.r2.cloudflarestorage.com"
    bucket_name = "${bucketName}"

    zipfile_path = "${toString installerPackage}/nixos-asahi-${version}.zip"
    data_path = "${toString installerPackage}/data/nixos-asahi-${version}.json"
    joined_data_path = "installer_data.json"

    obj_dict = {
        zipfile_path: f"os/nixos-asahi-${version}.zip",
        data_path: f"os/nixos-asahi-${version}.json",
        joined_data_path: f"data/installer_data.json",
    }

    s3 = boto3.client(
        "s3",
        region_name="auto",
        config=Config(signature_version="s3v4"),
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        endpoint_url=r2_endpoint,
    )

    transfer_config = boto3.s3.transfer.TransferConfig(
        multipart_threshold=8 * 1024 * 1024,
        multipart_chunksize=8 * 1024 * 1024,
    )


    def upload_to_r2(file_path, object_key):
        with open(file_path, "rb") as f:
            s3.upload_fileobj(
                Fileobj=f,
                Bucket=bucket_name,
                Key=object_key,
                Config=transfer_config,
            )

    for path, key in obj_dict.items():
        upload_to_r2(path, key)
  '';

  listObjectsPy = writeScript "list_objects.py" ''
    import boto3
    import re
    import os

    access_key_id = "${accessKeyId}"
    account_id = "${accountId}"
    secret_access_key = "${secretAccessKey}"

    session = boto3.Session(
        aws_access_key_id=access_key_id,
        aws_secret_access_key=secret_access_key,
    )

    s3 = session.resource(
        "s3",
        endpoint_url=f"https://{account_id}.r2.cloudflarestorage.com",
        region_name="auto",
    )

    r2_bucket = s3.Bucket("${bucketName}")

    substring = "os"

    for obj in r2_bucket.objects.all():
        if re.search(substring, obj.key):
            if obj.key.endswith("json"):
                print(obj.key)

  '';
in
with lib;
getExe (writeShellApplication {
  name = "release";
  runtimeInputs = with pkgs; [ (python3.withPackages (ps: [ ps.boto3 ])) ];
  text = ''
    tmpDir=$(mktemp -d)

    mkdir -p "$tmpDir"
    cd "$tmpDir"

    python3 ${listObjectsPy} > object_list

    if [[ -s object_list ]]; then  
      xargs -I % curl -LO https://cdn.qeden.systems/% < object_list
      sed -i 's/os\///g' ./object_list
      mapfile dataFiles < ./object_list
      rm object_list
    fi

    dataFiles+=("${newData}")

    jq -s '{os_list: .}' "''${dataFiles[@]}" > installer_data.json

    echo "Uploading package and installer data to bucket..."
    python3 ${uploadPy}
    echo "Upload finished!"
  '';
})
