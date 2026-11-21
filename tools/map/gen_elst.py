"""Builds scenes/world/Elst.tscn and data/world/elst_ground.png from the map.

Run from the project root:
    python3 tools/map/gen_elst.py              # write the scene and the raster
    python3 tools/map/gen_elst.py --preview p.png   # only draw a top view

The layout (scale, locations, main roads, rail) comes from layout.py. The land
use (streets, gardens, parks, water, open land) is read from
docs/reference/kaart_elst.png; without that file (it is not in the repo) the
ground raster data/world/elst_ground.png, made from it, is used, which gives
the same town. Parts of the scene that are not generated (sky,
tornado, ground collider, navigation settings) are copied from the current
Elst.tscn, so the script can run again after edits to those parts.
"""
import math
import pathlib
import random
import sys
from collections import deque

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import layout as L  # noqa: E402

MAP_PATH = pathlib.Path("docs/reference/kaart_elst.png")
SCENE_PATH = pathlib.Path("scenes/world/Elst.tscn")
RASTER_PATH = pathlib.Path("data/world/elst_ground.png")
SIZE = 488            # raster cells of 1 m, from -244 to 244
HALF = SIZE // 2
SEED = 7
HOUSE_RADIUS = 214.0  # no houses or trees in the wind of the tornado
TREE_RADIUS = 218.0

# Palette indices of the ground raster.
FIELD_A, FIELD_B, FIELD_C, FIELD_D = 0, 1, 2, 3
YARD, STREET, MAIN, PARK, WATER, BALLAST, PAVING = 4, 5, 6, 7, 8, 9, 10
FIELDS = (FIELD_A, FIELD_B, FIELD_C, FIELD_D)
PALETTE = [
    (0.46, 0.6, 0.32),   # meadow
    (0.53, 0.66, 0.35),  # light meadow
    (0.74, 0.66, 0.36),  # crop
    (0.5, 0.4, 0.28),    # ploughed
    (0.44, 0.5, 0.33),   # gardens
    (0.56, 0.54, 0.5),   # street
    (0.3, 0.3, 0.32),    # main road
    (0.33, 0.55, 0.27),  # park
    (0.26, 0.45, 0.58),  # water
    (0.42, 0.38, 0.34),  # ballast
    (0.62, 0.6, 0.55),   # paving
]
WALLS = [(0.62, 0.32, 0.24), (0.55, 0.28, 0.22), (0.74, 0.6, 0.46), (0.82, 0.76, 0.64), (0.48, 0.3, 0.26),
         (0.66, 0.5, 0.38), (0.86, 0.84, 0.78), (0.58, 0.42, 0.3)]
ROOFS = [(0.3, 0.28, 0.3), (0.58, 0.24, 0.17), (0.22, 0.22, 0.24), (0.46, 0.2, 0.16), (0.35, 0.3, 0.28)]
MAIN_HALF_WIDTH = 4.0
BALLAST_HALF_WIDTH = 2.5

# Enemies outside: three laag drillers guard Amber's depot and the square of
# the station, three drillers the courtyard of Westeraam, facing the way the
# player comes in (south, yaw about pi). (name, scene id, x, z, yaw)
ENEMIES = [
    ("LowDriller1", "90_low_driller", 99.0, -101.0, 2.8),
    ("LowDriller2", "90_low_driller", 93.0, -102.0, 3.5),
    ("LowDriller3", "90_low_driller", 104.0, -79.0, 3.0),
    ("Driller1", "91_driller", 160.0, -68.0, 2.9),
    ("Driller2", "91_driller", 152.0, -69.0, 3.4),
    ("Driller3", "91_driller", 157.0, -59.0, 3.1),
    # Kakkers on the pitch inside OBC Elst Fort, well inside its walls.
    ("Voetballer1", "92_voetballer", -164.0, 72.0, 1.6),
    ("Voetballer2", "92_voetballer", -162.0, 84.0, 1.4),
    ("Fatbiker1", "93_fatbiker", -168.0, 78.0, 1.5),
    # Grandmas on the car park of the Bingo Club, well inside its footprint.
    ("BingoOma1", "94_oma", -32.0, -86.0, 3.1),
    ("BingoOma2", "94_oma", -22.0, -88.0, 3.0),
    ("BingoOpa1", "95_opa", -27.0, -82.0, 3.1),
]
# Open spots without houses, where the first patrols stood. Fixed, because
# the houses fill the town in one random pass: moving a spot reshuffles
# every house and tree.
CLEAR_SPOTS = [(76.0, -68.0), (80.0, -62.0), (72.0, -61.0), (146.0, -28.0), (152.0, -24.0), (-164.0, 72.0), (-162.0, 84.0),
               (-168.0, 78.0), (-32.0, -86.0), (-22.0, -88.0), (-27.0, -82.0)]
