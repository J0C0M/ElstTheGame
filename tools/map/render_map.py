"""Draws a map of Elst as it is in the game, in the style of the reference
map: the ground raster (streets, gardens, parks, water, fields), the houses
and trees that gen_elst.py places, the main roads, the railway with its
crossings, the six locations with their doors, the tornado ring, a legend,
a scale bar and north.

Run from the project root:
    python3 tools/map/render_map.py                 # writes docs/kaart_elst_spel.png
    python3 tools/map/render_map.py other.png

Everything comes from the game's own data (layout.py, the ground raster and
the random pass of gen_elst.py), so the map matches Elst.tscn.
"""
import math
import pathlib
import random
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import gen_elst as G  # noqa: E402
import layout as L  # noqa: E402

OUT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "docs/kaart_elst_spel.png")
PX = 2.0          # pixels per metre
EXTENT = 262.0    # metres from the middle to the edge of the picture
SIZE = int(EXTENT * 2 * PX)

GROUND = {
    G.FIELD_A: (214, 222, 182), G.FIELD_B: (222, 228, 190), G.FIELD_C: (232, 224, 182), G.FIELD_D: (220, 208, 180),
    G.YARD: (244, 238, 222), G.STREET: (236, 196, 156), G.MAIN: (236, 196, 156), G.PARK: (200, 218, 164),
    G.WATER: (168, 208, 216), G.BALLAST: (244, 238, 222), G.PAVING: (228, 222, 210),
}
OUTSIDE = (150, 140, 124)
HOUSE = (226, 196, 164)
HOUSE_EDGE = (176, 146, 116)
TREE = (120, 160, 96)
ROAD = (96, 96, 102)
RAIL = (64, 48, 36)
RING = (120, 74, 36)
WIND = (214, 130, 60)
INK = (20, 20, 20)
NAMES = {"Kerk": "Kerk", "BingoClub": "Bingo Club", "KlaasHouse": "Huis van Klaas", "Station": "Station",
         "Westeraam": "Westeraam", "OBCFort": "OBC Fort"}


def font(size, bold=True):
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                 "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"):
        if pathlib.Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def sp(x, z):
    return ((x + EXTENT) * PX, (z + EXTENT) * PX)


def town():
    """The same town gen_elst.py builds: raster, houses and trees."""
    grid = G.build_raster()
    dist = G.road_distance(grid)
    # One random pass for houses and then trees, as in gen_elst.main().
    rng = random.Random(G.SEED)
    houses, occupied = G.place_houses(grid, dist, rng)
    trees = G.place_trees(grid, dist, occupied, rng) + G.outskirt_trees(random.Random(G.SEED + 1))
    return grid, houses, trees


def draw_ground(img, grid):
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            wx, wz = x / PX - EXTENT, y / PX - EXTENT
            if math.hypot(wx, wz) > L.RING_WALL:
                px[x, y] = OUTSIDE
                continue
            i, j = G.world_cell(wx, wz)
            px[x, y] = GROUND[grid[j * G.SIZE + i]] if G.in_raster(i, j) else OUTSIDE


def draw_roads(d):
    for pts in L.MAIN_ROADS.values():
        d.line([sp(*p) for p in pts], fill=ROAD, width=int(G.MAIN_HALF_WIDTH * 2 * PX), joint="curve")
        for p in pts:
            x, y = sp(*p)
            r = G.MAIN_HALF_WIDTH * PX
            d.ellipse([x - r, y - r, x + r, y + r], fill=ROAD)


def draw_rail(d):
    top = -math.sqrt(L.RING_WALL ** 2 - L.RAIL_X ** 2)
    a, b = sp(L.RAIL_X, top - 20), sp(L.RAIL_X, -top + 20)
    d.line([a, b], fill=RAIL, width=int(3 * PX))
    z = top - 20
    while z < -top + 20:
        x0, y0 = sp(L.RAIL_X - 2.2, z)
        x1, _ = sp(L.RAIL_X + 2.2, z)
        d.line([(x0, y0), (x1, y0)], fill=RAIL, width=2)
        z += 3.0
    for z in L.RAIL_CROSSINGS_Z:
        x0, y0 = sp(L.RAIL_X - 5, z - 4)
        x1, y1 = sp(L.RAIL_X + 5, z + 4)
        d.rectangle([x0, y0, x1, y1], fill=(250, 250, 250), outline=INK, width=2)


def draw_houses_and_trees(d, houses, trees):
    for t in trees:
        x, y = sp(*t["pos"])
        r = 1.6 * t["scale"] * PX
        d.ellipse([x - r, y - r, x + r, y + r], fill=TREE)
    for h in houses:
        x, z = h["pos"]
        w, _, dd = h["size"]
        c, s = math.cos(h["yaw"]), math.sin(h["yaw"])
        pts = [sp(x + u * c + v * s, z - u * s + v * c) for u, v in ((-w / 2, -dd / 2), (w / 2, -dd / 2), (w / 2, dd / 2), (-w / 2, dd / 2))]
        d.polygon(pts, fill=HOUSE, outline=HOUSE_EDGE)


def draw_ring(d):
    for radius, color, width in ((L.RING_WALL, RING, 7), (L.RING_PUSH, WIND, 2)):
        x0, y0 = sp(-radius, -radius)
        x1, y1 = sp(radius, radius)
        d.ellipse([x0, y0, x1, y1], outline=color, width=width)


