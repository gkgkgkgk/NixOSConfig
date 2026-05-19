{ pkgs, ... }:

{
  home.packages = [ pkgs.rofi ];

  xdg.configFile."rofi/config.rasi".text = ''
    @import "/home/gavri/.config/rofi/colors.rasi"

    configuration {
        modi:                "drun";
        show-icons:          true;
        drun-display-format: "{name}";
    }

    /* No text-color here — set explicitly per widget so nothing overrides */
    * {
        background-color: transparent;
        font:             "Inter 11";
    }

    window {
        location:         center;
        anchor:           center;
        width:            640px;
        background-color: @bg;
        border-radius:    16px;
        border:           2px;
        border-color:     @accent-border;
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
        spacing:          0px;
        padding:          4px 0 0;
    }

    /* ── Normal (unselected) rows — dark, muted ── */
    element normal.normal {
        background-color: transparent;
        text-color:       @subtle;
        border-radius:    8px;
        padding:          8px 12px;
    }

    /* Alternating row gets a faint dark tint */
    element alternate.normal {
        background-color: @overlay;
        text-color:       @subtle;
        border-radius:    8px;
        padding:          8px 12px;
    }

    /* ── Selected row — light and clear ── */
    element selected.normal {
        background-color: @accent-border;
        text-color:       @fg;
        border-radius:    8px;
        border:           1px;
        border-color:     @accent;
        padding:          8px 12px;
    }

    /* Apply same layout to urgent/active states */
    element normal.urgent,
    element normal.active {
        background-color: transparent;
        text-color:       @subtle;
        border-radius:    8px;
        padding:          8px 12px;
    }

    element selected.urgent,
    element selected.active {
        background-color: @accent-border;
        text-color:       @fg;
        border-radius:    8px;
        border:           1px;
        border-color:     @accent;
        padding:          8px 12px;
    }

    element {
        spacing:     10px;
        orientation: horizontal;
        children:    [ element-icon, element-text ];
    }

    element-icon {
        background-color: transparent;
        size:             22px;
        vertical-align:   0.5;
    }

    element-text {
        background-color: transparent;
        text-color:       inherit;
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
