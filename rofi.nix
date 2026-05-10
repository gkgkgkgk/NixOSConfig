{ pkgs, ... }:
let colors = import ./colors.nix; in

{
  home.packages = [ pkgs.rofi ];

  # Written directly so stylix never touches it
  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
        modi:                "drun";
        show-icons:          true;
        drun-display-format: "{name}";
    }

    * {
        bg:      ${colors.bg}ed;
        overlay: ${colors.overlay}d1;
        fg:      ${colors.fg};
        subtle:  ${colors.subtle};
        accent:  ${colors.accent};

        background-color: transparent;
        text-color:       @fg;
        font:             "Inter 11";
    }

    window {
        location:         center;
        anchor:           center;
        width:            640px;
        background-color: @bg;
        border-radius:    16px;
        border:           2px;
        border-color:     ${colors.accent}2e;
    }

    mainbox {
        background-color: transparent;
        padding:          14px;
        spacing:          10px;
    }

    inputbar {
        background-color: @overlay;
        border-radius:    10px;
        padding:          10px 16px;
        spacing:          10px;
        children:         [ prompt, entry ];
    }

    prompt {
        background-color: transparent;
        text-color:       @accent;
    }

    entry {
        background-color:  transparent;
        text-color:        @fg;
        placeholder:       "Search apps...";
        placeholder-color: @subtle;
        cursor:            text;
    }

    listview {
        background-color: transparent;
        lines:            7;
        scrollbar:        false;
        spacing:          2px;
        padding:          4px 0 0;
    }

    element {
        background-color: transparent;
        padding:          8px 12px;
        border-radius:    8px;
        spacing:          10px;
        orientation:      horizontal;
        children:         [ element-icon, element-text ];
    }

    element.selected.normal,
    element.selected.urgent,
    element.selected.active {
        background-color: @overlay;
    }

    element-icon {
        background-color: transparent;
        size:             22px;
        vertical-align:   0.5;
    }

    element-text {
        background-color: transparent;
        vertical-align:   0.5;
    }

    no-entries {
        background-color: transparent;
        text-color:       @subtle;
        padding:          12px;
        horizontal-align: 0.5;
    }
  '';
}
