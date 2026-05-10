#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3Packages.pillow
"""
Auto-generate a colors.conf from a wallpaper image.

Usage:
  python3 generate-colors.py <image>          # writes colors.conf next to image
  python3 generate-colors.py themes/*/wallpaper.*  # batch all themes
"""

import sys
import os
import colorsys
from PIL import Image


def rgb_to_hex(r, g, b):
    return f"#{int(r):02x}{int(g):02x}{int(b):02x}"


def luminance(r, g, b):
    return 0.299 * r + 0.587 * g + 0.114 * b


def saturation(r, g, b):
    _, s, _ = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return s


def extract_palette(image_path, n=20):
    img = Image.open(image_path).convert("RGB")
    img = img.resize((300, 300), Image.LANCZOS)
    quantized = img.quantize(colors=n, method=Image.Quantize.MEDIANCUT)
    raw = quantized.getpalette()
    return [(raw[i * 3], raw[i * 3 + 1], raw[i * 3 + 2]) for i in range(n)]


def generate(image_path):
    colors = extract_palette(image_path)
    by_lum = sorted(colors, key=lambda c: luminance(*c))

    # BG: darkest, not pure black
    bg = next((c for c in by_lum if luminance(*c) > 5), by_lum[0])

    # FG: lightest
    fg = by_lum[-1]

    # OVERLAY: slightly lighter than bg, still dark
    overlay_candidates = [c for c in by_lum if 20 < luminance(*c) < 100]
    overlay = overlay_candidates[0] if overlay_candidates else by_lum[min(2, len(by_lum)-1)]

    # Accents: most saturated colors that aren't too dark or too light
    mid = [c for c in colors if 30 < luminance(*c) < 220]
    by_sat = sorted(mid, key=lambda c: saturation(*c), reverse=True)
    accent  = by_sat[0] if len(by_sat) > 0 else colors[4]
    accent2 = by_sat[1] if len(by_sat) > 1 else colors[5]

    return {
        "BG":      rgb_to_hex(*bg),
        "FG":      rgb_to_hex(*fg),
        "ACCENT":  rgb_to_hex(*accent),
        "ACCENT2": rgb_to_hex(*accent2),
        "OVERLAY": rgb_to_hex(*overlay),
    }


def write_conf(image_path, colors):
    out = os.path.join(os.path.dirname(image_path), "colors.conf")
    with open(out, "w") as f:
        f.write(f"# Auto-generated from {os.path.basename(image_path)}\n")
        for k, v in colors.items():
            f.write(f'{k}="{v}"\n')
    return out


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <wallpaper> [wallpaper2 ...]")
        sys.exit(1)

    for path in sys.argv[1:]:
        colors = generate(path)
        out = write_conf(path, colors)
        print(f"{path}")
        for k, v in colors.items():
            print(f"  {k}: {v}")
        print(f"  → {out}\n")
