{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    eww
    lm_sensors
    python3
  ];

  home.file = {
    ".config/eww/eww.yuck".source     = ./eww.yuck;
    ".config/eww/eww-style.scss".source = ./eww-style.scss;
    ".config/eww/scripts/cpu.sh"     = { source = ./scripts/cpu.sh;     executable = true; };
    ".config/eww/scripts/ram.sh"     = { source = ./scripts/ram.sh;     executable = true; };
    ".config/eww/scripts/temp.sh"    = { source = ./scripts/temp.sh;    executable = true; };
    ".config/eww/scripts/braille.py" = { source = ./scripts/braille.py; executable = true; };
    ".config/eww/scripts/gpu.sh"     = { source = ./scripts/gpu.sh;     executable = true; };
    ".config/eww/scripts/disk.sh"    = { source = ./scripts/disk.sh;    executable = true; };
  };
}
