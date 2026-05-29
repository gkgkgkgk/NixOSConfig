#!/usr/bin/env python3
"""
Home-workspace supervisor.

Consolidates three former bash watchers into one async process:
  - eww dashboard widget toggled by workspace (was: dashboard-watch.sh)
  - non-dashboard windows bounced off workspace 10 (was: ws-redirect.sh)
  - dashboard-term position/workspace lock + cursor-aware focus (was: dashboard-term-warden.sh)
"""

import asyncio
import json
import os
import subprocess
import sys
from typing import Optional

# ── Configuration ────────────────────────────────────────────────────────────
HOME_WS = 10
HOME_WS_NAME = "⌂"
DASHBOARD_CLASS = "com.local.dashboard-term"
DASHBOARD_W, DASHBOARD_H = 750, 480
DASHBOARD_LEFT_X = 20
DASHBOARD_BOTTOM_MARGIN = 100
POSITION_POLL_SECONDS = 5
CURSOR_POLL_SECONDS = 0.1
# How long the cursor/position loops idle while the home workspace is NOT
# focused. Their work (focus-stealing off the dashboard-term, snapping it back
# after a drag) is only meaningful when you're actually looking at workspace 10,
# so off-workspace we just sleep instead of spawning hyprctl ~20x/sec.
IDLE_POLL_SECONDS = 0.5
# Eww windows shown only when the home workspace is active.
HOME_EWW_WINDOWS = ["dashboard", "photo-caption"]

# Tracks the focused workspace so the polling loops can cheaply skip work when
# we're not on the home workspace. Updated from workspacev2 events (and seeded
# once at startup) — no polling required to maintain it.
current_ws: Optional[int] = None


# ── Hyprland helpers ─────────────────────────────────────────────────────────
def hypr(*args: str) -> str:
    return subprocess.run(
        ["hyprctl", *args],
        capture_output=True, text=True, check=False,
    ).stdout


def hypr_json(*args: str):
    out = hypr(*args, "-j")
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        return None


def focused_monitor() -> dict:
    mons = hypr_json("monitors") or []
    for m in mons:
        if m.get("focused"):
            return m
    return mons[0] if mons else {"width": 1920, "height": 1080}


def find_dashboard() -> Optional[dict]:
    for c in hypr_json("clients") or []:
        if c.get("class") == DASHBOARD_CLASS:
            return c
    return None


def snap_back(addr: str) -> None:
    # Hyprland >=0.55 Lua config: dispatch payloads are evaluated as Lua, so
    # each batched dispatch is an expression returning a dispatcher object.
    # movetoworkspacesilent → hl.dsp.window.move({...}, { follow = false }).
    # resizewindowpixel/movewindowpixel have no documented hl.dsp.* mapping
    # yet; the { exact = {W, H}, window = "..." } forms are best-guess —
    # if Hyprland rejects them, the dashboard-term still ends up on the home
    # workspace (the silent-move succeeds) but with its previous geometry.
    mon = focused_monitor()
    ty = mon["height"] - DASHBOARD_H - DASHBOARD_BOTTOM_MARGIN
    move_ws = (
        f'hl.dsp.window.move({{ workspace = {HOME_WS}, '
        f'window = "address:{addr}" }}, {{ follow = false }})'
    )
    resize = (
        f'hl.dsp.window.resize({{ exact = {{ {DASHBOARD_W}, {DASHBOARD_H} }}, '
        f'window = "address:{addr}" }})'
    )
    reposition = (
        f'hl.dsp.window.move({{ exact = {{ {DASHBOARD_LEFT_X}, {ty} }}, '
        f'window = "address:{addr}" }})'
    )
    hypr(
        "--batch",
        f"dispatch {move_ws} ; dispatch {resize} ; dispatch {reposition}",
    )


def next_empty_workspace() -> int:
    used = {w["id"] for w in (hypr_json("workspaces") or [])}
    n = 1
    while n in used or n == HOME_WS:
        n += 1
    return n


def set_home_widgets(workspace_id: int) -> None:
    action = "open" if workspace_id == HOME_WS else "close"
    for window in HOME_EWW_WINDOWS:
        subprocess.run(["eww", action, window], capture_output=True)


