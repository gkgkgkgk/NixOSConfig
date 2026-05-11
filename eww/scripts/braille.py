#!/usr/bin/env python3
"""
Usage: braille.py <name> <value> [width] [height]
Maintains a history ring-buffer and renders it as Unicode braille characters.

Each braille cell is 2 cols × 4 rows of dots.
Dots are filled from bottom-up, left column then right column.

Braille bit layout (Unicode spec):
  dot1(bit0) dot4(bit3)   ← top
  dot2(bit1) dot5(bit4)
  dot3(bit2) dot6(bit5)
  dot7(bit6) dot8(bit7)   ← bottom
"""
import sys
import os

# Bit masks for filling n dots from the bottom of a column (n = 0..4)
L = [0x00, 0x40, 0x44, 0x46, 0x47]   # left column
R = [0x00, 0x80, 0xa0, 0xb0, 0xb8]   # right column

def braille_char(l_total, r_total, chart_row, chart_height):
    """
    l_total / r_total : total dots filled (0 .. chart_height*4) for left/right columns
    chart_row         : which row of the chart (0 = top)
    """
    base = (chart_height - 1 - chart_row) * 4   # dots in rows below this cell
    lf = max(0, min(4, l_total - base))
    rf = max(0, min(4, r_total - base))
    return chr(0x2800 | L[lf] | R[rf])

def render(history, width, height):
    total_dots = height * 4
    data = list(history)
    # Left-pad with zeros so the graph fills from the right
    while len(data) < width * 2:
        data.insert(0, 0.0)
    data = data[-(width * 2):]
    dots = [round(v / 100.0 * total_dots) for v in data]

    rows = []
    for r in range(height):
        rows.append(
            ''.join(braille_char(dots[c * 2], dots[c * 2 + 1], r, height)
                    for c in range(width))
        )
    return '\n'.join(rows)

def main():
    name   = sys.argv[1] if len(sys.argv) > 1 else 'default'
    value  = float(sys.argv[2]) if len(sys.argv) > 2 else 0.0
    width  = int(sys.argv[3])   if len(sys.argv) > 3 else 20
    height = int(sys.argv[4])   if len(sys.argv) > 4 else 2

    hist_file = f'/tmp/eww-{name}-hist'
    history = []
    try:
        if os.path.exists(hist_file):
            history = [float(x) for x in open(hist_file).read().split() if x]
    except Exception:
        pass

    history.append(value)
    history = history[-(width * 2):]

    try:
        open(hist_file, 'w').write('\n'.join(str(v) for v in history))
    except Exception:
        pass

    print(render(history, width, height))

if __name__ == '__main__':
    main()
