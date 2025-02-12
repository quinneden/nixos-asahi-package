{
  pkgs,
  self,
  ...
}:
let
  inherit (pkgs) lib writeShellApplication writeScript;
  inherit (self.packages.${pkgs.system}) installerPackage;
  inherit (installerPackage) version;

  uploadPy = writeScript "upload.py" ''
    import boto3
    import os
    import sys
    from botocore.config import Config
    from dotenv import dotenv_values

    secrets = dotenv_values(".env")

    pkg_zip = "nixos-asahi-${version}.zip"
    pkg_data = "installer_data.json"

    obj_list = [pkg_zip, pkg_data]

    s3 = boto3.client(
        "s3",
        region_name="auto",
        config=Config(signature_version="s3v4"),
        aws_access_key_id=secrets["ACCESS_KEY_ID"],
        aws_secret_access_key=secrets["SECRET_ACCESS_KEY"],
        endpoint_url=secrets["ENDPOINT_URL"],
    )

    transfer_config = boto3.s3.transfer.TransferConfig(
        multipart_threshold=8 * 1024 * 1024,
        multipart_chunksize=8 * 1024 * 1024,
    )


    def upload_to_r2(file):
        content_type = "text/plain" if file.endswith(".json") else "application/octet-stream"
        prefix = "data" if file.endswith(".json") else "os"
        with open(file, "rb") as fb:
            s3.upload_fileobj(
                fb,ExtraArgs={'ContentType': content_type},
                Bucket=bucket_name,
                Key=os.path.join(prefix, file),
                Config=transfer_config,
            )

    for obj in obj_list:
        upload_to_r2(obj)
  '';
in
with lib;
getExe (writeShellApplication {
  name = "upload-pkg-to-r2";
  runtimeInputs = with pkgs; [
    (python3.withPackages (ps: [
      ps.boto3
      ps.python-dotenv
    ]))
  ];
  text = ''
    pkgData="installer_data-${version}.json"
    pkgZip="nixos-asahi-${version}.zip"
    tmpDir=$(mktemp -d)

    trap 'rm -rf $tmpDir' EXIT

    pushd "$tmpDir" > /dev/null
    cp ${installerPackage}/{"$pkgZip","$pkgData"} ./.
    chmod -R +w ./.

    curl -sf -o os_list.json "https://cdn.qeden.systems/data/installer_data.json" || exit 1
    jq '.os_list += [input]' os_list.json "$pkgData" > installer_data.json

    echo "Uploading package and installer data to bucket..."
    python3 ${uploadPy} || exit 1
    echo "Done!"
    popd > /dev/null
  '';
})
