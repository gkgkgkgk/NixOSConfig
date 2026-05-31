#!/usr/bin/env python3
"""
Extract a color palette from a wallpaper and write ~/.cache/theme/colors.env.
Requires: imagemagick (magick command)

Usage:
  generate-colors.py <image> [output_path]
"""

import sys
import os
import colorsys
import subprocess
import re


def rgb_to_hex(r, g, b):
    return f"#{int(r):02x}{int(g):02x}{int(b):02x}"


def luminance(r, g, b):
    return 0.299 * r + 0.587 * g + 0.114 * b


def to_hsv(r, g, b):
    return colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)


def boost_saturation(r, g, b, factor=1.8, min_value=0.72):
    h, s, v = to_hsv(r, g, b)
    s = min(1.0, s * factor)
    v = max(v, min_value)
    r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
    return int(r2 * 255), int(g2 * 255), int(b2 * 255)


def blend(c1, c2, t):
    return (
        int(c1[0] + (c2[0] - c1[0]) * t),
        int(c1[1] + (c2[1] - c1[1]) * t),
        int(c1[2] + (c2[2] - c1[2]) * t),
    )


def wcag_luminance(r, g, b):
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def contrast_ratio(c1, c2):
    l1, l2 = wcag_luminance(*c1), wcag_luminance(*c2)
    hi, lo = max(l1, l2), min(l1, l2)
    return (hi + 0.05) / (lo + 0.05)


def ensure_contrast(accent, bg, min_ratio=4.5):
    h, s, v = to_hsv(*accent)
    r, g, b = accent
    while contrast_ratio((r, g, b), bg) < min_ratio and v < 1.0:
        v = min(1.0, v + 0.04)
        r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
        r, g, b = int(r2 * 255), int(g2 * 255), int(b2 * 255)
    return r, g, b


def hue_distance(c1, c2):
    h1 = to_hsv(*c1)[0]
    h2 = to_hsv(*c2)[0]
    d = abs(h1 - h2)
    return min(d, 1.0 - d)


def extract_palette(image_path, n=24):
    result = subprocess.run(
        ["magick", image_path,
         "-resize", "100x100^",
         "-quantize", "transparent",
         "-colors", str(n),
         "+dither", "-unique-colors",
         "-depth", "8", "txt:-"],
        capture_output=True, text=True
    )
    hexes = re.findall(r'#([0-9A-Fa-f]{6})', result.stdout)
    return [(int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)) for h in hexes]


def generate(image_path):
    colors = extract_palette(image_path)
    if not colors:
        sys.exit(f"Error: no colors extracted from {image_path}")

    by_lum = sorted(colors, key=lambda c: luminance(*c))

    bg_raw = next((c for c in by_lum if luminance(*c) > 5), by_lum[0])
    fg_raw = by_lum[-1]

    overlay_candidates = [c for c in by_lum if 15 < luminance(*c) < 80]
    overlay_raw = overlay_candidates[0] if overlay_candidates else by_lum[min(2, len(by_lum) - 1)]

    mid = [c for c in colors if 25 < luminance(*c) < 230]
    by_sat = sorted(mid, key=lambda c: to_hsv(*c)[1], reverse=True)

    accent_raw = by_sat[0] if by_sat else colors[0]

    accent2_raw = None
    for candidate in by_sat[1:]:
        if hue_distance(accent_raw, candidate) > 0.08:
            accent2_raw = candidate
            break
    if accent2_raw is None:
        accent2_raw = by_sat[1] if len(by_sat) > 1 else accent_raw

    # ACCENT is the *single* neon splash. Keep ACCENT2 for downstream consumers
    # (KDE / eww / sioyek / hyprland) but the bar (GavBar) only uses ACCENT.
    accent  = ensure_contrast(boost_saturation(*accent_raw,  factor=1.3),  bg_raw)
    accent2 = ensure_contrast(boost_saturation(*accent2_raw, factor=1.8),  bg_raw)

    # MUTED: a neutral chrome color derived from the wallpaper itself (BG nudged
    # toward FG). Used for outlines / secondary surfaces / hover states in the
    # bar, decoupling those from the loud accent.
    muted_raw = blend(bg_raw, fg_raw, 0.28)

    # OVERLAY can collide with BG when the wallpaper has no mid-tones; lift it
    # slightly toward FG so mSurfaceVariant is always visually distinct.
    if abs(luminance(*overlay_raw) - luminance(*bg_raw)) < 6:
        overlay_raw = blend(bg_raw, fg_raw, 0.10)

    lum = luminance(*bg_raw)
    clock_text = rgb_to_hex(*fg_raw) if lum < 128 else "#1a1520"

    return {
        "BG":         rgb_to_hex(*bg_raw),
        "FG":         rgb_to_hex(*fg_raw),
        "ACCENT":     rgb_to_hex(*accent),
        "ACCENT2":    rgb_to_hex(*accent2),
        "MUTED":      rgb_to_hex(*muted_raw),
        "OVERLAY":    rgb_to_hex(*overlay_raw),
        "CLOCK_TEXT": clock_text,
    }


def write_env(colors, output_path):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        for k, v in colors.items():
            f.write(f'export {k}="{v}"\n')


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <wallpaper> [output_path]")
        sys.exit(1)

    image_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else os.path.expanduser("~/.cache/theme/colors.env")

    colors = generate(image_path)
    write_env(colors, output_path)

    for k, v in colors.items():
        print(f"  {k}: {v}")
