let
  timestamp = (import ./lib/timestamp.nix { }) builtins.currentTime;
  inherit (timestamp) shortYear month day;
in
{
  version = "${toString shortYear}.${toString month}.${toString day}";
  released = false;

  latestRelease = {
    commit = "b97da42f001d11db96e77201f9742a57f0ee6e6b";
    date = "2025-05-04";
    version = "0.1.4";
    tag = "v0.1.4";
  };
}
