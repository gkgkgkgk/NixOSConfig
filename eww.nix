{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    eww
    lm_sensors
    python3
  ];

  home.file = {
    ".config/eww/eww.yuck".source = ./eww/eww.yuck;
    ".config/eww/eww.scss".source = ./eww/eww.scss;
    ".config/eww/scripts/cpu.sh"     = { source = ./eww/scripts/cpu.sh;     executable = true; };
    ".config/eww/scripts/ram.sh"     = { source = ./eww/scripts/ram.sh;     executable = true; };
    ".config/eww/scripts/temp.sh"    = { source = ./eww/scripts/temp.sh;    executable = true; };
    ".config/eww/scripts/braille.py" = { source = ./eww/scripts/braille.py; executable = true; };
    ".config/eww/scripts/gpu.sh"     = { source = ./eww/scripts/gpu.sh;     executable = true; };
    ".config/eww/scripts/disk.sh"    = { source = ./eww/scripts/disk.sh;    executable = true; };
  };
}
