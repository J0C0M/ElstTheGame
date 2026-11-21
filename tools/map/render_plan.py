"""Draws the planned layout of Elst over the reference map.

Run: python3 tools/map/render_plan.py docs/reference/kaart_elst.png plan.png
"""
import math
import sys
import pathlib
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import layout as L

MAP = Image.open(sys.argv[1]).convert("RGB")
OUT = sys.argv[2]
PPM = 2.0          # pixels per metre
HALF = 255.0       # metres shown around the origin
SIZE = int(HALF * 2 * PPM)


def font(size, bold=False):
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                 "/usr/share/fonts/TTF/DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            pass
    return ImageFont.load_default()


def scr(p):
    return ((p[0] + HALF) * PPM, (p[1] + HALF) * PPM)


img = Image.new("RGB", (SIZE, SIZE), (60, 56, 52))
px = img.load()
mp = MAP.load()
for y in range(SIZE):
    for x in range(SIZE):
        wx, wz = x / PPM - HALF, y / PPM - HALF
        mx, my = L.to_map((wx, wz))
        inside = math.hypot(wx, wz) <= L.RING_WALL
        if 0 <= mx < MAP.width and 0 <= my < MAP.height:
            r, g, b = mp[int(mx), int(my)]
        else:
            r, g, b = (225, 215, 185)
        if inside:
            px[x, y] = (int(r * 0.55 + 255 * 0.45), int(g * 0.55 + 250 * 0.45), int(b * 0.55 + 240 * 0.45))
        else:
            px[x, y] = (int(r * 0.35 + 70 * 0.65), int(g * 0.35 + 66 * 0.65), int(b * 0.35 + 62 * 0.65))

over = Image.new("RGBA", img.size, (0, 0, 0, 0))
d = ImageDraw.Draw(over)

# Tornado ring.
for radius, colour, width in ((L.RING_WALL, (120, 70, 30, 255), 6), (L.RING_PUSH, (200, 120, 40, 200), 3)):
    box = [scr((-radius, -radius)), scr((radius, radius))]
    d.ellipse([box[0][0], box[0][1], box[1][0], box[1][1]], outline=colour, width=width)

# Main roads.
for name, pts in L.MAIN_ROADS.items():
    d.line([scr(p) for p in pts], fill=(90, 90, 96, 230), width=int(8 * PPM), joint="curve")
    for p in pts:
        r = 4 * PPM
        c = scr(p)
        d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=(90, 90, 96, 230))

# Railway with sleepers.
top, bottom = -math.sqrt(L.RING_WALL ** 2 - L.RAIL_X ** 2), math.sqrt(L.RING_WALL ** 2 - L.RAIL_X ** 2)
d.line([scr((L.RAIL_X, top)), scr((L.RAIL_X, bottom))], fill=(70, 55, 45, 255), width=int(5 * PPM))
z = top
while z < bottom:
    a, b = scr((L.RAIL_X - 3.5, z)), scr((L.RAIL_X + 3.5, z))
    d.line([a, b], fill=(40, 30, 25, 255), width=2)
    z += 4
for cz in L.RAIL_CROSSINGS_Z:
    a, b = scr((L.RAIL_X - 6, cz)), scr((L.RAIL_X + 6, cz))
    d.rectangle([a[0], a[1] - 9, b[0], b[1] + 9], outline=(255, 255, 255, 255), width=3)

# Old positions.
for name, old in L.OLD.items():
    c = scr(old)
    n = scr(L.LOCATIONS[name]["pos"])
    d.line([c, n], fill=(80, 80, 80, 160), width=2)
    d.ellipse([c[0] - 9, c[1] - 9, c[0] + 9, c[1] + 9], outline=(80, 80, 80, 220), width=3)

# Locations.
names = {"Kerk": "Kerk", "BingoClub": "Bingo Club", "KlaasHouse": "Huis van Klaas", "Station": "Station",
         "Westeraam": "Westeraam", "OBCFort": "OBC Fort"}
