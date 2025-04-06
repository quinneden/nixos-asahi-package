{
  curl,
  jq,
  python3,
  writeShellApplication,
  ...
}:
writeShellApplication {
  name = "upload-to-r2";

  runtimeInputs = [
    curl
    jq
    (python3.withPackages (
      ps: with ps; [
        boto3
        requests
        tqdm
      ]
    ))
  ];

  text = ''
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -e | --env)
          dotenv="$2"
          shift 2
          ;;
        *)
          src_dir=$(realpath "$1")
          shift
          ;;
      esac
    done

    dotenv="''${dotenv:-./.env}"
    src_dir="''${src_dir:-$(realpath ./result)}"

    if [[ ! -d $src_dir ]]; then
      echo "error: source directory not specified or doesn't exist" >&2
      exit 1
    else
      PKG_DATA="$(find "$src_dir" -follow -name "installer_data-*.json")"; export PKG_DATA
      PKG_ZIP="$(find "$src_dir" -follow -name "nixos-asahi-*.zip")"; export PKG_ZIP
    fi

    if [[ ! -f $PKG_DATA || ! -f $PKG_ZIP ]]; then
      echo "error: package and/or installer data not found in source directory" >&2
      exit 1
    else
      # shellcheck disable=SC1090
      source "$dotenv"
      exec ${./upload-to-r2.py}
    fi
  '';
}
