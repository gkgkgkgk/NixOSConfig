#!/usr/bin/env python3
"""
Resolves metadata for the current wallpaper.

theme-switch.sh writes the active wallpaper filename to ~/.cache/current-theme.
This script looks it up in photos.json and emits a flat JSON object that
eww's photo-caption widget consumes.

Always returns the full schema (with empty strings where missing) so the
yuck side doesn't have to handle nulls.
"""
import json
import os

CACHE = os.path.expanduser("~/.cache/current-theme")
DB    = os.path.expanduser("~/OSConfig/home-workspace/photos.json")

EMPTY = {"title": "", "location": "", "lat": "", "lng": "", "coord": "", "visited": ""}

def main() -> None:
    try:
        with open(CACHE) as f:
            key = f.read().strip()
        with open(DB) as f:
            data = json.load(f)
        entry = {**EMPTY, **(data.get(key) or {})}
    except Exception:
        entry = dict(EMPTY)

    if entry["lat"] != "" and entry["lng"] != "":
        entry["coord"] = f"{entry['lat']}, {entry['lng']}"

    print(json.dumps(entry))

if __name__ == "__main__":
    main()
