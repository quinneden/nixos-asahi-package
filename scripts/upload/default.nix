{
  curl,
  jq,
  python3,
  writeShellApplication,
  ...
}:
let
  pythonEnv = python3.withPackages (
    ps: with ps; [
      boto3
      requests
      tqdm
    ]
  );
in
writeShellApplication {
  name = "upload-to-r2";

  runtimeInputs = [
    curl
    jq
    pythonEnv
  ];

  excludeShellChecks = [ "SC1090" ];
  text = ''
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -e | --env)
          dotenv="$2"
          shift 2
          ;;
        *)
          result_dir=$(realpath "$1")
          shift
          ;;
      esac
    done

    dotenv="''${dotenv:-./.env}"
    result_dir="''${result_dir:-$(realpath ./result)}"; export result_dir

    if [[ ! -d "$result_dir" ]]; then
      echo "Error: $result_dir is not a directory" >&2
      exit 1
    fi

    source "$dotenv"
    exec ${./upload.py}
  '';
}
