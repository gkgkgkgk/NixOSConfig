let
  hexVal = s:
    let d = { "0"=0;"1"=1;"2"=2;"3"=3;"4"=4;"5"=5;"6"=6;"7"=7;"8"=8;"9"=9;"a"=10;"b"=11;"c"=12;"d"=13;"e"=14;"f"=15; };
    in d.${builtins.substring 0 1 s} * 16 + d.${builtins.substring 1 1 s};

  # Convert #RRGGBB + alpha string to rgba() — needed for GTK CSS (Waybar)
  toRgba = hex: alpha:
    let s = builtins.substring 1 6 hex;
    in "rgba(${toString (hexVal (builtins.substring 0 2 s))}, ${toString (hexVal (builtins.substring 2 2 s))}, ${toString (hexVal (builtins.substring 4 2 s))}, ${alpha})";

  bg      = "#231f36";
  overlay = "#524535";
  fg      = "#e0def4";
  subtle  = "#908caa";
  accent  = "#e7d6a7";
in {
  inherit bg overlay fg subtle accent toRgba;
}
