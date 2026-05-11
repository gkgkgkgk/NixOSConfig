{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    eww
    lm_sensors
  ];

  home.file = {
    ".config/eww/eww.yuck".source = ./eww/eww.yuck;
    ".config/eww/eww.scss".source = ./eww/eww.scss;
    ".config/eww/scripts/cpu.sh"  = { source = ./eww/scripts/cpu.sh;  executable = true; };
    ".config/eww/scripts/ram.sh"  = { source = ./eww/scripts/ram.sh;  executable = true; };
    ".config/eww/scripts/temp.sh" = { source = ./eww/scripts/temp.sh; executable = true; };
  };
}
