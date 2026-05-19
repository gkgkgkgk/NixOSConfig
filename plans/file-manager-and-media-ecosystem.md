# File Manager & Media Ecosystem (Nemo + Sioyek + Live-Reload Theming)

## Goal

Replace the current Dolphin/Gwenview KDE pair with a slimmer GTK-centered ecosystem:
**Nemo** (file manager) + **Sioyek** (PDFs) + **imv** (images) + **mpv/Celluloid** (video).
Make every app participate in the wallpaper-derived theme switch *without restart*.
Rip out Stylix entirely — the wallpaper hook pipeline becomes the single source of truth.

## Non-goals

- No CLI file managers.
- No new theming framework; keep the existing `colors.env` + hook fan-out pattern.
- No backwards-compat / fallbacks for the old Dolphin path. Delete it cleanly.

---

## Phase 0 — Verify two unknowns before committing

Two things drive the design and need a quick check first:

1. **Sioyek IPC reload**: confirm whether the installed `sioyek` supports
   `sioyek --execute-command reload_config_file` (or similar). Run
   `sioyek --help` and grep upstream `main_widget.cpp` for `reload_config`.
   If present → live reload. If absent → session-preserving restart pattern.
2. **mpv IPC**: confirm we're OK adding `input-ipc-server=/tmp/mpvsocket` to
   `~/.config/mpv/mpv.conf` (this is the live-update channel for running mpv
   instances). Acceptable security-wise on a single-user box.

Outcome of Phase 0 determines exact wording of `theme-hooks/sioyek.sh` and
`theme-hooks/mpv.sh` in Phase 4.

---

## Phase 1 — Rip out Stylix

### Touch points

- `flake.nix`: drop `inputs.stylix` and `stylix.nixosModules.stylix` from the modules list.
- `configuration.nix`: delete the entire `stylix = { … };` block (lines ~125–150).
- `home.nix`: delete `stylix.targets.noctalia-shell.enable`, `stylix.targets.hyprpaper.enable`, AND the now-orphaned `gtk.gtk4.theme = config.gtk.theme;` line (nothing else sets `gtk.theme` once Stylix is gone, so eval would fail).
- `rofi.nix`: drop the "stylix never touches it" comment (no longer relevant).

### Re-establish what Stylix was providing

| Was via Stylix                  | Replacement                                                                                          |
|---------------------------------|------------------------------------------------------------------------------------------------------|
| Cursor (BreezeX-RosePine, 24px) | `home.pointerCursor = { name; package; size; gtk.enable = true; x11.enable = true; }` in `home.nix` |
| Fonts (JetBrainsMono, Inter)    | `fonts.packages` + `fonts.fontconfig.defaultFonts.{monospace,sansSerif}` in `configuration.nix`     |
| Base16 palette                  | Already replaced — `colors.env` is the runtime source                                                |
| `polarity = "dark"`             | Implicit in the wallpaper palette + GTK theme choice (Adwaita-dark anchor)                           |
| Font sizes (apps 11, term 13)   | App-side: written into ghostty/gtk configs directly as needed                                        |

### Validation

After Phase 1, rebuild and confirm: cursor still themed, fonts intact, all
existing hooks (waybar/ghostty/noctalia/eww/rofi/hyprland) still live-reload
on `Mod+Shift+W`. No new apps yet — pure subtractive change.

---

## Phase 2 — Add the new app stack (no theming yet)

### NixOS / Home Manager additions

In `configuration.nix`:
```
services.gvfs.enable = true;   # SMB/SFTP/network drives for Nemo
```

In `home.nix` `home.packages`:
- `pkgs.nemo-with-extensions`
- `pkgs.cifs-utils`
- `pkgs.sioyek`
- `pkgs.imv`
- `pkgs.mpv`
- `pkgs.celluloid` *(optional GTK frontend if we want the file-manager-style
  theming to extend to video chrome; can defer)*

