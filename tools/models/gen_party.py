"""Builds scenes/world/props/PartyDecor.tscn: the party on the church square
once Amber is beaten.

Run from the project root: python3 tools/models/gen_party.py

In the local space of scenes/world/locations/Kerk.tscn (the church door
faces -Z, the nave stands from x -7 to 7): strings of glowing bulbs on poles
around the square in front of the door, with bunting under them, a long
table with protein shakes, a little stage with two speakers and a disco
ball, and a banner "ELST IS VRIJ!" on the tower.
"""
import math
import sys
import pathlib

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from model_builder import Model, add, scale, sub  # noqa: E402

POLE = (0.22, 0.16, 0.12)
WIRE = (0.1, 0.1, 0.1)
BULBS = [(1.0, 0.62, 0.15), (0.75, 0.35, 1.0), (1.0, 0.85, 0.35), (1.0, 0.95, 0.85)]
FLAGS = [(0.95, 0.55, 0.12), (0.6, 0.25, 0.85), (0.95, 0.8, 0.25), (0.92, 0.92, 0.9)]
WOOD = (0.48, 0.32, 0.18)
CLOTH = (0.55, 0.22, 0.75)
SHAKE = (0.92, 0.86, 0.74)
STAGE = (0.3, 0.22, 0.16)
SPEAKER = (0.1, 0.1, 0.11)
CHROME = (0.85, 0.86, 0.9)
GOLD = (0.95, 0.76, 0.25)

m = Model("PartyDecor")
POLE_HEIGHT = 4.6
POLES = [(-15, -23), (-15, -14), (-15, -5), (15, -23), (15, -14), (15, -5), (-8, -23), (8, -23)]
for n, (x, z) in enumerate(POLES):
    m.box(".", f"Pole{n}", (x, POLE_HEIGHT / 2, z), (0.16, POLE_HEIGHT, 0.16), POLE)
    m.box(".", f"PoleCap{n}", (x, POLE_HEIGHT + 0.08, z), (0.24, 0.12, 0.24), GOLD, metal=True)

# Strings of lights between neighbouring poles, sagging in the middle.
STRINGS = [(0, 1), (1, 2), (3, 4), (4, 5), (0, 6), (6, 7), (7, 3)]
bulb_count = 0
for a, b in STRINGS:
    pa = (POLES[a][0], POLE_HEIGHT - 0.1, POLES[a][1])
    pb = (POLES[b][0], POLE_HEIGHT - 0.1, POLES[b][1])
    length = math.dist(pa, pb)
    steps = max(int(length / 0.9), 2)
    points = []
    for i in range(steps + 1):
        t = i / steps
        p = add(pa, scale(sub(pb, pa), t))
        points.append((p[0], p[1] - math.sin(t * math.pi) * 0.9, p[2]))
    for i in range(steps):
        m.bone(".", f"Wire{a}_{b}_{i}", points[i], points[i + 1], 0.03, 0.03, WIRE)
        if 0 < i:
            x, y, z = points[i]
            m.box(".", f"Bulb{bulb_count}", (x, y - 0.12, z), (0.14, 0.18, 0.14), BULBS[bulb_count % 4], glow=3.0)
            m.prism(".", f"Flag{bulb_count}", (x + (points[i + 1][0] - x) * 0.5, y - 0.25, z + (points[i + 1][2] - z) * 0.5),
                    (0.36, 0.34, 0.02), FLAGS[bulb_count % 4], rot=(math.pi, math.atan2(points[i + 1][0] - x, points[i + 1][2] - z) + math.pi / 2, 0))
            bulb_count += 1

# A long table with shakes on the west side of the square.
m.box(".", "TableTop", (-12, 0.85, -12), (1.4, 0.08, 7.0), WOOD)
m.box(".", "TableCloth", (-12, 0.9, -12), (1.5, 0.02, 7.1), CLOTH)
for n, z in enumerate((-15, -9)):
    m.box(".", f"TableLegs{n}", (-12, 0.42, z), (1.2, 0.84, 0.1), WOOD)
for n in range(10):
    m.cone(".", f"Shake{n}", (-12 + (n % 2 - 0.5) * 0.6, 0.91, -15 + n * 0.65), (-12 + (n % 2 - 0.5) * 0.6, 1.15, -15 + n * 0.65),
           0.06, SHAKE, sides=6, top=0.075)
m.label(".", "ShakeSign", (-12, 1.7, -12), "GRATIS EIWITSHAKES", GOLD, size=64, pixel=0.012, rot=(0, -math.pi / 2, 0))

# A little stage with speakers and a disco ball on the east side.
m.box(".", "Stage", (12, 0.25, -12), (5.0, 0.5, 4.0), STAGE)
m.box(".", "StageEdge", (12, 0.52, -12), (5.1, 0.06, 4.1), GOLD, metal=True)
for n, z in enumerate((-13.6, -10.4)):
    m.box(".", f"Speaker{n}", (13.6, 1.25, z), (0.8, 1.5, 0.8), SPEAKER)
    m.box(".", f"Woofer{n}", (13.19, 1.05, z), (0.02, 0.5, 0.5), CHROME, metal=True)
m.box(".", "DiscoBall", (12, 4.2, -12), (0.6, 0.6, 0.6), CHROME, rot=(0.6, 0.6, 0), metal=True, glow=1.0)
m.box(".", "DiscoWire", (12, 4.55, -12), (0.02, 0.4, 0.02), WIRE)

# The banner on the tower, above the old sign.
m.box(".", "BannerCloth", (0, 9.6, -17.86), (7.6, 1.6, 0.06), CLOTH)
m.label(".", "Banner", (0, 9.6, -17.9), "ELST IS VRIJ!", GOLD, size=96, pixel=0.02, rot=(0, math.pi, 0))
m.write("scenes/world/props/PartyDecor.tscn")
