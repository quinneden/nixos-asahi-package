{
  asahiPackage,
  pkgs,
  python3,
  python3Packages,
  secrets,
  writeShellScriptBin,
}:
let
  inherit (builtins) readFile;
  inherit (pkgs) fetchurl lib jq;
  baseUrl = "https://cdn.qeden.systems";
  dateTag = readFile (toString asahiPackage + "/.release_date");
  installerDataTemplate = "${./data/template/installer_data.json}";
  pkgZip = "nixos-asahi-${dateTag}.zip";
  rootSize = readFile (toString asahiPackage + "/.root_part_size");

  installerDataCurrent = fetchurl {
    url = "${toString baseUrl}/data/installer_data.json";
    hash = "sha256-5jFkkHny6PLssb1kkNqi/J7hnZOiKUK0v+UhETii3mk="; # Changes on every release
  };

  uploadScript = writeShellScriptBin "upload-to-cdn" ''
    tmpDir=$(mktemp -d upload-to-cdn.XXXXXXXXXX)
    export tmpDir

    cp "${pkgZip}" "$tmpDir"
    chmod 644 "$tmpDir/${pkgZip}"

    echo "Starting upload: ''${pkgZip}'"

    python3 ${pythonScript} pkg

    if [[ $(jq -r '.os_list | last | .package' ${installerDataCurrent}) != "${baseUrl}/os/${pkgZip}" ]]; then
      jq -r < ${installerDataTemplate} \
        ".[].[].package = \"${baseUrl}/os/${pkgZip}\" | .[].[].partitions.[1].size = \"${rootSize}B\" | .[].[].name = \"NixOS Asahi Package ${dateTag}\"" \
        > "$tmpDir/new_installer_data.json"

      jq '.os_list += (input | .os_list)' "${installerDataCurrent}" "$tmpDir/new_installer_data.json" > "$tmpDir/merged_installer_data.json"
    fi

    python3 ${pythonScript} data
  '';

  pythonScript = pkgs.writeText "python-boto3-script" ''
    import boto3
    import os
    import sys
    from botocore.config import Config

    aws_access_key_id = "${secrets.accessKeyId}"
    aws_secret_access_key = "${secrets.secretAccessKey}"
    r2_endpoint = "https://${secrets.accountId}.r2.cloudflarestorage.com"

    bucket_name = "${secrets.bucketName}"

    tmp_dir = "os.environ[tmpDir]"
    pkg = "${pkgZip}"

    if len(sys.argv) > 1:
        if sys.argv[1] == "pkg":
            file_path = os.path.join(tmp_dir, pkg)
            object_key = os.path.join("os", pkg)
        if sys.argv[1] == "data":
            file_path = os.path.join(tmp_dir, "merged_installer_data.json")
            object_key = os.path.join("data", "installer_data.json")

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
mkShell {
  buildInputs = [ uploadScript ];
  shellHook = ''
    exec ${uploadScript}
  '';
}
