"""Layout of Elst traced from docs/reference/kaart_elst.png (520 x 419 px).

Map pixels become world metres with to_world(): +x east, +z south, origin in
the middle of the tornado ring. Shared by the plan render and the generator.
"""
import math

SCALE = 1.05            # metres per map pixel
CENTER = (220.0, 242.0)  # map pixel at the world origin
RING_PUSH = 222.0
RING_WALL = 240.0


def to_world(p):
    return ((p[0] - CENTER[0]) * SCALE, (p[1] - CENTER[1]) * SCALE)


def to_map(p):
    return (p[0] / SCALE + CENTER[0], p[1] / SCALE + CENTER[1])


# Location: world position, yaw (door is local -z), footprint from the scene
# (x0, x1, z0, z1 in local metres) and the map blob it stands for.
LOCATIONS = {
    # The church faces the main road (R2) like a market square; its plaza
    # shrinks from 64 to 46 m so it fits next to the road and the bingo hall.
    "Kerk":       {"pos": (25.0, -109.0), "yaw": -2.146,       "box": (-23, 23, -23, 23), "color": (230, 60, 200)},
    "BingoClub":  {"pos": (-27.0, -104.0), "yaw": math.pi,      "box": (-16, 16, -28, 11), "color": (30, 60, 230)},
    "KlaasHouse": {"pos": (35.0, 3.0),    "yaw": 0.0,           "box": (-16, 16, -17, 10), "color": (150, 40, 230)},
    # Turned around: platform and rail on the east side, square to the south.
    "Station":    {"pos": (112.0, -97.0), "yaw": math.pi,       "box": (-13, 27, -43, 34), "color": (30, 200, 60)},
    "Westeraam":  {"pos": (157.0, -69.0), "yaw": math.pi,       "box": (-22, 22, -14, 26), "color": (240, 200, 0)},
    "OBCFort":    {"pos": (-172.0, 78.0), "yaw": -math.pi / 2,  "box": (-26, 26, -22, 19), "color": (230, 30, 30)},
}

# Railway: straight north-south, between the station and Westeraam.
RAIL_X = 127.0

# Main roads traced from the wide roads on the map, in map pixels.
MAIN_ROADS_PX = {
    "R1 noord":       [(167, 0), (183, 27), (200, 50), (213, 80), (222, 108), (233, 103), (253, 95), (273, 88), (295, 90)],
    "R2 doorgaand":   [(318, 0), (310, 30), (300, 70), (295, 90), (293, 120), (280, 137), (267, 157), (250, 180),
                       (233, 200), (213, 223), (203, 247), (190, 270), (173, 290), (163, 310), (160, 330), (153, 360),
                       (143, 390), (137, 419)],
    "R3 west":        [(0, 160), (17, 173), (27, 187), (40, 195), (67, 200), (97, 205), (113, 210), (133, 220),
                       (150, 223), (180, 230), (200, 233), (213, 223)],
    "R4 zuidwest":    [(97, 205), (88, 233), (85, 267), (85, 300), (90, 320), (100, 340)],
    "R5 zuidring":    [(100, 340), (133, 330), (160, 328), (200, 333), (250, 332), (277, 343), (300, 347),
                       (320, 343), (350, 323), (367, 310), (372, 307)],
    "R6 oost":        [(373, 198), (372, 233), (370, 267), (370, 307)],
    "R7 Westeraam":   [(373, 198), (400, 207), (427, 217), (450, 230), (473, 238), (500, 243), (520, 247)],
    "R11 Stationsstraat": [(267, 157), (270, 173), (290, 182), (299, 190)],
    "R12 spoorweg-oost":  [(295, 90), (317, 92), (343, 97), (357, 100)],
    "S1 station-zuid":    [(280, 193), (310, 200), (343, 205), (373, 198)],
}
MAIN_ROADS = {name: [to_world(p) for p in pts] for name, pts in MAIN_ROADS_PX.items()}

