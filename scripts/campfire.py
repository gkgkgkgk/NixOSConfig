#!/usr/bin/env python3
"""
Campfire startup scene using true-color halfblock rendering.
Each terminal cell shows 2 pixels via ▀ (fg=upper, bg=lower).
Press any key or wait to continue.
"""
import sys, os, math, random, time, signal, tty, termios, select

DURATION = 7.0
FPS      = 24

# ── Helpers ───────────────────────────────────────────────────────────────────

def lerp(a, b, t):
    return a + (b - a) * t

def clamp(v, lo=0, hi=255):
    return int(max(lo, min(hi, v)))

def blend(base, color, alpha):
    return (
        clamp(lerp(base[0], color[0], alpha)),
        clamp(lerp(base[1], color[1], alpha)),
        clamp(lerp(base[2], color[2], alpha)),
    )

# ── Pixel canvas ──────────────────────────────────────────────────────────────

class Canvas:
    def __init__(self, cols, rows):
        self.cols = cols
        self.rows = rows
        self.buf  = [[(0, 0, 0)] * cols for _ in range(rows)]

    def put(self, x, y, color, alpha=1.0):
        if 0 <= x < self.cols and 0 <= y < self.rows:
            if alpha >= 1.0:
                self.buf[y][x] = color
            else:
                self.buf[y][x] = blend(self.buf[y][x], color, alpha)

    def get(self, x, y):
        if 0 <= x < self.cols and 0 <= y < self.rows:
            return self.buf[y][x]
        return (0, 0, 0)

    def render(self):
        term_rows = self.rows // 2
        parts = ["\033[H"]
        for ty in range(term_rows):
            row = []
            for x in range(self.cols):
                tr, tg, tb = self.buf[ty * 2][x]
                br, bg, bb = self.buf[ty * 2 + 1][x] if ty * 2 + 1 < self.rows else (0, 0, 0)
                row.append(
                    f"\033[38;2;{tr};{tg};{tb}m\033[48;2;{br};{bg};{bb}m▀"
                )
            parts.append("".join(row) + "\033[0m")
        sys.stdout.write("\n".join(parts))
        sys.stdout.flush()


# ── Scene drawing ─────────────────────────────────────────────────────────────

def draw_sky(c, t):
    for y in range(c.rows):
        yt = y / c.rows
        r = clamp(lerp(2,  18, yt))
        g = clamp(lerp(2,  10, yt))
        b = clamp(lerp(28, 45, yt))
        for x in range(c.cols):
            c.buf[y][x] = (r, g, b)