Remove from `home.packages`:
- `pkgs.kdePackages.dolphin`
- `pkgs.kdePackages.gwenview`
- `pkgs.kdePackages.kio-extras`
- `pkgs.kdePackages.plasma-integration`
- `pkgs.kdePackages.breeze`

Keep `qt.platformTheme.name = "kde"` for now — Sioyek is a Qt app and reads
`kdeglobals`, which `theme-hooks/kde.sh` already writes. Means we don't lose
Qt theming when KDE apps leave.

### Declarative glue refactor

In `home.nix`, introduce a single `myApps` attrset and derive everything from it:

```
let
  myApps = {
    fileManager = "nemo.desktop";
    image       = "imv.desktop";
    pdf         = "sioyek.desktop";
    video       = "mpv.desktop";   # or celluloid if added
  };
in {
  xdg.desktopEntries."file-explorer" = {
    name = "File Explorer";
    exec = "nemo %U";
    icon = "system-file-manager";
    categories = [ "System" "FileManager" ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory"                    = myApps.fileManager;
      "application/x-gnome-saved-search"   = myApps.fileManager;
      "application/pdf"                    = myApps.pdf;
      "image/jpeg"   = myApps.image;
      "image/png"    = myApps.image;
      "image/gif"    = myApps.image;
      "image/webp"   = myApps.image;
      "image/bmp"    = myApps.image;
      "image/tiff"   = myApps.image;
      "image/avif"   = myApps.image;
      "video/mp4"    = myApps.video;
      "video/x-matroska" = myApps.video;
      "video/webm"   = myApps.video;
    };
  };
}
```

Delete the existing `xdg.desktopEntries."org.kde.dolphin"` hide-alias.

### Validation

After Phase 2, Nemo opens with default GTK styling, network drives appear in
its sidebar, double-clicking a PDF launches Sioyek, an image opens imv, a
video opens mpv. Theming is wrong/inconsistent — that's Phase 3+.

---

## Phase 3 — GTK live-reload hook (the centerpiece)

### Design

The "two-name toggle" pattern, fully owned by us:

1. Hook writes color overrides to a custom theme directory:
   `~/.local/share/themes/WallpaperTheme/gtk-3.0/gtk.css`
   `~/.local/share/themes/WallpaperTheme/gtk-4.0/gtk.css`

   Each file is small: just `@define-color` lines + `@import` of
   `Adwaita-dark`'s base (or a hand-rolled minimal stylesheet).

2. To force GTK3/4 to re-read, we toggle the gsettings key.
   Two identical symlinks: `WallpaperTheme-Tick` → `WallpaperTheme`,
   `WallpaperTheme-Tock` → `WallpaperTheme`. Hook alternates between them
   via `gsettings set org.gnome.desktop.interface gtk-theme '…-Tick'` and
   `'…-Tock'`. Same content, different name → GTK invalidates its cache.

3. State (last value used) lives at `~/.cache/theme/gtk-toggle`.

### Files to create

- `~/OSConfig/theme-hooks/gtk.sh` — writes CSS, flips gsettings, persists toggle state.
- (Optional) a static `~/.local/share/themes/WallpaperTheme/index.theme`
  declaring it as an "Adwaita-dark"-derived theme so apps that look for a
  parent-theme inherit sensibly.

### Things this hook deliberately *does not* do

- Does not touch `~/.config/gtk-3.0/gtk.css` directly — that file is
  user-global and conflicts with `home-manager`'s `gtk.gtk3.extraCss`.
- Does not call `gsettings set color-scheme` — we own dark/light entirely.

### home.nix adjustments

- Drop `gtk.gtk4.theme = config.gtk.theme;` (we own GTK via the hook now).
- If you want home-manager to keep `gtk.enable`, set `gtk.theme.name =
  "WallpaperTheme-Tick"` as the *initial* value; the hook will diverge from
  there at runtime. Otherwise drop the entire `gtk.*` block.

### Validation