# Where the roads cross the railway (world z).
RAIL_CROSSINGS_Z = [to_world((343, 97))[1], to_world((343, 205))[1], to_world((343, 327))[1]]

# Old provisional layout, for comparison.
OLD = {"Kerk": (0, 0), "KlaasHouse": (-20, 110), "BingoClub": (-130, -20), "Station": (125, 30),
       "Westeraam": (160, -105), "OBCFort": (-130, 130)}


def footprint(name):
    """World corners of a location's footprint."""
    loc = LOCATIONS[name]
    x0, x1, z0, z1 = loc["box"]
    c, s = math.cos(loc["yaw"]), math.sin(loc["yaw"])
    out = []
    for lx, lz in ((x0, z0), (x1, z0), (x1, z1), (x0, z1)):
        # Godot yaw: x' = x cos + z sin, z' = -x sin + z cos
        out.append((loc["pos"][0] + lx * c + lz * s, loc["pos"][1] - lx * s + lz * c))
    return out


def door(name):
    loc = LOCATIONS[name]
    yaw = loc["yaw"]
    return (-math.sin(yaw), -math.cos(yaw))


def _seg_dist(p, a, b):
    ax, az = a; bx, bz = b; px, pz = p
    dx, dz = bx - ax, bz - az
    t = max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / (dx * dx + dz * dz or 1.0)))
    return math.hypot(px - ax - t * dx, pz - az - t * dz)


def _poly_edges(poly):
    return [(poly[i], poly[(i + 1) % len(poly)]) for i in range(len(poly))]


def _inside(p, poly):
    x, z = p
    hit = False
    for (ax, az), (bx, bz) in _poly_edges(poly):
        if (az > z) != (bz > z) and x < ax + (z - az) * (bx - ax) / (bz - az):
            hit = not hit
    return hit


def poly_line_gap(poly, line):
    """Smallest distance between a footprint and a polyline (0 if they cross)."""
    best = 1e9
    for a, b in zip(line, line[1:]):
        for p in (a, b):
            if _inside(p, poly):
                return 0.0
        for e0, e1 in _poly_edges(poly):
            best = min(best, _seg_dist(e0, a, b), _seg_dist(e1, a, b), _seg_dist(a, e0, e1), _seg_dist(b, e0, e1))
            # crossing check
            def ccw(p1, p2, p3):
                return (p3[1] - p1[1]) * (p2[0] - p1[0]) > (p2[1] - p1[1]) * (p3[0] - p1[0])
            if ccw(e0, a, b) != ccw(e1, a, b) and ccw(e0, e1, a) != ccw(e0, e1, b):
                return 0.0
    return best


# Roads that end at a location on purpose.
LEADS_TO = {("Station", "R11 Stationsstraat")}


def check(road_half=4.0, rail_half=3.0):
    problems = []
    names = list(LOCATIONS)
    rail = [(RAIL_X, -RING_WALL), (RAIL_X, RING_WALL)]
    for n in names:
        poly = footprint(n)
        far = max(math.hypot(*p) for p in poly)
        if far > RING_PUSH - 4:
            problems.append(f"{n}: far corner {far:.1f} m")
        for road, pts in MAIN_ROADS.items():
            gap = poly_line_gap(poly, pts) - road_half
            if gap < 2.0 and (n, road) not in LEADS_TO:
                problems.append(f"{n} vs {road}: gap {gap:.1f} m")
        gap = poly_line_gap(poly, rail) - rail_half
        if gap < 2.0 and n != "Station":  # the platform stands at the rail on purpose
            problems.append(f"{n} vs rail: gap {gap:.1f} m")
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            pa, pb = footprint(a), footprint(b)
            gap = min(poly_line_gap(pa, pb + [pb[0]]), poly_line_gap(pb, pa + [pa[0]]))
            if gap < 3.0:
                problems.append(f"{a} vs {b}: gap {gap:.1f} m")
    return problems