def draw_stars(c, t, stars, sky_h):
    for sx, sy, phase, speed, base_b in stars:
        if sx >= c.cols or sy >= sky_h:
            continue
        b = base_b * (0.55 + 0.45 * math.sin(t * speed + phase))
        v = clamp(b * 255)
        # slightly blue-white
        col = (v, v, clamp(v + 25))
        c.put(sx, sy, col)
        if b > 0.88:
            d = (v // 4, v // 4, v // 4)
            for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                c.put(sx + dx, sy + dy, d)


def draw_shooting_star(c, sx, sy, age, sky_h):
    trail = 20
    for i in range(trail):
        tx = int(sx) - i * 2
        ty = int(sy) - i
        if not (0 <= tx < c.cols and 0 <= ty < sky_h):
            continue
        alpha = (1 - i / trail) ** 1.5
        v = clamp(alpha * 255)
        c.put(tx, ty, (v, min(255, v + 30), min(255, v + 60)))


def draw_tree(c, cx, base_y, height, sway):
    for row in range(height):
        half = row + 1
        sw   = int(round(sway * (height - row) / height * 3))
        y    = base_y - height + row
        if y < 0:
            continue
        for dx in range(-half, half + 1):
            x = cx + dx + sw
            if not (0 <= x < c.cols and 0 <= y < c.rows):
                continue
            edge   = abs(dx) / (half + 0.5)
            height_t = row / height
            g = clamp(lerp(55, 155, (1 - edge) * 0.5 + height_t * 0.5))
            r = clamp(lerp(5,  30,  height_t))
            b = clamp(lerp(5,  25,  edge))
            c.put(x, y, (r, g, b))
    # trunk
    for dy in range(4):
        c.put(cx, base_y + dy, (55, 32, 10))


def draw_ground(c, ground_y):
    for y in range(ground_y, c.rows):
        depth = (y - ground_y) / max(1, c.rows - ground_y)
        r = clamp(lerp(20, 8,  depth))
        g = clamp(lerp(32, 12, depth))
        b = clamp(lerp(14, 5,  depth))
        for x in range(c.cols):
            c.put(x, y, (r, g, b))


def draw_fire_glow(c, cx, fire_y, t):
    glow_r = 35
    for dy in range(-glow_r, glow_r + 1):
        for dx in range(-glow_r * 2, glow_r * 2 + 1):
            x, y = cx + dx, fire_y + dy
            if not (0 <= x < c.cols and 0 <= y < c.rows):
                continue
            dist  = math.sqrt((dx / 2.2) ** 2 + dy ** 2)
            alpha = max(0.0, 1 - dist / glow_r) ** 2.2
            alpha *= 0.5 * (0.85 + 0.15 * math.sin(t * 6 + dx * 0.3))
            if alpha < 0.015:
                continue
            c.put(x, y, blend(c.get(x, y), (210, 95, 15), alpha))


def draw_fire(c, cx, fire_y, t):
    fw = 11   # half-width at base
    fh = 26   # height in pixels

    for dy in range(fh):
        y = fire_y - dy
        if not (0 <= y < c.rows):
            continue
        height_t = dy / fh
        # animated width with layered flicker
        flicker = (
            0.13 * math.sin(t * 11.0 + dy * 0.5) +
            0.07 * math.sin(t *  7.3 + dy * 0.9) +
            0.04 * math.sin(t * 17.1 + dy * 1.4)
        )
        max_dx = int((1 - height_t ** 0.55) * fw + flicker * fw * 0.8)
        if max_dx < 0:
            continue

        for dx in range(-max_dx, max_dx + 1):
            x = cx + dx
            if not (0 <= x < c.cols):
                continue
            edge = abs(dx) / (max_dx + 0.5) if max_dx else 1.0
            core = (1 - edge ** 1.4) * (1 - height_t ** 0.65)
            core += 0.04 * math.sin(t * 14 + dy * 1.2 + dx * 1.1)
            core = max(0.0, min(1.0, core))
            if core < 0.04:
                continue

            # white → yellow → orange → deep red
            if core > 0.88:
                t2 = (core - 0.88) / 0.12
                col = (255, 255, clamp(lerp(0, 255, t2)))
            elif core > 0.62:
                t2 = (core - 0.62) / 0.26
                col = (255, clamp(lerp(140, 255, t2)), 0)
            elif core > 0.32:
                t2 = (core - 0.32) / 0.30
                col = (255, clamp(lerp(45, 140, t2)), 0)
            else:
                t2 = core / 0.32
                col = (clamp(lerp(60, 255, t2)), clamp(lerp(0, 45, t2)), 0)

            c.put(x, y, col)


def draw_logs(c, cx, log_y):
    for dx in range(-9, 10):
        c.put(cx + dx, log_y,     (75, 42, 12))
        c.put(cx + dx, log_y + 1, (55, 30,  8))
    # cross log
    for dx in range(-6, 7):
        angle_y = log_y + abs(dx) // 4
        c.put(cx + dx, angle_y, (65, 36, 10))


def draw_embers(c, embers):
    for ex, ey, age, max_age in embers:
        x, y = int(ex), int(ey)
        if not (0 <= x < c.cols and 0 <= y < c.rows):
            continue
        life = 1 - age / max_age
        if life > 0.6:
            col = (255, clamp(lerp(80, 230, (life - 0.6) / 0.4)), 0)
        elif life > 0.3:
            col = (clamp(lerp(120, 255, (life - 0.3) / 0.3)), 0, 0)
        else:
            col = (clamp(life / 0.3 * 120), 0, 0)
        c.put(x, y, col)


# ── Main ──────────────────────────────────────────────────────────────────────

def run():
    if not sys.stdout.isatty() or not sys.stdin.isatty():
        return

    cols, term_rows = os.get_terminal_size()
    rows     = term_rows * 2
    sky_h    = int(rows * 0.62)
    ground_y = int(rows * 0.82)
    fire_x   = cols // 2
    fire_y   = ground_y - 3

    # Fixed star positions
    rng   = random.Random(42)
    stars = [
        (rng.randint(0, cols - 1),
         rng.randint(0, sky_h - 1),
         rng.uniform(0, 2 * math.pi),
         rng.uniform(0.4, 2.2),
         rng.uniform(0.45, 1.0))
        for _ in range(max(35, cols * sky_h // 35))
    ]

    # Trees
    trees = []
    for x in range(4, cols - 4, max(6, cols // 5)):
        if abs(x - fire_x) > 14:
            trees.append((x,
                          rng.uniform(0, 2 * math.pi),
                          rng.randint(int(rows * 0.20), int(rows * 0.30))))

    shoot  = None  # [x, y, vx, vy, age]
    embers = []    # [x, y, age, max_age]  (vx/vy derived from age for simplicity)
    ember_states = []  # [x, y, vx, vy, age, max_age]

    # Terminal setup
    old_tty = termios.tcgetattr(sys.stdin)
    sys.stdout.write("\033[?25l\033[2J\033[H")
    sys.stdout.flush()
    tty.setcbreak(sys.stdin.fileno())

    def cleanup(sig=None, frame=None):
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_tty)
        sys.stdout.write("\033[?25h\033[0m\033[2J\033[H")
        sys.stdout.flush()

    signal.signal(signal.SIGINT,  lambda s, f: (cleanup(), sys.exit(0)))
    signal.signal(signal.SIGTERM, lambda s, f: (cleanup(), sys.exit(0)))

    t0 = time.time()

    try:
        while True:
            t = time.time() - t0
            if t >= DURATION:
                break
            if select.select([sys.stdin], [], [], 0)[0]:
                break

            c = Canvas(cols, rows)

            draw_sky(c, t)
            draw_stars(c, t, stars, sky_h)

            # # Shooting star
            # if shoot is None and random.random() < 0.014:
            #     shoot = [float(random.randint(2, cols // 2)),
            #              float(random.randint(1, sky_h // 3)),
            #              random.uniform(2.2, 3.8),
            #              random.uniform(0.35, 0.75),
            #              0]
            # if shoot is not None:
            #     draw_shooting_star(c, shoot[0], shoot[1], shoot[4], sky_h)
            #     shoot[0] += shoot[2]
            #     shoot[1] += shoot[3]
            #     shoot[4] += 1
            #     if shoot[0] >= cols or shoot[4] > 28:
            #         shoot = None

            # for tx, phase, tree_h in trees:
            #     sway = math.sin(t * 0.72 + phase)
            #     draw_tree(c, tx, ground_y - 1, tree_h, sway)

            # draw_ground(c, ground_y)
            # draw_fire_glow(c, fire_x, fire_y, t)
            # draw_logs(c, fire_x, fire_y + 1)
            # draw_fire(c, fire_x, fire_y, t)

            # Spawn embers
            if random.random() < 0.45:
                ember_states.append([
                    fire_x + random.uniform(-3, 3),
                    float(fire_y - 2),
                    random.uniform(-0.4, 0.4),
                    random.uniform(-0.35, -0.10),
                    0,
                    random.uniform(28, 65),
                ])

            for e in ember_states:
                e[0] += e[2] + 0.08 * math.sin(e[4] * 0.4)
                e[1] += e[3]
                e[4] += 1

            ember_states = [e for e in ember_states
                            if e[4] < e[5] and 0 <= int(e[1]) < rows]

            draw_embers(c, [(e[0], e[1], e[4], e[5]) for e in ember_states])

            c.render()
            time.sleep(1 / FPS)

    finally:
        cleanup()


run()