def arrow(d, start, end, color, width=4):
    d.line([start, end], fill=color, width=width)
    angle = math.atan2(end[1] - start[1], end[0] - start[0])
    for side in (-1, 1):
        a = angle + math.pi + side * 0.45
        d.line([end, (end[0] + math.cos(a) * 14, end[1] + math.sin(a) * 14)], fill=color, width=width)


def label(d, center, text, size=24):
    f = font(size)
    box = d.textbbox((0, 0), text, font=f)
    w, h = box[2] - box[0], box[3] - box[1]
    x, y = center[0] - w / 2, center[1] - h / 2
    d.rectangle([x - 6, y - 4, x + w + 6, y + h + 8], fill=(255, 255, 255))
    d.text((x, y), text, font=f, fill=INK)


def draw_locations(img):
    over = Image.new("RGBA", img.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(over)
    for name, loc in L.LOCATIONS.items():
        od.polygon([sp(*p) for p in L.footprint(name)], fill=loc["color"] + (120,), outline=INK + (255,), width=3)
    img.alpha_composite(over)
    d = ImageDraw.Draw(img)
    for name, loc in L.LOCATIONS.items():
        cx, cz = loc["pos"]
        dx, dz = L.door(name)
        x0, z0, x1, z1 = loc["box"]
        reach = max(abs(z0), abs(z1)) * 0.95
        arrow(d, sp(cx, cz), sp(cx + dx * reach, cz + dz * reach), INK)
    for name, loc in L.LOCATIONS.items():
        corners = L.footprint(name)
        top = min(p[1] for p in corners)
        bottom = max(p[1] for p in corners)
        cx = loc["pos"][0]
        # Above the location, or below it when that is nearer the edge.
        z = top - 9 if top > -200 else bottom + 9
        label(d, sp(cx, z), NAMES[name])


def draw_furniture(d):
    # North.
    x, y = 60, 40
    d.polygon([(x, y), (x - 14, y + 42), (x, y + 34), (x + 14, y + 42)], fill=INK)
    d.text((x - 10, y + 48), "N", font=font(28), fill=INK)
    # Scale bar of 100 m.
    sx, sy = 40, SIZE - 50
    d.rectangle([sx, sy, sx + 100 * PX, sy + 12], fill=(255, 236, 210), outline=INK)
    d.text((sx, sy - 30), "100 m", font=font(22), fill=(255, 250, 240))
    d.text((sx, sy - 70), "tornado: wind vanaf %d m,\nmuur op %d m" % (L.RING_PUSH, L.RING_WALL), font=font(16, False), fill=(255, 250, 240))
    # Legend.
    lx, ly = SIZE - 360, SIZE - 260
    d.rectangle([lx, ly, SIZE - 16, SIZE - 16], fill=(255, 255, 255), outline=INK, width=2)
    f = font(18, False)
    rows = [
        ("hoofdweg", lambda x, y: d.line([(x, y), (x + 44, y)], fill=ROAD, width=10)),
        ("straat", lambda x, y: d.line([(x, y), (x + 44, y)], fill=GROUND[G.STREET], width=8)),
        ("spoor, wit = overweg", lambda x, y: d.line([(x, y), (x + 44, y)], fill=RAIL, width=6)),
        ("huis", lambda x, y: d.rectangle([x + 12, y - 8, x + 32, y + 8], fill=HOUSE, outline=HOUSE_EDGE)),
        ("park / weiland", lambda x, y: (d.rectangle([x, y - 8, x + 20, y + 8], fill=GROUND[G.PARK]),
                                         d.rectangle([x + 24, y - 8, x + 44, y + 8], fill=GROUND[G.FIELD_A]))),
        ("water", lambda x, y: d.rectangle([x, y - 8, x + 44, y + 8], fill=GROUND[G.WATER])),
        ("locatie, pijl = deur", lambda x, y: d.rectangle([x, y - 10, x + 44, y + 10], fill=(200, 150, 230), outline=INK, width=2)),
    ]
    for n, (text, sample) in enumerate(rows):
        y = ly + 26 + n * 33
        sample(lx + 16, y)
        d.text((lx + 76, y - 11), text, font=f, fill=INK)
    title = "Elst, zoals in het spel (Prototype 1)"
    tb = d.textbbox((0, 0), title, font=font(22))
    d.rectangle([SIZE / 2 - (tb[2] - tb[0]) / 2 - 10, 10, SIZE / 2 + (tb[2] - tb[0]) / 2 + 10, 44], fill=(255, 255, 255))
    d.text((SIZE / 2 - (tb[2] - tb[0]) / 2, 14), title, font=font(22), fill=INK)


def main():
    grid, houses, trees = town()
    img = Image.new("RGBA", (SIZE, SIZE))
    draw_ground(img, grid)
    d = ImageDraw.Draw(img)
    draw_roads(d)
    draw_rail(d)
    draw_houses_and_trees(d, houses, trees)
    draw_ring(d)
    draw_locations(img)
    draw_furniture(ImageDraw.Draw(img))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(OUT, optimize=True)
    print("wrote", OUT, f"({len(houses)} houses, {len(trees)} trees)")


if __name__ == "__main__":
    main()