- Open Nemo, run `theme-switch.sh --next`. Headerbar, sidebar, and
  selection chrome should swap colors live, no restart.
- Toolbar icons may flicker once — acceptable.
- Confirm gsettings actually toggles (`gsettings get …`); if cache isn't
  invalidating, fallback is `dconf update`.

---

## Phase 4 — Sioyek and mpv hooks

### `theme-hooks/sioyek.sh`

Writes `~/.config/sioyek/prefs_user.config`:
```
background_color <bg-as-floats>
text_highlight_color <accent-as-floats>
ui_text_color <fg-as-floats>
ui_background_color <bg-as-floats>
ui_selected_background_color <accent-as-floats>
...
```
(Sioyek wants `0.0–1.0` floats per channel, not hex — hook converts.)

Then, per Phase 0 outcome:
- **If `reload_config_file` IPC exists** → `sioyek --execute-command reload_config_file`.
- **Else** → if a sioyek process is open: kill it, wait 0.2s, relaunch
  in background. Session restore handles the rest.

### `theme-hooks/mpv.sh`

Writes `~/.config/mpv/script-opts/osc.conf` with new OSC bar colors (for
next launch).

For *running* instances:
```
echo '{ "command": ["set", "osd-color", "#…"] }' | socat - /tmp/mpvsocket
```
(Quiet failure if no socket — single mpv invocation only writes one socket.)

Requires `~/.config/mpv/mpv.conf` to include `input-ipc-server=/tmp/mpvsocket`
— add via `home-manager`'s `programs.mpv` or a plain `xdg.configFile`.

### `theme-hooks/imv.sh`

Writes `~/.config/imv/config` with `background = <bg-hex>`. Reads at next
launch only — imv has no live reload. Acceptable since image viewing is
short-lived.

---

## Phase 5 — Cleanup pass

- Strip the dolphin/gwenview restart loop at the bottom of `theme-hooks/kde.sh`
  (KDE apps are gone). Keep the `kdeglobals` writes — Sioyek (Qt) still reads them.
- Audit `colors.nix` for any vars no longer referenced.
- Decide whether `qt.platformTheme.name = "kde"` still earns its keep
  (Sioyek is the only Qt app left; might be cleaner to switch to `"qtct"`
  and own `~/.config/qt5ct/qt5ct.conf` directly — defer unless we hit issues).
- Add a smoke-test note to this plan: "after wallpaper switch, every visible
  GUI surface should change within ~300ms with no app restart, except imv
  (next launch) and Sioyek (if non-IPC fallback)."

---

## Risk register

| Risk                                                | Mitigation                                         |
|-----------------------------------------------------|----------------------------------------------------|
| GTK toggle doesn't invalidate cache on Wayland      | Fallback to `dconf update` + explicit `XDG_DATA_DIRS` |
| Sioyek lacks `reload_config_file` in our version    | Session-restore restart (documented in Phase 4)    |
| Removing Stylix breaks an indirect dependency       | Phase 1 rebuilds before adding new apps — early signal |
| Nemo headerbar uses GTK4 (libadwaita) and ignores classic theme | Add gtk-4.0 file in the WallpaperTheme dir; if libadwaita still dominant, fall back to `gtk.css` user override |
| `home.pointerCursor` differs subtly from Stylix's   | Test cursor across Hyprland + GTK + Qt before considering Phase 1 done |

---

## Execution order

1. Phase 0 (verify Sioyek IPC, decide on mpv socket) — read-only, ~5 min.
2. Phase 1 (Stylix removal) — single rebuild, validate parity.
3. Phase 2 (add apps + mime refactor) — single rebuild, validate file routing.
4. Phase 3 (GTK live-reload hook) — iteration heavy, expect tuning.
5. Phase 4 (Sioyek + mpv + imv hooks) — three small hooks, mostly independent.
6. Phase 5 (cleanup) — once everything green.

Each phase is independently revertable. Don't bundle phases.