# Areas that change once liberated: node name, flag, the enemies (from ENEMIES)
# that patrol it until then, and the villagers (x, z) that come after, with
# their lines and a warm light in the middle.
AREAS = [
    ("KlaasArea", "q1_reported", [], [(30.0, -22.0), (40.0, -22.0), (35.0, -27.0)], (35.0, -22.0),
     ["Klaas is weer terug!", "Heb je Klaas al zien flexen?", "Dank je wel!", "Het is weer gezellig in de straat."]),
    ("StationArea", "station_cleared", ["LowDriller1", "LowDriller2", "LowDriller3"],
     [(104.0, -60.0), (112.0, -57.0), (118.0, -62.0)], (110.0, -60.0),
     ["De treinen rijden weer!", "Eindelijk weer een trein naar Nijmegen.", "Geen eiwitshakes meer voor Amber!", "Dank je wel!"]),
    ("WesteraamArea", "boss_vape_koning", ["Driller1", "Driller2", "Driller3"],
     [(152.0, -66.0), (160.0, -64.0), (156.0, -60.0), (162.0, -70.0)], (157.0, -66.0),
     ["Geen vapewolken meer in de portiek!", "De Vape-koning is weg. Ik kan weer ademen.", "Westeraam is weer van ons!", "Dank je wel!"]),
    ("OBCArea", "boss_fatbike_kindje", ["Voetballer1", "Voetballer2", "Fatbiker1"],
     [(-166.0, 72.0), (-160.0, 80.0), (-168.0, 85.0), (-158.0, 74.0)], (-164.0, 78.0),
     ["Het OBC is weer van ons!", "Eindelijk kan ik weer naar school. Geloof ik.", "Geen voetballen meer tegen mijn hoofd!", "Dank je wel!"]),
    ("BingoArea", "boss_grumpy_oma", ["BingoOma1", "BingoOma2", "BingoOpa1"],
     [(-30.0, -84.0), (-24.0, -86.0), (-27.0, -90.0)], (-27.0, -86.0),
     ["BINGO! Echt waar deze keer!", "Eindelijk weer een gezellige bingoavond.", "Oma is weer lief.", "Dank je wel!"]),
]
LOCATION_SCENES = {"Kerk": "5_res", "KlaasHouse": "6_res", "BingoClub": "7_res", "Station": "8_res",
                   "Westeraam": "9_res", "OBCFort": "10_res"}
START_LOCAL = (0.0, -11.0)  # the Start marker inside KlaasHouse.tscn


def cell_center(i, j):
    return (i - HALF + 0.5, j - HALF + 0.5)


def world_cell(x, z):
    return (int(math.floor(x + HALF)), int(math.floor(z + HALF)))


def in_raster(i, j):
    return 0 <= i < SIZE and 0 <= j < SIZE


def seg_dist(p, a, b):
    return L._seg_dist(p, a, b)


# --- Land use ---------------------------------------------------------------

def classify_map():
    """Class per map pixel: F field, Y yard, S street, P park, W water."""
    im = Image.open(MAP_PATH).convert("RGB")
    w, h = im.size
    px = im.load()
    road = Image.new("L", (w, h), 0)
    rp = road.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if r > 185 and r - g > 22 and r - b > 50 and r + g + b < 650:
                rp[x, y] = 255
    # Wide roads are drawn again from the traced main roads, so drop them here.
    thick = road.filter(ImageFilter.MinFilter(5)).filter(ImageFilter.MaxFilter(7)).load()
    out = {}
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if max(r, g, b) - min(r, g, b) > 150:      # coloured location blob
                c = "Y"
            elif b > 150 and g > 170 and r < 170:
                c = "W"
            elif g > 160 and b < 130 and abs(r - g) < 25 and r < 215:
                c = "P"
            elif rp[x, y]:
                c = "Y" if thick[x, y] else "S"
            elif r >= 243:
                c = "Y"
            else:
                c = "F"
            out[(x, y)] = c
    return out, w, h


def field_variant(x, z, rng_seeds):
    """Patchwork of fields: the variant of the nearest seed on a 48 m lattice."""
    gx, gz = math.floor(x / 48.0), math.floor(z / 48.0)
    best, best_d = FIELD_A, 1e9
    for dx in (-1, 0, 1):
        for dz in (-1, 0, 1):
            seed = rng_seeds.get((gx + dx, gz + dz))
            if seed is None:
                rnd = random.Random(hash((gx + dx, gz + dz, SEED)))
                seed = ((gx + dx + rnd.random()) * 48.0, (gz + dz + rnd.random()) * 48.0, rnd.choice(FIELDS))
                rng_seeds[(gx + dx, gz + dz)] = seed
            d = (seed[0] - x) ** 2 + (seed[1] - z) ** 2
            if d < best_d:
                best, best_d = seed[2], d
    return best


