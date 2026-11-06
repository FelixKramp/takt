#!/usr/bin/env python3
"""Zeichnet das Takt-Icon (Drehregler mit Teilstrichen) als PNG, ohne Fremdbibliotheken."""
import math, struct, sys, zlib

PANEL, TRACK, ORANGE, KNOB, INK = (216, 216, 211), (181, 181, 175), (240, 86, 10), (237, 237, 233), (27, 27, 25)

def color_at(x, y, n, scale, transparent):
    c = n / 2
    dx, dy = (x - c) / (n * scale), (y - c) / (n * scale)
    r = math.hypot(dx, dy)
    ang = (math.atan2(dx, -dy)) % (2 * math.pi)
    ticks, lit = 32, 21
    idx = ang / (2 * math.pi) * ticks
    if r < 0.235:
        pointer = abs(dx) < 0.022 and -0.215 < dy < -0.09
        return INK + (255,) if pointer else KNOB + (255,)
    if 0.33 < r < 0.46 and (idx % 1) < 0.5:
        return (ORANGE if int(idx) < lit else TRACK) + (255,)
    return (0, 0, 0, 0) if transparent else PANEL + (255,)

def render(n, scale, transparent, ss=3):
    rows = bytearray()
    for y in range(n):
        rows.append(0)
        for x in range(n):
            acc = [0, 0, 0, 0]
            for j in range(ss):
                for i in range(ss):
                    p = color_at(x + (i + .5) / ss, y + (j + .5) / ss, n, scale, transparent)
                    a = p[3]
                    acc[0] += p[0] * a; acc[1] += p[1] * a; acc[2] += p[2] * a; acc[3] += a
            a = acc[3]
            rows += bytes((acc[0] // a, acc[1] // a, acc[2] // a, a // (ss * ss))) if a else bytes(4)
    return bytes(rows)

def write_png(path, n, data):
    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d))
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', n, n, 8, 6, 0, 0, 0))
    png += chunk(b'IDAT', zlib.compress(data, 9)) + chunk(b'IEND', b'')
    open(path, 'wb').write(png)

write_png(sys.argv[1], 512, render(512, 1.0, False))
write_png(sys.argv[2], 512, render(512, 0.62, True))
if len(sys.argv) > 3:
    ORANGE = INK
    write_png(sys.argv[3], 512, render(512, 1.0, False))
