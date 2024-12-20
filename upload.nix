{
  pkgs,
  self,
  ...
}:
let
  pythonWithBoto3 = pkgs.python3.withPackages (ps: [ ps.boto3 ]);

  inherit (pkgs)
    callPackage
    jq
    lib
    readFile
    writeShellScriptBin
    ;

  asahiPackage = self.packages.${pkgs.system}.asahiPackage;
  baseUrl = "https://cdn.qeden.systems";
  dateTag = readFile (toString asahiPackage + "/.release_date");
  installerDataCurrent = "${./data/installer_data.json}";
  installerDataTemplate = "${./data/template/installer_data.json}";
  pkgZip = "nixos-asahi-${dateTag}.zip";
  rootSize = readFile (toString asahiPackage + "/.root_part_size");

  uploadScript = writeShellScriptBin "upload-to-cdn" ''
    tmpDir=$(mktemp -d upload-to-cdn.XXXXXXXXXX)
    export tmpDir

    # trap 'rm -rf $tmpDir' EXIT

    source scripts/secrets.sh

    confirm() {
      while true; do
        read -r -n 1 -p "$1 [y/n]: " REPLY
        case $REPLY in
          [yY]) echo ; return 0 ;;
          [nN]) echo ; return 1 ;;
          *) echo ;;
        esac
      done
    }

    cp "${pkgZip}" "$tmpDir"
    chmod 644 "$tmpDir/${pkgZip}"

    echo "Starting upload: ''${pkgZip}'"

    ${pythonWithBoto3} scripts/main.py pkg

    cat ${installerDataCurrent} > "$tmpDir/old_installer_data.json"

    if [[ $(jq -r '.os_list | last | .package' data/installer_data.json) != "${baseUrl}/os/${pkgZip}" ]]; then
      jq -r < ${installerDataTemplate} \
        ".[].[].package = \"${baseUrl}/os/${pkgZip}\" | .[].[].partitions.[1].size = \"${rootSize}B\" | .[].[].name = \"NixOS Asahi Package ${dateTag}\"" \
        > "$tmpDir/new_installer_data.json"

      jq '.os_list += (input | .os_list)' "$tmpDir/old_installer_data.json" "$tmpDir/new_installer_data.json" > "$tmpDir/merged_installer_data.json"
    fi

    ${pythonWithBoto3} scripts/main.py data
  '';

  pythonScript = pkgs.writeText "python-boto3-script" ''
    import boto3
    import os
    import sys
    from botocore.config import Config

    aws_access_key_id = 
    aws_secret_access_key = 
    r2_endpoint = 

    bucket_name = 

    tmp_dir = 
    pkg = 

    if len(sys.argv) > 1:
        if sys.argv[1] == "pkg":
            file_path = os.path.join(tmp_dir, pkg)
            object_key = os.path.join("os", pkg)
        if sys.argv[1] == "data":
            file_path = "data/installer_data.json"
            object_key = file_path

    s3 = boto3.client(
        "s3",
        region_name="auto",
        config=Config(signature_version="s3v4"),
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        endpoint_url=r2_endpoint,
    )

    transfer_config = boto3.s3.transfer.TransferConfig(
        multipart_threshold=8 * 1024 * 1024,  # 8 MB
        multipart_chunksize=8 * 1024 * 1024,  # 8 MB
    )

    with open(file_path, "rb") as f:
        s3.upload_fileobj(
            Fileobj=f,
            Bucket=bucket_name,
            Key=object_key,
            Config=transfer_config,
        )

    print(f"{file_path} uploaded successfully to {bucket_name}.")
  '';
in
{
  type = "app";
  program = lib.getExe uploadScript;
}