def local_point(name, x, z):
    """World point in the local frame of a location."""
    loc = L.LOCATIONS[name]
    dx, dz = x - loc["pos"][0], z - loc["pos"][1]
    c, s = math.cos(loc["yaw"]), math.sin(loc["yaw"])
    return (dx * c - dz * s, dx * s + dz * c)


def in_location(x, z, margin):
    for name, loc in L.LOCATIONS.items():
        lx, lz = local_point(name, x, z)
        x0, x1, z0, z1 = loc["box"]
        if x0 - margin <= lx <= x1 + margin and z0 - margin <= lz <= z1 + margin:
            return True
    return False


def door_aprons():
    """A clear spot in front of every location's door."""
    out = []
    for name, loc in L.LOCATIONS.items():
        dx, dz = L.door(name)
        reach = -loc["box"][2] + 7.0
        out.append((loc["pos"][0] + dx * reach, loc["pos"][1] + dz * reach))
    return out


def build_raster():
    if not MAP_PATH.exists():
        # The ground raster in the repo was made from the map; without the
        # map it is the source, so the town comes out the same.
        print("no", MAP_PATH, "- using", RASTER_PATH)
        return bytearray(Image.open(RASTER_PATH).convert("L").tobytes())
    classes, mw, mh = classify_map()
    seeds = {}
    grid = bytearray(SIZE * SIZE)
    code = {"Y": YARD, "S": STREET, "P": PARK, "W": WATER}
    for j in range(SIZE):
        for i in range(SIZE):
            x, z = cell_center(i, j)
            mx, my = L.to_map((x, z))
            c = classes.get((int(mx), int(my)), "F") if 0 <= mx < mw and 0 <= my < mh else "F"
            if math.hypot(x, z) > L.RING_WALL:
                c = "F"
            grid[j * SIZE + i] = code[c] if c in code else field_variant(x, z, seeds)
    # Remove specks of park and water that are only map noise.
    for j in range(2, SIZE - 2):
        for i in range(2, SIZE - 2):
            v = grid[j * SIZE + i]
            if v in (PARK, WATER):
                same = sum(grid[(j + dj) * SIZE + i + di] == v for di in (-1, 0, 1) for dj in (-1, 0, 1))
                if same < 4:
                    grid[j * SIZE + i] = YARD
            elif v in FIELDS:
                # Bits of open land between houses are gardens, not fields.
                same = sum(grid[(j + dj) * SIZE + i + di] in FIELDS for di in (-2, -1, 0, 1, 2) for dj in (-2, -1, 0, 1, 2))
                if same < 13:
                    grid[j * SIZE + i] = YARD
    # Main roads, the railway and paved ground under the locations.
    for pts in L.MAIN_ROADS.values():
        for a, b in zip(pts, pts[1:]):
            i0, j0 = world_cell(min(a[0], b[0]) - 5, min(a[1], b[1]) - 5)
            i1, j1 = world_cell(max(a[0], b[0]) + 5, max(a[1], b[1]) + 5)
            for j in range(max(j0, 0), min(j1 + 1, SIZE)):
                for i in range(max(i0, 0), min(i1 + 1, SIZE)):
                    if seg_dist(cell_center(i, j), a, b) <= MAIN_HALF_WIDTH:
                        grid[j * SIZE + i] = MAIN
    for j in range(SIZE):
        for i in range(SIZE):
            x, z = cell_center(i, j)
            if abs(x - L.RAIL_X) <= BALLAST_HALF_WIDTH and grid[j * SIZE + i] != MAIN and math.hypot(x, z) < L.RING_WALL:
                grid[j * SIZE + i] = BALLAST
            elif in_location(x, z, 2.0):
                grid[j * SIZE + i] = PAVING
    return grid


# --- Houses, trees and water ------------------------------------------------

