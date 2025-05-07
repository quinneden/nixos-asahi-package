{
  lib ? import <nixpkgs/lib>, # for builtins.currentTime
}:

unixTimestamp:

let
  # Constants
  secondsPerMinute = 60;
  minutesPerHour = 60;
  hoursPerDay = 24;
  secondsPerDay = secondsPerMinute * minutesPerHour * hoursPerDay;

  # Helper functions
  isLeapYear = year: (lib.mod year 4 == 0 && lib.mod year 100 != 0) || (lib.mod year 400 == 0);

  daysInMonth =
    { year, month }:
    if month == 2 then
      if isLeapYear year then 29 else 28
    else if
      builtins.elem month [
        4
        6
        9
        11
      ]
    then
      30
    else
      31;

  # Convert timestamp to days since epoch and remainder seconds
  daysSinceEpoch = unixTimestamp / secondsPerDay;

  # Calculate year
  calculateYear =
    days:
    let
      # Helper to find the year by accumulating days
      go =
        { year, remainingDays }:
        let
          daysInCurrentYear = if isLeapYear year then 366 else 365;
        in
        if remainingDays < daysInCurrentYear then
          { inherit year remainingDays; }
        else
          go {
            year = year + 1;
            remainingDays = remainingDays - daysInCurrentYear;
          };
    in
    go {
      year = 1970;
      remainingDays = days;
    };

  getLast =
    n: str:
    let
      len = builtins.stringLength str;
      validN = if n > len then len else n;
    in
    builtins.substring (len - validN) validN str;

  yearInfo = calculateYear (builtins.floor daysSinceEpoch);
  year = yearInfo.year;
  shortYear = lib.toInt (getLast 2 (toString yearInfo.year));
  dayOfYear = yearInfo.remainingDays + 1; # +1 because zero-indexed

  # Calculate month and day
  calculateMonthAndDay =
    { currentYear, remainingDays }:
    let
      go =
        { month, days }:
        let
          daysInCurrentMonth = daysInMonth {
            year = currentYear;
            month = month;
          };
        in
        if days <= daysInCurrentMonth then
          {
            inherit month;
            day = days;
          }
        else
          go {
            month = month + 1;
            days = days - daysInCurrentMonth;
          };
    in
    go {
      month = 1;
      days = remainingDays;
    };

  dateInfo = calculateMonthAndDay {
    currentYear = year;
    remainingDays = dayOfYear;
  };
  month = dateInfo.month;
  day = dateInfo.day;

  # Format with leading zeros
  pad = n: if n < 10 then "0${toString n}" else toString n;
in
{
  unix = unixTimestamp;
  date = "${toString year}-${pad month}-${pad day}";
  inherit
    year
    shortYear
    month
    day
    ;
}
# "${toString shortYear}.${toString month}.${toString day}"