# ── Event handlers ───────────────────────────────────────────────────────────
def handle_event(event: str, payload: str) -> None:
    if event == "workspacev2":
        global current_ws
        ws_id_str = payload.split(",", 1)[0]
        try:
            current_ws = int(ws_id_str)
            set_home_widgets(current_ws)
        except ValueError:
            pass

    elif event == "openwindow":
        # ADDRESS,WORKSPACE_NAME,CLASS,TITLE
        parts = payload.split(",")
        if len(parts) < 3:
            return
        addr = f"0x{parts[0]}"
        ws_name = parts[1]
        cls = parts[2]
        if cls == DASHBOARD_CLASS:
            snap_back(addr)
        elif ws_name in (str(HOME_WS), HOME_WS_NAME):
            target = next_empty_workspace()
            hypr(
                "dispatch",
                f'hl.dsp.window.move({{ workspace = {target}, window = "address:{addr}" }})',
            )

    elif event == "movewindowv2":
        # ADDRESS,WORKSPACE_ID,WORKSPACE_NAME
        parts = payload.split(",")
        if len(parts) < 2:
            return
        addr = f"0x{parts[0]}"
        new_ws = parts[1]
        if new_ws == str(HOME_WS):
            return
        d = find_dashboard()
        if d and d.get("address") == addr:
            snap_back(addr)


# ── Async loops ──────────────────────────────────────────────────────────────
async def wait_for_socket(sock_path: str) -> None:
    while not os.path.exists(sock_path):
        await asyncio.sleep(0.3)


async def event_listener() -> None:
    sig = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
    runtime = os.environ["XDG_RUNTIME_DIR"]
    sock_path = f"{runtime}/hypr/{sig}/.socket2.sock"
    await wait_for_socket(sock_path)
    reader, _ = await asyncio.open_unix_connection(sock_path)
    while True:
        raw = await reader.readline()
        if not raw:
            return
        line = raw.decode(errors="replace").rstrip()
        if ">>" not in line:
            continue
        ev, payload = line.split(">>", 1)
        try:
            handle_event(ev, payload)
        except Exception as e:
            print(f"event {ev} handler error: {e}", file=sys.stderr)


async def cursor_loop() -> None:
    """Shift focus away from dashboard-term when cursor leaves its bounds —
    only if another window on workspace 10 exists as a focus target."""
    was_inside = False
    while True:
        # Only meaningful while viewing the home workspace; otherwise idle
        # without touching hyprctl at all.
        if current_ws != HOME_WS:
            was_inside = False
            await asyncio.sleep(IDLE_POLL_SECONDS)
            continue
        d = find_dashboard()
        if d:
            tx, ty = d["at"]
            tw, th = d["size"]
            raw = hypr("cursorpos").strip()
            try:
                cx_s, cy_s = raw.split(",")
                cx, cy = int(cx_s), int(cy_s.strip())
            except (ValueError, IndexError):
                await asyncio.sleep(CURSOR_POLL_SECONDS)
                continue

            inside = tx <= cx < tx + tw and ty <= cy < ty + th
            if inside:
                was_inside = True
            else:
                if was_inside:
                    active = hypr_json("activewindow") or {}
                    if active.get("address") == d["address"]:
                        other = next(
                            (c for c in (hypr_json("clients") or [])
                             if c["workspace"]["id"] == HOME_WS
                             and c["address"] != d["address"]),
                            None,
                        )
                        if other:
                            hypr(
                                "dispatch",
                                f'hl.dsp.focus({{ window = "address:{other["address"]}" }})',
                            )
                was_inside = False
        await asyncio.sleep(CURSOR_POLL_SECONDS)


async def position_loop() -> None:
    """Snap dashboard-term back to its locked geometry on a slow tick (catches drags)."""
    while True:
        await asyncio.sleep(POSITION_POLL_SECONDS)
        # Manual drags only happen while viewing ws10; skip the clients query
        # otherwise. openwindow/movewindow events still re-snap on their own.
        if current_ws != HOME_WS:
            continue
        d = find_dashboard()
        if not d:
            continue
        mon = focused_monitor()
        target_y = mon["height"] - DASHBOARD_H - DASHBOARD_BOTTOM_MARGIN
        tx, ty = d["at"]
        tw, th = d["size"]
        if (tx, ty, tw, th) != (DASHBOARD_LEFT_X, target_y, DASHBOARD_W, DASHBOARD_H):
            snap_back(d["address"])


async def main() -> None:
    # Wait for eww (matches what dashboard-watch.sh did before)
    for _ in range(50):
        if subprocess.run(["eww", "ping"], capture_output=True).returncode == 0:
            break
        await asyncio.sleep(0.2)

    global current_ws
    aw = hypr_json("activeworkspace") or {}
    if "id" in aw:
        current_ws = aw["id"]
        set_home_widgets(aw["id"])

    await asyncio.gather(
        event_listener(),
        cursor_loop(),
        position_loop(),
    )


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