def road_distance(grid):
    """Distance in metres from every cell to the nearest street or main road."""
    inf = 1e9
    dist = [inf] * (SIZE * SIZE)
    src = [None] * (SIZE * SIZE)
    queue = deque()
    for idx, v in enumerate(grid):
        if v in (STREET, MAIN):
            dist[idx] = 0.0
            src[idx] = (idx % SIZE, idx // SIZE)
            queue.append(idx)
    while queue:
        idx = queue.popleft()
        i, j = idx % SIZE, idx // SIZE
        si, sj = src[idx]
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            ni, nj = i + di, j + dj
            if not in_raster(ni, nj):
                continue
            nidx = nj * SIZE + ni
            d = math.hypot(ni - si, nj - sj)
            if d < dist[nidx] - 1e-6:
                dist[nidx] = d
                src[nidx] = (si, sj)
                if d < 14:
                    queue.append(nidx)
    return dist


def blocked_spot(x, z, extra):
    if math.hypot(x, z) > HOUSE_RADIUS:
        return True
    if abs(x - L.RAIL_X) < 7.0 or in_location(x, z, 4.0):
        return True
    for ax, az in door_aprons():
        if math.hypot(x - ax, z - az) < 10.0:
            return True
    for ex, ez in CLEAR_SPOTS:
        if math.hypot(x - ex, z - ez) < 7.0 + extra:
            return True
    return False


def rect_cells(x, z, yaw, w, d, pad):
    """Cells under a rectangle centred on (x, z), width w along local x."""
    c, s = math.cos(yaw), math.sin(yaw)
    out = set()
    steps_u = int(math.ceil(w + 2 * pad)) + 1
    steps_v = int(math.ceil(d + 2 * pad)) + 1
    for a in range(steps_u):
        u = -w / 2 - pad + (w + 2 * pad) * a / max(steps_u - 1, 1)
        for b in range(steps_v):
            v = -d / 2 - pad + (d + 2 * pad) * b / max(steps_v - 1, 1)
            out.add(world_cell(x + u * c + v * s, z - u * s + v * c))
    return out


def place_houses(grid, dist, rng):
    """Houses along the streets: first a pass of normal houses, then smaller
    ones in the gaps that are left."""
    occupied = bytearray(SIZE * SIZE)
    houses = []
    for widths, depths, heights in (((5.5, 8.0), (5.5, 7.0), (3.8, 4.2, 4.6, 5.2)),
                                    ((4.5, 6.0), (4.8, 6.0), (3.4, 3.7, 4.0))):
        _house_pass(grid, dist, rng, occupied, houses, widths, depths, heights)
    return houses, occupied


def _house_pass(grid, dist, rng, occupied, houses, widths, depths, heights):
    candidates = [idx for idx, v in enumerate(grid) if v == YARD and 2.0 <= dist[idx] <= 6.5]
    rng.shuffle(candidates)
    for idx in candidates:
        if len(houses) >= 480:
            break
        i, j = idx % SIZE, idx // SIZE
        if not (2 <= i < SIZE - 2 and 2 <= j < SIZE - 2) or occupied[idx]:
            continue
        x, z = cell_center(i, j)
        if blocked_spot(x, z, 0.0):
            continue
        w, d = rng.uniform(*widths), rng.uniform(*depths)
        if not (d / 2 + 0.3 <= dist[idx] <= d / 2 + 2.6):
            continue
        # Face the street: against the slope of the distance field.
        gx = dist[j * SIZE + i + 2] - dist[j * SIZE + i - 2]
        gz = dist[(j + 2) * SIZE + i] - dist[(j - 2) * SIZE + i]
        if abs(gx) + abs(gz) < 0.5:
            continue
        yaw = math.atan2(gx, gz)  # door (local -z) points down the slope
        cells = rect_cells(x, z, yaw, w, d, 0.0)
        if any(not in_raster(ci, cj) or grid[cj * SIZE + ci] != YARD or occupied[cj * SIZE + ci] for ci, cj in cells):
            continue
        for ci, cj in rect_cells(x, z, yaw, w, d, 0.7):
            if in_raster(ci, cj):
                occupied[cj * SIZE + ci] = 1
        height = rng.choice(heights)
        houses.append({"pos": (x, z), "yaw": yaw, "size": (w, height, d), "roof": rng.uniform(1.8, 3.0),
                       "wall": rng.choice(WALLS), "roof_color": rng.choice(ROOFS)})


def place_trees(grid, dist, occupied, rng):
    trees = []
    taken = []

    def free(x, z, spacing):
        return all((x - tx) ** 2 + (z - tz) ** 2 >= spacing * spacing for tx, tz in taken)

    def scatter(kinds, spacing, limit, pick, leafy_share, scale):
        cells = [idx for idx, v in enumerate(grid) if v in kinds]
        rng.shuffle(cells)
        count = 0
        for idx in cells:
            if count >= limit:
                break
            if occupied[idx] or not pick(idx):
                continue
            i, j = idx % SIZE, idx // SIZE
            x, z = cell_center(i, j)
            x += rng.uniform(-0.4, 0.4)
            z += rng.uniform(-0.4, 0.4)
            if math.hypot(x, z) > TREE_RADIUS or blocked_spot(x, z, 0.0) and math.hypot(x, z) <= HOUSE_RADIUS:
                continue
            if abs(x - L.RAIL_X) < 6.0 or in_location(x, z, 3.0):
                continue
            if not free(x, z, spacing):
                continue
            taken.append((x, z))
            trees.append({"pos": (x, z), "yaw": rng.uniform(0, math.tau), "scale": rng.uniform(*scale),
                          "pine": rng.random() > leafy_share})
            count += 1

    scatter((PARK,), 6.5, 200, lambda idx: dist[idx] >= 2.0, 0.8, (1.0, 1.45))
    scatter((YARD,), 9.0, 110, lambda idx: dist[idx] >= 3.0, 0.85, (0.85, 1.2))
    scatter(FIELDS, 16.0, 120, lambda idx: dist[idx] >= 4.0, 0.55, (1.0, 1.5))
    return trees


def water_boxes(grid):
    """Rectangles that cover the larger ponds inside the ring, as colliders."""
    seen = bytearray(SIZE * SIZE)
    keep = bytearray(SIZE * SIZE)
    for start, v in enumerate(grid):
        if v != WATER or seen[start]:
            continue
        comp = [start]
        seen[start] = 1
        k = 0
        while k < len(comp):
            idx = comp[k]
            k += 1
            i, j = idx % SIZE, idx // SIZE
            for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ni, nj = i + di, j + dj
                if in_raster(ni, nj) and grid[nj * SIZE + ni] == WATER and not seen[nj * SIZE + ni]:
                    seen[nj * SIZE + ni] = 1
                    comp.append(nj * SIZE + ni)
        inside = [idx for idx in comp if math.hypot(*cell_center(idx % SIZE, idx // SIZE)) < L.RING_WALL - 2]
        if len(comp) >= 150 and inside:
            for idx in inside:
                keep[idx] = 1
    boxes = []
    done = bytearray(SIZE * SIZE)
    for j in range(SIZE):
        i = 0
        while i < SIZE:
            idx = j * SIZE + i
            if not keep[idx] or done[idx]:
                i += 1
                continue
            i_end = i + 1
            while i_end < SIZE and keep[j * SIZE + i_end] and not done[j * SIZE + i_end]:
                i_end += 1
            j_end = j + 1
            while j_end < SIZE and all(keep[j_end * SIZE + c] and not done[j_end * SIZE + c] for c in range(i, i_end)):
                j_end += 1
            for r in range(j, j_end):
                for c in range(i, i_end):
                    done[r * SIZE + c] = 1
            x0, z0 = i - HALF, j - HALF
            boxes.append(((x0 + (i_end - i) / 2, z0 + (j_end - j) / 2), (i_end - i, j_end - j)))
            i = i_end
    return boxes


# --- Scene ------------------------------------------------------------------

def f(v):
    s = f"{v:.3f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def vec(*v):
    return "Vector3(" + ", ".join(f(c) for c in v) + ")"


def col(c):
    return f"Color({f(c[0])}, {f(c[1])}, {f(c[2])}, 1)"


def block(text, header):
    """A block of the current scene from its header line to the blank line."""
    start = text.index(header + "\n")
    end = text.find("\n\n", start)
    return text[start:end if end >= 0 else len(text)].rstrip("\n")


def outskirt_trees(rng):
    """Trees beyond the tornado, on the skirt of the ground, so the land seems
    to go on into the fog. A rng of its own keeps the town as it is."""
    trees = []
    while len(trees) < 160:
        angle, radius = rng.uniform(0, math.tau), rng.uniform(250.0, 340.0)
        x, z = math.cos(angle) * radius, math.sin(angle) * radius
        if abs(x - L.RAIL_X) < 9.0:
            continue
        trees.append({"pos": (x, z), "yaw": rng.uniform(0, math.tau), "scale": rng.uniform(1.0, 1.6), "pine": rng.random() < 0.5})
    return trees


def outskirt_roads():
    """Main roads that reach the tornado go on beyond it: (centre, yaw, length)."""
    roads = []
    for pts in L.MAIN_ROADS.values():
        for end, prev in ((pts[0], pts[1]), (pts[-1], pts[-2])):
            if math.hypot(*end) < 200.0:
                continue
            dx, dz = end[0] - prev[0], end[1] - prev[1]
            n = math.hypot(dx, dz)
            dx, dz = dx / n, dz / n
            length = 160.0
            roads.append(((end[0] + dx * length / 2, end[1] + dz * length / 2), math.atan2(dx, dz), length))
    return roads


def write_scene(houses, trees, boxes):
    old = SCENE_PATH.read_text()
    keep_sub = [block(old, h) for h in (
        '[sub_resource type="ProceduralSkyMaterial" id="ProceduralSkyMaterial_1"]',
        '[sub_resource type="Sky" id="Sky_2"]',
        '[sub_resource type="Environment" id="Environment_3"]',
        '[sub_resource type="BoxShape3D" id="BoxShape3D_4"]',
        '[sub_resource type="NavigationMesh" id="NavigationMesh_61"]')]
    keep_nodes = {name: block(old, h) for name, h in (
        ("root", '[node name="Elst" type="Node3D"]'),
        ("env", '[node name="WorldEnvironment" type="WorldEnvironment" parent="."]'),
        ("sun", '[node name="Sun" type="DirectionalLight3D" parent="."]'),
        ("tornado", '[node name="Tornado" parent="." instance=ExtResource("2_res")]'),
        ("ground", '[node name="Ground" type="StaticBody3D" parent="." groups=["navigation_source"]]'),
        ("ground_shape", '[node name="CollisionShape3D" type="CollisionShape3D" parent="Ground"]'),
        ("nav", '[node name="Navigation" type="NavigationRegion3D" parent="."]'))}
    out = ["[gd_scene format=3]", ""]
    ext = [
        ("Script", "res://scenes/world/game_world.gd", "1_res"),
        ("PackedScene", "res://scenes/world/Tornado.tscn", "2_res"),
        ("PackedScene", "res://scenes/world/props/House.tscn", "3_res"),
        ("PackedScene", "res://scenes/world/props/TreeProp.tscn", "4_res"),
        ("PackedScene", "res://scenes/world/locations/Kerk.tscn", "5_res"),
        ("PackedScene", "res://scenes/world/locations/KlaasHouse.tscn", "6_res"),
        ("PackedScene", "res://scenes/world/locations/BingoClub.tscn", "7_res"),
        ("PackedScene", "res://scenes/world/locations/Station.tscn", "8_res"),
        ("PackedScene", "res://scenes/world/locations/Westeraam.tscn", "9_res"),
        ("PackedScene", "res://scenes/world/locations/OBCFort.tscn", "10_res"),
        ("Script", "res://scenes/world/runtime_navigation_region.gd", "11_res"),
        ("PackedScene", "res://scenes/player/Player.tscn", "12_res"),
        ("Script", "res://scripts/world/ground_map.gd", "13_res"),
        ("Image", "res://" + RASTER_PATH.as_posix(), "14_res"),
        ("Script", "res://scripts/world/liberated_area.gd", "15_res"),
        ("PackedScene", "res://scenes/npcs/Villager.tscn", "16_res"),
        ("PackedScene", "res://scenes/enemies/LowDriller.tscn", "90_low_driller"),
        ("PackedScene", "res://scenes/enemies/Driller.tscn", "91_driller"),
        ("PackedScene", "res://scenes/enemies/Voetballer.tscn", "92_voetballer"),
        ("PackedScene", "res://scenes/enemies/Fatbiker.tscn", "93_fatbiker"),
        ("PackedScene", "res://scenes/enemies/BozeOma.tscn", "94_oma"),
        ("PackedScene", "res://scenes/enemies/BingoOpa.tscn", "95_opa"),
    ]
    for kind, path, rid in ext:
        out.append(f'[ext_resource type="{kind}" path="{path}" id="{rid}"]')
    out.append("")
    for b in keep_sub:
        out += [b, ""]
    rail_len = 760.0  # on through the tornado, into the fog
    out += ['[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_ballast"]', "albedo_color = " + col(PALETTE[BALLAST]), "",
            '[sub_resource type="BoxMesh" id="BoxMesh_ballast"]', 'material = SubResource("StandardMaterial3D_ballast")',
            f"size = {vec(4.4, 0.24, rail_len)}", "",
            '[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_rail"]', "albedo_color = Color(0.55, 0.55, 0.58, 1)",
            "metallic = 0.6", "roughness = 0.4", "",
            '[sub_resource type="BoxMesh" id="BoxMesh_rail"]', 'material = SubResource("StandardMaterial3D_rail")',
            f"size = {vec(0.12, 0.16, rail_len)}", "",
            '[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_planks"]', "albedo_color = Color(0.45, 0.33, 0.22, 1)", "",
            '[sub_resource type="BoxMesh" id="BoxMesh_crossing"]', 'material = SubResource("StandardMaterial3D_planks")',
            f"size = {vec(5.0, 0.12, 2 * MAIN_HALF_WIDTH)}", "",
            '[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_road"]', "albedo_color = " + col(PALETTE[MAIN]), "",
            '[sub_resource type="BoxMesh" id="BoxMesh_road"]', 'material = SubResource("StandardMaterial3D_road")',
            f"size = {vec(2 * MAIN_HALF_WIDTH, 0.06, 1)}", ""]
    for n, (_, size) in enumerate(boxes):
        out += [f'[sub_resource type="BoxShape3D" id="BoxShape3D_water{n}"]', f"size = {vec(size[0], 2, size[1])}", ""]
    out += [keep_nodes["root"], "", keep_nodes["env"], "", keep_nodes["sun"], "", keep_nodes["tornado"], "",
            keep_nodes["ground"], "", keep_nodes["ground_shape"], ""]
    palette = ", ".join(f"{f(c[0])}, {f(c[1])}, {f(c[2])}, 1" for c in PALETTE)
    out += ['[node name="Map" type="Node3D" parent="Ground"]', 'script = ExtResource("13_res")',
            'raster = ExtResource("14_res")', f"palette = PackedColorArray({palette})",
            f"skirt_color = {col(PALETTE[FIELD_A])}", ""]
    out += ['[node name="Railway" type="Node3D" parent="."]', ""]
    out += ['[node name="Ballast" type="MeshInstance3D" parent="Railway"]', f"position = {vec(L.RAIL_X, 0.12, 0)}",
            'mesh = SubResource("BoxMesh_ballast")', ""]
    for name, dx in (("RailLeft", -0.72), ("RailRight", 0.72)):
        out += [f'[node name="{name}" type="MeshInstance3D" parent="Railway"]', f"position = {vec(L.RAIL_X + dx, 0.32, 0)}",
                'mesh = SubResource("BoxMesh_rail")', ""]
    for n, cz in enumerate(L.RAIL_CROSSINGS_Z, 1):
        out += [f'[node name="Crossing{n}" type="MeshInstance3D" parent="Railway"]', f"position = {vec(L.RAIL_X, 0.36, cz)}",
                'mesh = SubResource("BoxMesh_crossing")', ""]
    if boxes:
        out += ['[node name="Water" type="StaticBody3D" parent="." groups=["navigation_source"]]', ""]
        for n, (center, _) in enumerate(boxes):
            out += [f'[node name="Shape{n}" type="CollisionShape3D" parent="Water"]', f"position = {vec(center[0], 1, center[1])}",
                    f'shape = SubResource("BoxShape3D_water{n}")', ""]
    out += ['[node name="Houses" type="Node3D" parent="." groups=["navigation_source"]]', ""]
    for n, h in enumerate(houses, 1):
        out += [f'[node name="House{n:03d}" parent="Houses" instance=ExtResource("3_res")]',
                f"position = {vec(h['pos'][0], 0, h['pos'][1])}", f"rotation = {vec(0, h['yaw'], 0)}",
                f"size = {vec(*h['size'])}", f"roof_height = {f(h['roof'])}", f"wall_color = {col(h['wall'])}",
                f"roof_color = {col(h['roof_color'])}", ""]
    out += ['[node name="Trees" type="Node3D" parent="." groups=["navigation_source"]]', ""]
    for n, t in enumerate(trees, 1):
        lines = [f'[node name="Tree{n:03d}" parent="Trees" instance=ExtResource("4_res")]',
                 f"position = {vec(t['pos'][0], 0, t['pos'][1])}", f"rotation = {vec(0, t['yaw'], 0)}",
                 f"scale = {vec(t['scale'], t['scale'], t['scale'])}"]
        if t["pine"]:
            lines.append("kind = 0")
        out += lines + [""]
    out += ['[node name="OutskirtRoads" type="Node3D" parent="."]', ""]
    for n, ((x, z), yaw, length) in enumerate(outskirt_roads(), 1):
        out += [f'[node name="Road{n}" type="MeshInstance3D" parent="OutskirtRoads"]', f"position = {vec(x, 0.03, z)}",
                f"rotation = {vec(0, yaw, 0)}", f"scale = {vec(1, 1, length)}", 'mesh = SubResource("BoxMesh_road")', ""]
    out += ['[node name="Locations" type="Node3D" parent="." groups=["navigation_source"]]', ""]
    for name, loc in L.LOCATIONS.items():
        out += [f'[node name="{name}" parent="Locations" instance=ExtResource("{LOCATION_SCENES[name]}")]',
                f"position = {vec(loc['pos'][0], 0, loc['pos'][1])}"]
        if abs(loc["yaw"]) > 1e-6:
            out.append(f"rotation = {vec(0, loc['yaw'], 0)}")
        out.append("")
    out += [keep_nodes["nav"], ""]
    klaas = L.LOCATIONS["KlaasHouse"]
    sx, sz = klaas["pos"][0] + START_LOCAL[0], klaas["pos"][1] + START_LOCAL[1]
    out += ['[node name="Player" parent="." instance=ExtResource("12_res")]', f"position = {vec(sx, 0, sz)}", ""]
    out += ['[node name="Areas" type="Node3D" parent="."]', ""]
    enemies = {e[0]: e for e in ENEMIES}
    seed = 1
    for area, flag, enemy_names, villagers, light, lines in AREAS:
        base = f"Areas/{area}"
        out += [f'[node name="{area}" type="Node3D" parent="Areas"]', 'script = ExtResource("15_res")', f'liberated_by_flag = &"{flag}"', "",
                f'[node name="Occupied" type="Node3D" parent="{base}"]', ""]
        for name in enemy_names:
            _, rid, x, z, yaw = enemies[name]
            out += [f'[node name="{name}" parent="{base}/Occupied" instance=ExtResource("{rid}")]', f"position = {vec(x, 0, z)}",
                    f"rotation = {vec(0, yaw, 0)}", ""]
        out += [f'[node name="Liberated" type="Node3D" parent="{base}"]', ""]
        packed_lines = ", ".join('"' + line + '"' for line in lines)
        for n, (x, z) in enumerate(villagers, 1):
            out += [f'[node name="Villager{n}" parent="{base}/Liberated" instance=ExtResource("16_res")]', f"position = {vec(x, 0, z)}",
                    f"lines = PackedStringArray({packed_lines})", f"look_seed = {seed}", ""]
            seed += 1
        out += [f'[node name="WarmLight" type="OmniLight3D" parent="{base}/Liberated"]', f"position = {vec(light[0], 9, light[1])}",
                "light_color = Color(1, 0.74, 0.45, 1)", "light_energy = 0.9", "omni_range = 28.0", ""]
    assigned = {name for area in AREAS for name in area[2]}
    assert assigned == set(enemies), "every enemy outside belongs to an area"
    SCENE_PATH.write_text("\n".join(out).rstrip("\n") + "\n")


def write_raster(grid):
    RASTER_PATH.parent.mkdir(parents=True, exist_ok=True)
    Image.frombytes("L", (SIZE, SIZE), bytes(grid)).save(RASTER_PATH, optimize=True)
    import_file = RASTER_PATH.with_name(RASTER_PATH.name + ".import")
    if not import_file.exists():
        import_file.write_text('[remap]\n\nimporter="image"\ntype="Image"\n')


def preview(grid, houses, trees, boxes, path):
    scale = 2
    img = Image.new("RGB", (SIZE, SIZE))
    pal = [tuple(int(v * 255) for v in c) for c in PALETTE]
    img.putdata([pal[v] for v in grid])
    img = img.resize((SIZE * scale, SIZE * scale), Image.NEAREST)
    d = ImageDraw.Draw(img)

    def sp(x, z):
        return ((x + HALF) * scale, (z + HALF) * scale)

    for h in houses:
        x, z = h["pos"]
        w, _, dd = h["size"]
        c, s = math.cos(h["yaw"]), math.sin(h["yaw"])
        pts = [sp(x + u * c + v * s, z - u * s + v * c) for u, v in ((-w / 2, -dd / 2), (w / 2, -dd / 2), (w / 2, dd / 2), (-w / 2, dd / 2))]
        d.polygon(pts, fill=tuple(int(v * 255) for v in h["roof_color"]), outline=(20, 20, 20))
        door = sp(x - s * (dd / 2), z - c * (dd / 2))
        d.ellipse([door[0] - 1.5, door[1] - 1.5, door[0] + 1.5, door[1] + 1.5], fill=(255, 230, 120))
    for t in trees:
        x, z = sp(*t["pos"])
        r = 2.2 * t["scale"]
        d.ellipse([x - r, z - r, x + r, z + r], fill=(30, 80, 30) if not t["pine"] else (20, 60, 40))
    for name in L.LOCATIONS:
        d.polygon([sp(*p) for p in L.footprint(name)], outline=(255, 0, 255), width=2)
    for center, size in boxes:
        x0, z0 = sp(center[0] - size[0] / 2, center[1] - size[1] / 2)
        x1, z1 = sp(center[0] + size[0] / 2, center[1] + size[1] / 2)
        d.rectangle([x0, z0, x1, z1], outline=(0, 0, 120))
    for name, _, x, z, _ in ENEMIES:
        px_, pz = sp(x, z)
        d.ellipse([px_ - 4, pz - 4, px_ + 4, pz + 4], fill=(255, 40, 40))
    r = L.RING_PUSH * scale
    c0 = HALF * scale
    d.ellipse([c0 - r, c0 - r, c0 + r, c0 + r], outline=(200, 120, 40), width=2)
    img.save(path)


def main():
    rng = random.Random(SEED)
    grid = build_raster()
    dist = road_distance(grid)
    houses, occupied = place_houses(grid, dist, rng)
    trees = place_trees(grid, dist, occupied, rng) + outskirt_trees(random.Random(SEED + 1))
    boxes = water_boxes(grid)
    print(f"houses {len(houses)}, trees {len(trees)}, water boxes {len(boxes)}")
    if "--preview" in sys.argv:
        preview(grid, houses, trees, boxes, sys.argv[sys.argv.index("--preview") + 1])
        return
    write_raster(grid)
    write_scene(houses, trees, boxes)
    print("wrote", RASTER_PATH, "and", SCENE_PATH)


if __name__ == "__main__":
    main()