for name, loc in L.LOCATIONS.items():
    poly = [scr(p) for p in L.footprint(name)]
    col = loc["color"]
    d.polygon(poly, fill=col + (150,), outline=(20, 20, 20, 255), width=3)
    c = scr(loc["pos"])
    dx, dz = L.door(name)
    x0, x1, z0, z1 = loc["box"]
    reach = -z0 + 10
    tip = scr((loc["pos"][0] + dx * reach, loc["pos"][1] + dz * reach))
    d.line([c, tip], fill=(20, 20, 20, 255), width=4)
    ang = math.atan2(tip[1] - c[1], tip[0] - c[0])
    for side in (2.5, -2.5):
        d.line([tip, (tip[0] - 16 * math.cos(ang + side / 6), tip[1] - 16 * math.sin(ang + side / 6))], fill=(20, 20, 20, 255), width=4)

img = Image.alpha_composite(img.convert("RGBA"), over)
d = ImageDraw.Draw(img)
f_big, f_mid, f_small = font(26, True), font(20), font(16)
label_offset = {"Kerk": (40, -50), "BingoClub": (-150, -60), "KlaasHouse": (-30, 40), "Station": (-120, 20),
                "Westeraam": (-40, 40), "OBCFort": (-40, 50)}
for name, loc in L.LOCATIONS.items():
    c = scr(loc["pos"])
    ox, oy = label_offset[name]
    text = names[name]
    tx, ty = c[0] + ox, c[1] + oy
    bb = d.textbbox((tx, ty), text, font=f_big)
    d.rectangle([bb[0] - 5, bb[1] - 3, bb[2] + 5, bb[3] + 3], fill=(255, 255, 255, 230))
    d.text((tx, ty), text, font=f_big, fill=(20, 20, 20))
rail_label = scr((L.RAIL_X + 6, 150))
d.text(rail_label, "spoor", font=f_mid, fill=(40, 30, 25))
d.text((16, SIZE - 120), "tornado: wind vanaf 222 m,\nmuur op 240 m", font=f_small, fill=(255, 235, 210))

# North arrow and scale bar.
d.polygon([(60, 30), (48, 70), (72, 70)], fill=(20, 20, 20))
d.text((52, 74), "N", font=f_big, fill=(20, 20, 20))
x0s, y0s = 40, SIZE - 50
d.rectangle([x0s, y0s, x0s + 100 * PPM, y0s + 10], fill=(255, 235, 210))
d.text((x0s, y0s - 28), "100 m", font=f_mid, fill=(255, 235, 210))

# Legend.
lx, ly = SIZE - 330, SIZE - 175
d.rectangle([lx - 10, ly - 10, SIZE - 15, SIZE - 15], fill=(255, 255, 255, 235), outline=(40, 40, 40))
d.line([(lx, ly + 12), (lx + 40, ly + 12)], fill=(90, 90, 96), width=14)
d.text((lx + 52, ly), "hoofdweg (van de kaart)", font=f_small, fill=(20, 20, 20))
d.line([(lx, ly + 46), (lx + 40, ly + 46)], fill=(70, 55, 45), width=10)
d.text((lx + 52, ly + 34), "spoor, wit = overweg", font=f_small, fill=(20, 20, 20))
d.polygon([(lx, ly + 70), (lx + 40, ly + 70), (lx + 40, ly + 92), (lx, ly + 92)], fill=(200, 150, 220), outline=(20, 20, 20))
d.text((lx + 52, ly + 70), "locatie, pijl = deur", font=f_small, fill=(20, 20, 20))
d.ellipse([lx + 11, ly + 106, lx + 29, ly + 124], outline=(80, 80, 80), width=3)
d.text((lx + 52, ly + 104), "oude plek", font=f_small, fill=(20, 20, 20))
img.convert("RGB").save(OUT)
print(img.size)
