"""Builds four location scenes in scenes/world/locations/: Station, Westeraam,
OBCFort and BingoClub, the outsides of the four dungeons. For the church and
Klaas' house, which are made by hand, it builds only their decoration
(KerkDecor.tscn and KlaasHouseDecor.tscn), instanced as "Decor" in them.

Run from the project root: python3 tools/map/gen_locations.py

Big buildings are House props; everything else (fences, bikes, cars, signs,
battlements) is boxes in a few BoxCluster nodes per location: Details (no
collision), Solids (with collision), Glow (always bright), Glass
(see-through) and Blockers (invisible walls). Every location stays inside the
"box" of its entry in tools/map/layout.py and faces its road with local -Z.
Doors, spawn points, quest markers and the location area keep their names,
because the world, the quests and the tests use them.
"""
import math
import pathlib
import random

OUT_DIR = pathlib.Path("scenes/world/locations")
CLUSTERS = {"Details": (0, False), "Solids": (0, True), "Glow": (1, False), "Glass": (2, False), "Blockers": (2, True)}
LOCKED = ("De deur zit op slot. Zolang Station Elst Amber bevoorraadt, houdt ze deze plek dicht. Sloop eerst het station.")

BLACK = (0.1, 0.1, 0.11)
WHITE = (0.93, 0.93, 0.9)
STEEL = (0.62, 0.63, 0.66)
DARK = (0.22, 0.22, 0.24)
CONCRETE = (0.6, 0.6, 0.58)
WOOD = (0.5, 0.34, 0.2)
GREEN = (0.24, 0.45, 0.22)
AMBER = (0.92, 0.55, 0.12)
YELLOW = (0.95, 0.78, 0.15)
RED = (0.7, 0.14, 0.12)
NAVY = (0.14, 0.18, 0.4)
PINK = (0.94, 0.73, 0.83)
LAMP = (1.0, 0.92, 0.7)
INVISIBLE = (0, 0, 0, 0)


def f(v):
    s = f"{v:.3f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def vec(*v):
    return "Vector3(" + ", ".join(f(c) for c in v) + ")"


def col(c):
    return f"Color({f(c[0])}, {f(c[1])}, {f(c[2])}, {f(c[3]) if len(c) > 3 else 1})"


class Group:
    """Places parts relative to a point and a turn, like a small prop."""

    def __init__(self, loc, x, z, yaw, y=0.0):
        self.loc, self.x, self.z, self.yaw, self.y = loc, x, z, yaw, y

    def add(self, cat, dx, dy, dz, sx, sy, sz, c, dyaw=0.0):
        cos, sin = math.cos(self.yaw), math.sin(self.yaw)
        self.loc.add(cat, self.x + dx * cos + dz * sin, self.y + dy, self.z - dx * sin + dz * cos, sx, sy, sz, c, self.yaw + dyaw)


class Location:
    def __init__(self, root):
        self.root = root
        self.boxes = {name: [] for name in CLUSTERS}
        self.nodes = []

    def add(self, cat, x, y, z, sx, sy, sz, c, yaw=0.0):
        self.boxes[cat].append((x, y, z, sx, sy, sz, yaw, c))

    def ground(self, cat, x, z, sx, sy, sz, c, base=0.0, yaw=0.0):
        """A box standing on the ground (or on [base])."""
        self.add(cat, x, base + sy / 2, z, sx, sy, sz, c, yaw)

    def group(self, x, z, yaw=0.0, y=0.0):
        return Group(self, x, z, yaw, y)

    def house(self, name, pos, size, wall, roof, roof_height=0, has_door=False, yaw=0.0):
        lines = [f'[node name="{name}" parent="." instance=ExtResource("1_house")]', f"position = {vec(*pos)}"]
        if yaw:
            lines.append(f"rotation = {vec(0, yaw, 0)}")
        lines += [f"size = {vec(*size)}", f"roof_height = {f(roof_height)}", f"wall_color = {col(wall)}", f"roof_color = {col(roof)}"]
        if not has_door:
            lines.append("has_door = false")
        self.nodes.append(lines)

    def label(self, name, pos, yaw, text, c, font=96, pixel=0.01, outline=(0.05, 0.05, 0.06)):
        self.nodes.append([f'[node name="{name}" type="Label3D" parent="."]', f"position = {vec(*pos)}", f"rotation = {vec(0, yaw, 0)}",
                           f"pixel_size = {f(pixel)}", "double_sided = false", f"modulate = {col(c)}", f"outline_modulate = {col(outline)}",
                           f'text = "{text}"', f"font_size = {font}", "outline_size = 12"])

    def light(self, name, pos, c, energy, rng):
        self.nodes.append([f'[node name="{name}" type="OmniLight3D" parent="."]', f"position = {vec(*pos)}", f"light_color = {col(c)}",
                           f"light_energy = {f(energy)}", f"omni_range = {f(rng)}"])

    def tree(self, name, x, z, scale=1.0, yaw=0.0):
        self.nodes.append([f'[node name="{name}" parent="." instance=ExtResource("6_tree")]', f"position = {vec(x, 0, z)}",
                           f"rotation = {vec(0, yaw, 0)}", f"scale = {vec(scale, scale, scale)}"])

    def raw(self, *lines):
        self.nodes.append(list(lines))

    def door(self, name, pos, prompt, door_color, target, locked=True):
        lines = [f'[node name="{name}" parent="." instance=ExtResource("2_door")]']
        if locked:
            lines += ['unlocked_by_flag = &"station_cleared"', f'locked_message = "{LOCKED}"']
        lines += [f"position = {vec(*pos)}", f'prompt = "{prompt}"', f"door_color = {col(door_color)}",
                  f'target_scene = "{target}"', 'target_spawn = &"Entrance"']
        self.nodes.append(lines)

    def markers(self, exit_name, exit_pos, marker_pos, marker_id):
        self.raw(f'[node name="{exit_name}" type="Marker3D" parent="." groups=["spawn_points"]]', f"position = {vec(*exit_pos)}")
        self.raw('[node name="MarkerDoor" type="Marker3D" parent="."]', f"position = {vec(*marker_pos)}", 'script = ExtResource("4_marker")',
                 f'ids = Array[StringName]([&"{marker_id}"])')

    def write(self, file_name, area_id=None, area_name="", area_pos=(0, 0, 0), area_size=(1, 1, 1)):
        out = ['[gd_scene format=3]', '',
               '[ext_resource type="PackedScene" path="res://scenes/world/props/House.tscn" id="1_house"]',
               '[ext_resource type="PackedScene" path="res://scenes/world/props/DungeonEntrance.tscn" id="2_door"]',
               '[ext_resource type="Script" path="res://scenes/world/location_area.gd" id="3_area"]',
               '[ext_resource type="Script" path="res://scripts/quests/quest_marker.gd" id="4_marker"]',
               '[ext_resource type="Script" path="res://scripts/world/box_cluster.gd" id="5_cluster"]',
               '[ext_resource type="PackedScene" path="res://scenes/world/props/TreeProp.tscn" id="6_tree"]', '',
               '[sub_resource type="BoxShape3D" id="Shape_area"]', f"size = {vec(*area_size)}", '',
               f'[node name="{self.root}" type="Node3D"]', '']
        for name, (look, solid) in CLUSTERS.items():
            boxes = self.boxes[name]
            if not boxes:
                continue
            numbers = ", ".join(", ".join(f(v) for v in b[:7]) for b in boxes)
            colours = ", ".join(", ".join(f(v) for v in (b[7] + (1,) if len(b[7]) == 3 else b[7])) for b in boxes)
            out += [f'[node name="{name}" type="StaticBody3D" parent="."]', 'script = ExtResource("5_cluster")',
                    f"boxes = PackedFloat32Array({numbers})", f"colors = PackedColorArray({colours})"]
            if look:
                out.append(f"look = {look}")
            if solid:
                out.append("solid = true")
            out.append("")
        for block in self.nodes:
            out += block + [""]
        if area_id is None:
            out = [line for line in out if "Shape_area" not in line and "size = " + vec(*area_size) != line]
        else:
            out += ['[node name="LocationArea" type="Area3D" parent="."]', 'script = ExtResource("3_area")', f'id = &"{area_id}"',
                f'display_name = "{area_name}"', '',
                '[node name="CollisionShape3D" type="CollisionShape3D" parent="LocationArea"]', f"position = {vec(*area_pos)}",
                'shape = SubResource("Shape_area")']
        path = OUT_DIR / file_name
        path.write_text("\n".join(out) + "\n")
        print(f"wrote {path}: {sum(len(b) for b in self.boxes.values())} boxes, {len(self.nodes)} nodes")


# Small props, built around their own centre and turn.

def bike(loc, x, z, yaw, c):
    g = loc.group(x, z, yaw)
    for dz in (-0.52, 0.52):
        g.add("Details", 0, 0.35, dz, 0.06, 0.7, 0.7, BLACK)
    g.add("Details", 0, 0.62, 0, 0.06, 0.07, 1.0, c)
    g.add("Details", 0, 0.5, -0.12, 0.06, 0.5, 0.07, c)
    g.add("Details", 0, 0.82, 0.2, 0.18, 0.06, 0.26, BLACK)
    g.add("Details", 0, 0.92, -0.5, 0.5, 0.05, 0.05, DARK)


def car(loc, x, z, yaw, body, burnt=False):
    g = loc.group(x, z, yaw)
    lift = 0.0 if burnt else 0.2
    g.add("Solids", 0, 0.55 + lift, 0, 1.8, 0.8, 4.2, body)
    g.add("Details", 0, 1.25 + lift, 0.25, 1.6, 0.6, 2.2, BLACK if burnt else (0.25, 0.32, 0.4))
    for dx in (-0.85, 0.85):
        for dz in (-1.3, 1.3):
            g.add("Details", dx, 0.3 if not burnt else 0.18, dz, 0.25, 0.6 if not burnt else 0.36, 0.6 if not burnt else 0.36,
                  BLACK if not burnt else (0.3, 0.28, 0.27))
    if burnt:
        g.add("Details", 0, 0.03, 0, 3.0, 0.02, 5.0, (0.12, 0.11, 0.1))
    else:
        for dx in (-0.6, 0.6):
            g.add("Glow", dx, 0.7, -2.11, 0.35, 0.18, 0.04, LAMP)


def lamp_post(loc, x, z, height=4.5, yaw=0.0):
    g = loc.group(x, z, yaw)
    g.add("Solids", 0, height / 2, 0, 0.16, height, 0.16, DARK)
    g.add("Details", 0, height, -0.35, 0.12, 0.12, 0.8, DARK)
    g.add("Glow", 0, height - 0.12, -0.65, 0.4, 0.12, 0.3, LAMP)


def bench(loc, x, z, yaw, c=WOOD):
    g = loc.group(x, z, yaw)
    g.add("Solids", 0, 0.45, 0, 1.8, 0.08, 0.5, c)
    g.add("Details", 0, 0.75, 0.22, 1.8, 0.45, 0.06, c)
    for dx in (-0.75, 0.75):
        g.add("Details", dx, 0.22, 0, 0.08, 0.45, 0.45, DARK)


def fence(loc, x0, z0, x1, z1, height, c, tip=None, gap_every=0.5):
    """A metal fence of bars between two points, with an invisible wall."""
    length = math.hypot(x1 - x0, z1 - z0)
    yaw = math.atan2(-(z1 - z0), x1 - x0)
    g = loc.group((x0 + x1) / 2, (z0 + z1) / 2, yaw)
    for y in (0.3, height - 0.15):
        g.add("Details", 0, y, 0, length, 0.07, 0.06, c)
    n = max(int(length / gap_every), 1)
    for i in range(n + 1):
        dx = -length / 2 + i * length / n
        post = i % 4 == 0
        g.add("Details", dx, height / 2, 0, 0.1 if post else 0.04, height, 0.1 if post else 0.04, c)
        if tip and post:
            g.add("Details", dx, height + 0.08, 0, 0.14, 0.16, 0.14, tip)
    g.add("Blockers", 0, height / 2, 0, length, height, 0.2, INVISIBLE)


def battlements(loc, x0, z0, x1, z1, top, c, merlon=1.0, every=2.0, depth=1.4):
    length = math.hypot(x1 - x0, z1 - z0)
    yaw = math.atan2(-(z1 - z0), x1 - x0)
    g = loc.group((x0 + x1) / 2, (z0 + z1) / 2, yaw)
    n = int(length / every)
    for i in range(n + 1):
        g.add("Solids", -length / 2 + i * length / max(n, 1), top + 0.6, 0, merlon, 1.2, depth, c)


def flag(loc, x, z, base, c, stripe, yaw=0.0):
    g = loc.group(x, z, yaw, base)
    g.add("Details", 0, 2.2, 0, 0.12, 4.4, 0.12, STEEL)
    g.add("Details", 0.85, 3.8, 0, 1.6, 1.0, 0.05, c)
    g.add("Details", 0.85, 3.8, 0, 1.6, 0.3, 0.06, stripe)


def build_station():
    """Elst Station: the passenger hall with a clock, the platform along the
    rail (local x -15), a square with bikes and a bus shelter, and Amber's
    supply depot behind a fence, where the dungeon door is."""
    loc = Location("Station")
    rng = random.Random(1)
    # The platform and its ramp stand where they always did, along the rail.
    loc.add("Solids", -10.5, 0.5, 0, 5, 1, 60, (0.62, 0.6, 0.56))
    loc.add("Solids", -10.5, 0.25, -31.5, 5, 0.5, 3, (0.62, 0.6, 0.56))
    loc.add("Details", -12.9, 1.01, 0, 0.15, 0.02, 60, WHITE)
    loc.add("Details", -12.4, 1.01, 0, 0.3, 0.02, 60, YELLOW)
    loc.add("Details", -10.3, 4.4, 0, 4.8, 0.25, 40, DARK)
    loc.add("Glow", -10.3, 4.24, 0, 0.3, 0.08, 36, LAMP)
    for z in range(-16, 17, 8):
        loc.add("Solids", -9.0, 2.7, z, 0.25, 3.4, 0.25, DARK)
    for z in (-10, 2, 14):
        bench(loc, -9.6, z, math.pi / 2, (0.25, 0.4, 0.7))
    loc.add("Details", -10.3, 3.6, -4, 0.15, 0.8, 2.6, NAVY)
    loc.label("DepartureBoard", (-10.38, 3.6, -4), -math.pi / 2, "Nijmegen  12:04\\nArnhem    12:11", YELLOW, font=40, pixel=0.006)
    for z in (-20, 9):
        loc.add("Details", -10.3, 3.45, z, 0.1, 0.7, 2.6, NAVY)
    loc.label("NameBoard", (-10.37, 3.45, -20), -math.pi / 2, "Elst", WHITE, font=72, pixel=0.008)
    loc.label("NameBoard2", (-10.37, 3.45, 9), -math.pi / 2, "Elst", WHITE, font=72, pixel=0.008)
    loc.ground("Solids", -9.2, -24, 0.6, 1.7, 0.5, (0.3, 0.38, 0.55), base=1.0)
    loc.add("Glow", -9.5, 2.2, -24, 0.04, 0.35, 0.3, (0.5, 0.8, 1.0))
    # The passenger hall: brick with a glass front and a wide flat roof that
    # reaches over to the platform.
    loc.house("StationHall", (0, 0, -5), (12, 5, 14), (0.55, 0.3, 0.22), DARK)
    loc.add("Details", -1.5, 5.25, -5, 17, 0.4, 17, DARK)
    loc.add("Glass", 0, 1.6, -12.06, 6, 3.0, 0.1, (0.55, 0.75, 0.9, 0.55))
    loc.add("Details", 0, 3.15, -12.08, 6.2, 0.12, 0.14, DARK)
    for dx in (-3.05, -1, 1, 3.05):
        loc.add("Details", dx, 1.6, -12.08, 0.12, 3.1, 0.14, DARK)
    loc.add("Glass", 0, 5.95, -5, 10, 1.0, 12, (0.6, 0.8, 0.95, 0.5))
    loc.add("Details", 0, 6.5, -5, 10.4, 0.15, 12.4, DARK)
    loc.add("Details", 0, 3.4, -13.6, 9, 0.25, 3.2, DARK)
    for x in (-4.2, 4.2):
        loc.add("Solids", x, 1.7, -14.9, 0.2, 3.4, 0.2, DARK)
    loc.add("Details", 0, 4.2, -12.12, 8, 0.9, 0.1, NAVY)
    loc.label("Sign", (0, 4.2, -12.2), math.pi, "Station Elst", WHITE, font=96, pixel=0.009)
    # Clock on a post at the corner of the square.
    loc.add("Solids", 9, 5, -14, 0.5, 10, 0.5, DARK)
    loc.add("Details", 9, 10.3, -14, 1.5, 1.5, 1.5, DARK)
    for side_yaw in (0.0, math.pi / 2, math.pi, -math.pi / 2):
        g = loc.group(9, -14, side_yaw, 10.3)
        g.add("Details", 0, 0, -0.76, 1.2, 1.2, 0.04, WHITE)
        g.add("Details", 0, 0.2, -0.79, 0.07, 0.45, 0.03, BLACK)
        g.add("Details", 0.15, 0, -0.79, 0.35, 0.06, 0.03, BLACK)
    # The square: paving, planters with trees, benches, bikes and a bus shelter.
    loc.add("Details", 7, 0.02, -31.5, 40, 0.04, 23, (0.66, 0.6, 0.55))
    for x, z in ((-3, -40), (13, -40), (21, -24)):
        loc.ground("Solids", x, z, 2.2, 0.5, 2.2, (0.55, 0.3, 0.22))
        loc.tree(f"Tree{len(loc.nodes)}", x, z, 0.75, rng.uniform(0, math.pi))
    bench(loc, 5, -40.5, 0)
    bench(loc, -3, -36.5, math.pi)
    colours = [BLACK, (0.2, 0.3, 0.6), RED, (0.25, 0.45, 0.3), STEEL, (0.9, 0.85, 0.75), (0.5, 0.2, 0.4)]
    for row_z in (-22.5, -27.5):
        loc.add("Details", 7, 0.35, row_z, 9.5, 0.06, 0.06, STEEL)
        for i in range(12):
            if rng.random() < 0.85:
                bike(loc, 2.6 + i * 0.8, row_z, rng.uniform(-0.08, 0.08), rng.choice(colours))
    g = loc.group(20, -38, 0)
    g.add("Glass", 0, 1.3, 0.7, 4, 2.4, 0.06, (0.7, 0.85, 0.9, 0.4))
    for dx in (-2, 2):
        g.add("Glass", dx, 1.3, 0, 0.06, 2.4, 1.4, (0.7, 0.85, 0.9, 0.4))
        g.add("Solids", dx, 1.3, 0.7, 0.1, 2.6, 0.1, DARK)
    g.add("Details", 0, 2.65, 0.1, 4.4, 0.15, 1.8, DARK)
    g.add("Details", 0, 0.45, 0.45, 3, 0.08, 0.4, WOOD)
    g.add("Solids", -2.9, 1.5, -0.6, 0.1, 3, 0.1, DARK)
    g.add("Details", -2.9, 2.9, -0.6, 0.7, 0.5, 0.06, YELLOW)
    loc.label("BusSign", (17.1, 2.9, -38.65), math.pi, "BUS", BLACK, font=40, pixel=0.006, outline=YELLOW)
    g = loc.group(14, -20.5, 0)
    g.add("Solids", 0, 1.3, 0, 3, 2.6, 2.4, (0.85, 0.82, 0.75))
    for i in range(5):
        g.add("Details", -1.2 + i * 0.6, 2.75, -1.6, 0.6, 0.12, 1.0, RED if i % 2 == 0 else WHITE)
    loc.label("KioskSign", (14, 2.25, -21.75), math.pi, "BROODJES", RED, font=40, pixel=0.006, outline=WHITE)
    for x, z in ((-5, -27), (10, -33), (25, -31), (2, -42.2)):
        lamp_post(loc, x, z)
    # Amber's supply depot: a corrugated hall with an amber band, banners, a
    # shutter on each side, pallets of protein shakes, a container and a fence.
    loc.house("SupplyBuilding", (16, 0, 26), (22, 9, 16), (0.32, 0.33, 0.35), (0.16, 0.16, 0.17))
    for i in range(23):
        x = 5.5 + i
        if not 13.5 < x < 18.5:
            loc.add("Details", x, 4.5, 17.93, 0.12, 9, 0.12, (0.26, 0.27, 0.29))
    loc.add("Details", 16, 7.6, 17.9, 22.2, 0.7, 0.1, AMBER)
    loc.label("SupplySign", (16, 8.5, 17.82), math.pi, "AMBER LOGISTIEK", AMBER, font=96, pixel=0.012)
    for x in (10.5, 21.5):
        loc.add("Details", x, 2.1, 17.92, 3.6, 4.2, 0.1, (0.45, 0.46, 0.48))
        for y in range(8):
            loc.add("Details", x, 0.3 + y * 0.5, 17.86, 3.6, 0.05, 0.04, (0.35, 0.36, 0.38))
    for x in (6.5, 25.5):
        loc.add("Details", x, 4.6, 17.86, 1.5, 4.2, 0.08, AMBER)
        loc.add("Details", x, 5.0, 17.81, 0.8, 1.2, 0.04, BLACK)
    for x in (8, 24):
        loc.add("Solids", x, 1.2, 15.5, 3, 2.4, 2.4, DARK)
        loc.add("Details", x, 1.6, 14.28, 3.02, 0.4, 0.05, AMBER)
        loc.add("Glow", x + 1.1, 2.1, 14.27, 0.2, 0.2, 0.04, (1.0, 0.3, 0.1))
    for x, z in ((7, 10.5), (9, 11), (25.5, 12.5)):
        g = loc.group(x, z, rng.uniform(-0.3, 0.3))
        for layer in range(3):
            g.add("Solids", 0, 0.08 + layer * 0.75, 0, 1.2, 0.15, 1.0, WOOD)
            g.add("Solids", 0, 0.45 + layer * 0.75, 0, 1.1, 0.6, 0.9, WHITE)
            g.add("Details", 0, 0.45 + layer * 0.75, 0, 1.12, 0.15, 0.92, AMBER)
    for i in range(5):
        loc.ground("Solids", 4.6 + (i % 3) * 0.7, 13 + (i // 3) * 0.7, 0.6, 0.9, 0.6, AMBER if i % 2 else (0.85, 0.85, 0.8))
    g = loc.group(24.5, 2.5, 0)
    g.add("Solids", 0, 1.3, 0, 2.4, 2.6, 6, (0.85, 0.45, 0.12))
    for dz in range(-2, 3):
        g.add("Details", -1.22, 1.3, dz * 1.1, 0.04, 2.5, 0.12, (0.7, 0.36, 0.1))
    g.add("Details", 0, 1.3, -3.02, 2.3, 2.5, 0.04, (0.7, 0.36, 0.1))
    fence(loc, 3, 8, 12, 8, 2.4, STEEL, tip=DARK, gap_every=2.4)
    fence(loc, 20, 8, 27, 8, 2.4, STEEL, tip=DARK, gap_every=2.4)
    fence(loc, 3, 8, 3, 34, 2.4, STEEL, tip=DARK, gap_every=2.4)
    for x0, x1 in ((3, 12), (20, 27)):
        loc.add("Glass", (x0 + x1) / 2, 1.25, 8, x1 - x0, 2.1, 0.03, (0.6, 0.62, 0.64, 0.3))
        loc.add("Details", (x0 + x1) / 2, 2.55, 8, x1 - x0, 0.05, 0.05, DARK)
    loc.add("Glass", 3, 1.25, 21, 0.03, 2.1, 26, (0.6, 0.62, 0.64, 0.3))
    for x, z in ((4, 9.5), (26, 9.5)):
        loc.add("Solids", x, 3.5, z, 0.2, 7, 0.2, DARK)
        loc.add("Glow", x, 7, z + 0.2, 1.2, 0.5, 0.2, LAMP)
    loc.door("SupplyDoor", (16, 0, 17.85), "Het gebouw naast het station binnengaan", (0.3, 0.7, 0.4), "res://scenes/dungeons/Station.tscn",
             locked=False)
    loc.markers("StationExit", (16, 0, 14), (16, 0, 16), "generator")
    loc.write("Station.tscn", "station", "Elst Station", (5, 10, 0), (60, 20, 90))


def gallery_flat(loc, rng, name, pos, size, yaw, floors):
    """A gallery flat: a House with a concrete gallery and a railing on every
    floor along the front, laundry, satellite dishes and a striped plinth."""
    loc.house(name, pos, size, (0.86, 0.7, 0.25), BLACK, yaw=yaw)
    length, depth = size[0], size[2]
    g = loc.group(pos[0], pos[2], yaw)
    front = -depth / 2
    for n in range(floors):
        y = 3.4 + n * 3
        g.add("Details", 0, y, front - 0.8, length + 0.6, 0.3, 1.6, CONCRETE)
        g.add("Details", 0, y + 0.6, front - 1.58, length + 0.6, 0.9, 0.06, BLACK)
        g.add("Details", 0, y + 1.1, front - 1.58, length + 0.6, 0.08, 0.14, YELLOW)
        for _ in range(3):
            dx = rng.uniform(-length / 2 + 1, length / 2 - 1)
            g.add("Details", dx, y + 0.5, front - 1.66, 0.45, 0.55, 0.03, rng.choice([RED, WHITE, (0.3, 0.5, 0.9), PINK, GREEN]))
        if rng.random() < 0.7:
            dx = rng.uniform(-length / 2 + 1, length / 2 - 1)
            g.add("Details", dx, y + 1.45, front - 1.75, 0.6, 0.6, 0.08, (0.85, 0.85, 0.85), dyaw=rng.uniform(-0.6, 0.6))
    for i in range(int(length)):
        dx = -length / 2 + 0.5 + i
        if abs(dx) > 1.6 or name != "FlatBack":
            g.add("Details", dx, 0.5, front - 0.03, 1.0, 1.0, 0.05, YELLOW if i % 2 == 0 else BLACK)


def build_westeraam():
    """Westeraam Getho: three yellow gallery flats round a rough courtyard, with
    a burnt-out car, a fire barrel, bins, trolleys, a sofa, a broken swing, a
    basketball pole and vape clouds at the door. A black fence with a gate
    and a sign closes the front."""
    loc = Location("Westeraam")
    rng = random.Random(2)
    loc.add("Details", 0, 0.02, -2, 38, 0.04, 24, (0.27, 0.27, 0.28))
    for x0, z0, x1, z1 in ((-6, -10, 6, -10), (-6, -10, -6, -2), (6, -10, 6, -2), (-6, -2, 6, -2)):
        loc.add("Details", (x0 + x1) / 2, 0.05, (z0 + z1) / 2, max(abs(x1 - x0), 0.12), 0.01, max(abs(z1 - z0), 0.12), YELLOW)
    gallery_flat(loc, rng, "FlatBack", (0, 0, 14), (16, 21, 10), 0.0, 6)
    gallery_flat(loc, rng, "FlatLeft", (-17, 0, 2), (16, 18, 10), -1.571, 5)
    gallery_flat(loc, rng, "FlatRight", (17, 0, 2), (16, 18, 10), 1.571, 5)
    loc.house("BlockBlack", (-12, 0, 22), (10, 9, 8), BLACK, YELLOW)
    loc.add("Glow", -12, 3.2, 17.94, 6, 0.12, 0.05, (0.75, 0.3, 1.0))
    loc.label("VapeShopSign", (-12, 4.0, 17.9), math.pi, "VAPESHOP", (0.8, 0.45, 1.0), font=64, pixel=0.01)
    # Graffiti on the ground floors.
    for x, z, yaw, text, blob in ((-11.95, -1, math.pi / 2, "WSTRM", (0.2, 0.8, 0.4)), (11.95, 4, -math.pi / 2, "VAPE 4 LIFE", (0.9, 0.3, 0.6)),
                                  (-5, 8.9, math.pi, "KONING", (0.3, 0.6, 0.95))):
        g = loc.group(x, z, yaw)
        g.add("Details", 0, 1.9, 0.03, 4.2, 1.6, 0.04, blob)
        loc.label(f"Graffiti{len(loc.nodes)}", (x + 0.07 * math.sin(yaw), 1.9, z + 0.07 * math.cos(yaw)), yaw, text, YELLOW, font=72, pixel=0.012)
    # The portiek: a striped canopy on two pillars, an intercom and vape clouds.
    loc.add("Details", 0, 3.05, 7.8, 5, 0.25, 2.4, BLACK)
    for i in range(10):
        loc.add("Details", -2.25 + i * 0.5, 3.05, 6.58, 0.5, 0.26, 0.06, YELLOW if i % 2 == 0 else BLACK)
    for x in (-2.3, 2.3):
        loc.add("Solids", x, 1.5, 6.9, 0.3, 3, 0.3, BLACK)
    loc.add("Details", 1.6, 1.3, 8.9, 0.3, 0.5, 0.08, STEEL)
    for x, y, z, s in ((-1.5, 2.2, 6.0, 1.3), (1.4, 2.6, 5.6, 1.0), (0.2, 3.5, 6.4, 1.5), (-0.6, 1.4, 5.0, 0.9)):
        loc.add("Glass", x, y, z, s, s * 0.7, s * 0.8, (0.7, 0.55, 0.9, 0.35), rng.uniform(0, 1))
    # The courtyard.
    car(loc, -6.5, -4.5, 0.4, (0.16, 0.13, 0.12), burnt=True)
    loc.ground("Solids", -2.8, -7.5, 0.6, 0.9, 0.6, (0.45, 0.25, 0.15))
    loc.add("Glow", -2.8, 1.0, -7.5, 0.45, 0.25, 0.45, (1.0, 0.45, 0.1))
    loc.add("Glow", -2.75, 1.25, -7.5, 0.25, 0.3, 0.25, (1.0, 0.8, 0.2))
    loc.light("FireLight", (-2.8, 1.6, -7.5), (1.0, 0.55, 0.2), 2.0, 7.0)
    for z in (6.2, 3.4):
        g = loc.group(9.8, z, 0)
        g.add("Solids", 0, 0.6, 0, 1.2, 1.2, 2.0, (0.2, 0.42, 0.25))
        g.add("Details", 0, 1.25, 0, 1.26, 0.1, 2.06, BLACK)
    for x, z, yaw in ((4, -8, 0.6), (6, -6, 2.0), (-9, 5, 1.0)):
        g = loc.group(x, z, yaw)
        g.add("Details", 0, 0.75, 0, 0.6, 0.5, 0.9, STEEL)
        g.add("Details", 0, 1.05, 0.55, 0.6, 0.06, 0.06, RED)
        for dx in (-0.25, 0.25):
            for dz in (-0.35, 0.35):
                g.add("Details", dx, 0.1, dz, 0.06, 0.2, 0.12, BLACK)
    g = loc.group(-9, -10, 0.3)
    g.add("Solids", 0, 0.3, 0, 2.0, 0.45, 0.9, (0.45, 0.3, 0.2))
    g.add("Details", 0, 0.75, 0.38, 2.0, 0.6, 0.25, (0.45, 0.3, 0.2))
    for dx in (-1.05, 1.05):
        g.add("Details", dx, 0.55, 0, 0.25, 0.55, 0.9, (0.4, 0.26, 0.17))
    for x in (6.5, 9.5):
        loc.add("Solids", x, 1.2, -11, 0.12, 2.4, 0.12, RED)
    loc.add("Details", 8, 2.4, -11, 3.2, 0.12, 0.12, RED)
    loc.add("Details", 7.2, 1.2, -11, 0.04, 1.6, 0.04, STEEL)
    loc.add("Details", 7.2, 0.38, -11, 0.5, 0.05, 0.2, BLACK)
    loc.add("Details", 8.7, 0.03, -10.6, 0.5, 0.05, 0.2, BLACK, 0.7)
    loc.add("Solids", 11, 1.7, -12, 0.2, 3.4, 0.2, DARK)
    loc.add("Details", 11, 3.3, -11.85, 1.8, 1.1, 0.08, WHITE)
    loc.add("Details", 11, 3.0, -11.5, 0.5, 0.05, 0.5, AMBER)
    for x, z, yaw, body in ((3, 4, 1.2, YELLOW), (4.6, 4.8, 1.35, BLACK)):
        g = loc.group(x, z, yaw)
        g.add("Details", 0, 0.45, 0, 0.45, 0.5, 1.5, body)
        g.add("Details", 0, 0.8, 0.25, 0.4, 0.15, 0.6, BLACK)
        g.add("Details", 0, 1.1, -0.65, 0.6, 0.06, 0.06, DARK)
        for dz in (-0.6, 0.6):
            g.add("Details", 0, 0.2, dz, 0.12, 0.4, 0.4, BLACK)
    # The front fence with a gate under a sign.
    fence(loc, -19, -13.5, -3, -13.5, 2.0, BLACK, tip=YELLOW)
    fence(loc, 3, -13.5, 19, -13.5, 2.0, BLACK, tip=YELLOW)
    fence(loc, -19, -13.5, -19, -6, 2.0, BLACK, tip=YELLOW)
    fence(loc, 19, -13.5, 19, -6, 2.0, BLACK, tip=YELLOW)
    for x in (-3.3, 3.3):
        loc.add("Solids", x, 1.4, -13.5, 0.6, 2.8, 0.6, BLACK)
        loc.add("Details", x, 2.85, -13.5, 0.7, 0.1, 0.7, YELLOW)
        loc.add("Details", x, 3.4, -13.5, 0.15, 1.2, 0.15, BLACK)
    loc.add("Details", 0, 4.1, -13.5, 7.2, 0.9, 0.25, BLACK)
    loc.label("GateSign", (0, 4.1, -13.65), math.pi, "WESTERAAM GETHO", YELLOW, font=64, pixel=0.009)
    loc.label("Sign", (0, 23, 8.9), math.pi, "WESTERAAM", YELLOW, font=160, pixel=0.02)
    for x, z in ((-10, -9), (10, -3), (-9, 6)):
        lamp_post(loc, x, z, 4.2, rng.uniform(0, math.tau))
    loc.door("FlatDoor", (0, 0, 8.85), "Westeraam Getho binnengaan", BLACK, "res://scenes/dungeons/Westeraam.tscn")
    loc.markers("WesteraamExit", (0, 0, 5), (0, 0, 6), "vape_koning")
    loc.write("Westeraam.tscn", "westeraam", "Westeraam Getho", (0, 15, 4), (50, 30, 46))


def fort_tower(loc, x, z, size, height, flag_yaw):
    loc.add("Solids", x, height / 2, z, size, height, size, (0.62, 0.2, 0.18))
    loc.add("Details", x, height - 0.6, z, size + 0.1, 0.4, size + 0.1, NAVY)
    half = size / 2 - 0.4
    for sx, sz, ex, ez in ((-half, -half, half, -half), (half, -half, half, half), (half, half, -half, half), (-half, half, -half, -half)):
        battlements(loc, x + sx, z + sz, x + ex, z + ez, height, (0.62, 0.2, 0.18), merlon=0.9, every=1.6, depth=0.8)
    for face_yaw in (0.0, math.pi / 2, math.pi, -math.pi / 2):
        g = loc.group(x, z, face_yaw)
        for y in (height * 0.45, height * 0.75):
            g.add("Details", 0, y, -size / 2 - 0.02, 0.3, 1.3, 0.05, BLACK)
    flag(loc, x, z, height, RED, NAVY, flag_yaw)


def build_obc():
    """OBC Elst Fort: the school inside a red brick fort. High walls with
    battlements and banners, towers with flags, a gatehouse with a raised
    portcullis, and the football pitch with floodlights and dugouts."""
    loc = Location("OBCFort")
    brick = (0.62, 0.2, 0.18)
    loc.add("Details", 0, 0.03, -8, 30, 0.03, 20, (0.28, 0.5, 0.25))
    for x0, z0, x1, z1 in ((-14, -17.5, 14, -17.5), (-14, 1.5, 14, 1.5), (-14, -17.5, -14, 1.5), (14, -17.5, 14, 1.5), (-14, -8, 14, -8),
                           (-4, -17.5, -4, -13.5), (4, -17.5, 4, -13.5), (-4, -13.5, 4, -13.5), (-4, 1.5, -4, -2.5), (4, 1.5, 4, -2.5),
                           (-4, -2.5, 4, -2.5), (-1.5, -9.5, 1.5, -9.5), (-1.5, -6.5, 1.5, -6.5), (-1.5, -9.5, -1.5, -6.5), (1.5, -9.5, 1.5, -6.5)):
        loc.add("Details", (x0 + x1) / 2, 0.05, (z0 + z1) / 2, max(abs(x1 - x0), 0.12), 0.01, max(abs(z1 - z0), 0.12), WHITE)
    for z, back in ((-17.5, -1), (1.5, 1)):
        for dx in (-3.6, 3.6):
            loc.add("Solids", dx, 1.1, z, 0.12, 2.2, 0.12, WHITE)
        loc.add("Details", 0, 2.2, z, 7.3, 0.12, 0.12, WHITE)
        loc.add("Glass", 0, 1.1, z + back * 0.7, 7.2, 2.1, 1.4, (0.95, 0.95, 0.95, 0.35))
    for x in (-18.5, 18.5):
        g = loc.group(x, -8, math.pi / 2 if x < 0 else -math.pi / 2)
        g.add("Solids", 0, 1.1, 0.7, 4, 2.2, 0.1, NAVY)
        g.add("Details", 0, 2.25, 0, 4.2, 0.1, 1.6, NAVY)
        g.add("Glass", 0, 1.3, -0.75, 4, 1.8, 0.05, (0.7, 0.8, 0.95, 0.35))
        g.add("Details", 0, 0.45, 0.3, 3.6, 0.08, 0.5, RED)
    for x, z in ((-16, -18.5), (16, -18.5), (-16, 2.5), (16, 2.5)):
        loc.add("Solids", x, 6, z, 0.3, 12, 0.3, STEEL)
        loc.add("Glow", x, 12, z, 1.8, 1.0, 0.3, LAMP)
    loc.add("Details", -12, 4.0, -20.2, 5.2, 2.0, 0.2, BLACK)
    loc.label("Scoreboard", (-12, 4.0, -20.08), 0.0, "OBC  9 - 0  ELST", RED, font=56, pixel=0.008, outline=WHITE)
    # The school: light walls, a red band, a navy entrance canopy and bikes.
    loc.house("School", (0, 0, 12), (36, 10, 14), (0.86, 0.84, 0.8), NAVY)
    loc.add("Details", 0, 9.3, 4.95, 36.2, 0.8, 0.1, RED)
    loc.add("Details", 0, 3.4, 3.6, 8, 0.3, 3, NAVY)
    for x in (-3.8, 3.8):
        loc.add("Solids", x, 1.7, 2.3, 0.3, 3.4, 0.3, NAVY)
    loc.label("Sign", (0, 7.5, 4.8), math.pi, "OBC ELST", RED, font=160, pixel=0.02, outline=WHITE)
    rng = random.Random(3)
    for i in range(6):
        bike(loc, 8 + i * 0.9, 3.4, math.pi / 2 + rng.uniform(-0.1, 0.1), rng.choice([RED, NAVY, BLACK]))
    # The fort: curtain walls with battlements and banners, towers and a gatehouse.
    for x0, x1 in ((-21, -6), (6, 21)):
        loc.add("Solids", (x0 + x1) / 2, 2.5, -21, x1 - x0, 5, 1.4, brick)
        loc.add("Details", (x0 + x1) / 2, 4.6, -21.72, x1 - x0, 0.3, 0.05, NAVY)
        battlements(loc, x0 + 0.5, -21, x1 - 0.5, -21, 5, brick)
    for x in (-24.3, 24.3):
        loc.add("Solids", x, 2.5, -7.5, 1.4, 5, 20, brick)
        battlements(loc, x, -17, x, 2, 5, brick)
    for x in (-13, 13):
        loc.add("Details", x, 3.0, -21.75, 1.4, 3.2, 0.08, RED)
        loc.add("Details", x, 3.0, -21.8, 0.4, 3.2, 0.08, NAVY)
    fort_tower(loc, -23.5, -19.5, 5, 9, 0.0)
    fort_tower(loc, 23.5, -19.5, 5, 9, math.pi)
    fort_tower(loc, -21, 6, 7, 14, 0.0)
    fort_tower(loc, 21, 6, 7, 14, math.pi)
    for x in (-4.5, 4.5):
        loc.add("Solids", x, 4, -20.5, 3, 8, 3, brick)
        battlements(loc, x - 1.1, -21.6, x + 1.1, -21.6, 8, brick, merlon=0.8, every=1.1, depth=0.8)
    loc.add("Solids", 0, 7, -20.5, 6, 2, 3, brick)
    loc.add("Details", 0, 7.1, -22.05, 5.6, 1.1, 0.1, RED)
    loc.label("GateSign", (0, 7.1, -22.12), math.pi, "OBC ELST FORT", WHITE, font=56, pixel=0.01, outline=NAVY)
    for i in range(9):
        loc.add("Details", -2.8 + i * 0.7, 5.5, -21.2, 0.12, 1.2, 0.12, BLACK)
    for y in (5.2, 5.8):
        loc.add("Details", 0, y, -21.2, 6, 0.1, 0.12, BLACK)
    loc.door("SchoolDoor", (0, 0, 4.85), "OBC Elst Fort binnengaan", NAVY, "res://scenes/dungeons/OBC.tscn")
    loc.markers("OBCExit", (0, 0, 1), (0, 0, 2), "fatbike_kindje")
    loc.write("OBCFort.tscn", "obc_fort", "OBC Elst Fort", (0, 12, -2), (54, 25, 50))


def scooter(loc, x, z, yaw, c):
    g = loc.group(x, z, yaw)
    g.add("Solids", 0, 0.35, 0, 0.62, 0.35, 1.3, c)
    g.add("Details", 0, 0.8, 0.3, 0.5, 0.55, 0.45, BLACK)
    g.add("Details", 0, 0.85, -0.55, 0.08, 0.7, 0.08, DARK)
    g.add("Details", 0, 1.2, -0.55, 0.5, 0.06, 0.06, DARK)
    g.add("Details", 0, 0.75, -0.75, 0.4, 0.3, 0.3, STEEL)
    for dx in (-0.3, 0.3):
        for dz in (-0.45, 0.45):
            g.add("Details", dx, 0.13, dz, 0.12, 0.26, 0.26, BLACK)
    g.add("Details", 0.22, 1.2, 0.55, 0.03, 1.2, 0.03, DARK)
    g.add("Details", 0.36, 1.68, 0.55, 0.28, 0.2, 0.02, AMBER)


def build_bingo():
    """The Bingo Club: a blue club house whose door is a cave mouth of rocks
    and stalactites, under a big BINGO sign with light bulbs. Striped
    awnings and flower boxes, and a car park with mobility scooters, the
    Bingo Express minibus and a giant bingo ball."""
    loc = Location("BingoClub")
    rng = random.Random(4)
    rock = (0.45, 0.43, 0.42)
    loc.add("Details", 0, 0.02, -20, 32, 0.04, 16, (0.33, 0.33, 0.35))
    for i in range(8):
        x = -14 + i * 2.8 if i < 4 else 14 - (i - 4) * 2.8
        loc.add("Details", x, 0.05, -15.5, 0.12, 0.01, 4.5, WHITE)
        loc.add("Details", x, 0.05, -24.5, 0.12, 0.01, 4.5, WHITE)
    loc.house("Hall", (0, 0, 2), (28, 7, 18), (0.26, 0.43, 0.78), PINK, roof_height=3)
    loc.add("Details", 0, 0.4, -7.06, 28.2, 0.8, 0.1, (0.45, 0.22, 0.18))
    # The cave mouth round the door.
    for side in (-1, 1):
        for dx, y, dz, sx, sy, sz, yaw in ((2.6, 1.2, -8.6, 1.8, 2.4, 2.6, 0.2), (3.4, 3.1, -8.3, 1.7, 2.0, 2.2, -0.3), (2.5, 4.6, -8.8, 1.4, 1.4, 1.8, 0.5),
                                           (4.6, 0.8, -8.0, 1.5, 1.6, 1.8, 0.4)):
            loc.add("Solids", side * dx, y, dz, sx, sy, sz, rock, side * yaw)
        loc.add("Details", side * 3.0, 2.2, -9.8, 0.8, 0.4, 0.1, GREEN)
    for x, y, z, sx, sy, sz, yaw in ((0, 5.5, -8.6, 6.8, 1.6, 2.6, 0.0), (-1.3, 6.5, -8.2, 2.4, 1.0, 2.0, 0.3), (1.7, 6.3, -8.8, 2.0, 0.8, 1.6, -0.4)):
        loc.add("Solids", x, y, z, sx, sy, sz, rock, yaw)
    for x, length in ((-1.3, 0.8), (-0.4, 0.5), (0.6, 0.9), (1.4, 0.6)):
        loc.add("Details", x, 4.7 - length / 2, -9.5, 0.3, length, 0.3, (0.4, 0.38, 0.36))
    loc.add("Details", 0, 5.5, -9.95, 3.2, 0.6, 0.08, WOOD)
    loc.label("CaveSign", (0, 5.5, -10.0), math.pi, "BOOMER CAVE", WHITE, font=48, pixel=0.007)
    # The BINGO sign with a border of light bulbs.
    loc.add("Details", 0, 8.6, -7.1, 11, 2.8, 0.25, NAVY)
    for i in range(16):
        x = -5.2 + i * 0.7
        loc.add("Glow", x, 9.85, -7.25, 0.2, 0.2, 0.06, YELLOW)
        loc.add("Glow", x, 7.35, -7.25, 0.2, 0.2, 0.06, YELLOW)
    for y in (8.2, 9.0):
        for x in (-5.4, 5.4):
            loc.add("Glow", x, y, -7.25, 0.2, 0.2, 0.06, YELLOW)
    loc.label("Sign", (0, 8.6, -7.28), math.pi, "BINGO", PINK, font=200, pixel=0.012, outline=(0.4, 0.1, 0.3))
    for x0 in (-12, 5):
        for i in range(10):
            loc.add("Details", x0 + 0.35 + i * 0.7, 3.2, -7.7, 0.7, 0.15, 1.3, PINK if i % 2 == 0 else WHITE)
        loc.add("Details", x0 + 3.5, 1.0, -7.35, 6, 0.4, 0.5, GREEN)
        for i in range(12):
            loc.add("Details", x0 + 0.3 + i * 0.55, 1.3, -7.35, 0.18, 0.18, 0.18, RED if i % 3 else YELLOW)
    bench(loc, -8.5, -9.6, 0, (0.3, 0.45, 0.8))
    bench(loc, 8.5, -9.6, 0, (0.3, 0.45, 0.8))
    for x in (-3.6, 3.6):
        g = loc.group(x, -10.8, rng.uniform(-0.3, 0.3))
        for dx in (-0.25, 0.25):
            g.add("Details", dx, 0.45, 0, 0.04, 0.9, 0.04, STEEL)
        g.add("Details", 0, 0.9, 0, 0.55, 0.04, 0.04, RED)
        g.add("Details", 0, 0.5, 0.1, 0.45, 0.25, 0.3, (0.3, 0.3, 0.6))
    # The car park.
    for x, c in ((-12.6, RED), (-9.8, (0.3, 0.45, 0.85)), (9.8, (0.25, 0.6, 0.35))):
        scooter(loc, x, -15.5, 0.0, c)
    g = loc.group(12.6, -23.5, 0.0)
    g.add("Solids", 0, 1.35, 0, 2.2, 2.3, 5.5, WHITE)
    g.add("Details", 0, 1.2, 0, 2.22, 0.4, 5.52, PINK)
    g.add("Glass", 0, 1.95, -0.4, 2.24, 0.7, 4.0, (0.2, 0.25, 0.3, 0.8))
    for dx in (-1.0, 1.0):
        for dz in (-1.9, 1.9):
            g.add("Details", dx, 0.35, dz, 0.3, 0.7, 0.7, BLACK)
    loc.label("BusLabel", (11.48, 1.2, -23.5), -math.pi / 2, "BINGO EXPRESS", NAVY, font=40, pixel=0.008, outline=WHITE)
    loc.ground("Solids", -11, -24, 1.6, 0.8, 1.6, (0.85, 0.8, 0.9))
    loc.add("Solids", -11, 1.6, -24, 1.4, 1.4, 1.4, WHITE, 0.5)
    loc.add("Details", -11, 1.6, -24, 1.5, 0.3, 1.5, PINK, 0.5)
    loc.label("BallNumber", (-11.15, 1.6, -24.75), math.pi, "B-12", NAVY, font=72, pixel=0.008, outline=WHITE)
    for x0, x1 in ((-15, -4), (4, 15)):
        loc.ground("Solids", (x0 + x1) / 2, -27.6, x1 - x0, 1.0, 0.8, (0.18, 0.36, 0.2))
    for x in (-15.6, 15.6):
        loc.ground("Solids", x, -19.5, 0.8, 1.0, 15, (0.18, 0.36, 0.2))
    for x, z in ((-14, -26.5), (14, -26.5), (-14, -12.5), (14, -12.5)):
        lamp_post(loc, x, z)
    loc.door("CaveDoor", (0, 0, -9.9), "Bingo Club Boomer Cave binnengaan", (0.14, 0.2, 0.42), "res://scenes/dungeons/BingoCave.tscn")
    loc.markers("BingoExit", (0, 0, -14), (0, 0, -13), "grumpy_oma")
    loc.write("BingoClub.tscn", "bingo_club", "Bingo Club Boomer Cave", (0, 10, -6), (40, 20, 44))


def build_kerk_decor():
    """The church of Amber: buttresses and stained glass along the nave, a
    portal with braziers, clocks, a belfry and a rose window on the tower,
    and a churchyard with graves, benches and lamps round the square."""
    loc = Location("KerkDecor")
    rng = random.Random(5)
    stone = (0.7, 0.66, 0.6)
    glass = [AMBER, (0.85, 0.2, 0.2), (0.25, 0.4, 0.9), (0.6, 0.3, 0.8), YELLOW]
    for x in (-7.5, 7.5):
        for z in range(-8, 19, 5):
            loc.add("Solids", x, 3.5, z, 1.0, 7, 1.6, stone)
        for z in range(-6, 17, 5):
            loc.add("Glow", x * 0.937, 5.2, z + 0.5, 0.1, 4.2, 1.4, rng.choice(glass))
            loc.add("Details", x * 0.937, 7.45, z + 0.5, 0.12, 0.3, 1.6, stone)
    for dx in (-1.9, 1.9):
        loc.add("Solids", dx, 2.1, -17.85, 0.6, 4.2, 0.6, stone)
    loc.add("Details", 0, 4.5, -17.85, 4.4, 0.8, 0.6, stone)
    loc.add("Details", 0, 0.03, -19.6, 6, 0.05, 3.2, stone)
    loc.add("Glow", 0, 10.5, -17.56, 2.6, 2.6, 0.08, (0.95, 0.5, 0.15))
    loc.add("Details", 0, 10.5, -17.6, 3.0, 3.0, 0.06, stone)
    loc.add("Glow", 0, 13.6, -17.58, 1.2, 1.2, 0.06, AMBER, math.pi / 4)
    for x in (-3.6, 3.6):
        loc.ground("Solids", x, -19.6, 0.8, 1.0, 0.8, DARK)
        loc.add("Details", x, 1.1, -19.6, 1.1, 0.2, 1.1, DARK)
        loc.add("Glow", x, 1.45, -19.6, 0.6, 0.5, 0.6, (1.0, 0.5, 0.1))
    loc.light("BrazierLight", (0, 2.5, -20.5), (1.0, 0.55, 0.2), 2.0, 9.0)
    for yaw in (math.pi, math.pi / 2, -math.pi / 2):
        g = loc.group(0, -13, yaw, 26)
        g.add("Details", 0, 0, 4.53, 3.0, 3.0, 0.08, WHITE)
        g.add("Details", 0, 0, 4.55, 3.3, 3.3, 0.05, YELLOW)
        g.add("Details", 0, 0.5, 4.6, 0.15, 1.1, 0.05, BLACK)
        g.add("Details", 0.35, 0, 4.6, 0.8, 0.15, 0.05, BLACK)
    for yaw in (0.0, math.pi / 2, math.pi, -math.pi / 2):
        g = loc.group(0, -13, yaw, 30.5)
        for dx in (-1.6, 1.6):
            g.add("Details", dx, 0, -4.53, 1.2, 3.0, 0.06, BLACK)
    loc.add("Details", 0, 50.2, -13, 0.5, 0.5, 0.5, YELLOW)
    # Churchyard behind and beside the nave, with a low stone wall.
    for x0 in (-20, 10):
        for row in range(3):
            for col in range(4):
                x, z = x0 + col * 2.6, 6 + row * 4
                loc.ground("Solids", x, z, 0.9, rng.uniform(0.9, 1.4), 0.25, (0.55, 0.55, 0.57), yaw=rng.uniform(-0.15, 0.15))
                loc.add("Details", x, 0.04, z + 1.1, 0.9, 0.05, 1.8, GREEN)
    for x0, x1 in ((-21.5, -9), (9, 21.5)):
        loc.ground("Solids", (x0 + x1) / 2, 2.8, x1 - x0, 0.7, 0.5, stone)
    # The square: benches, lamps and paving lines.
    for i in range(-22, 23, 4):
        loc.add("Details", i, 0.04, -20, 0.08, 0.01, 6, (0.55, 0.52, 0.5))
    for x, z, yaw in ((-12, -10, math.pi / 2), (12, -10, -math.pi / 2), (-12, -2, math.pi / 2), (12, -2, -math.pi / 2)):
        bench(loc, x, z, yaw)
    for x, z in ((-9, -21), (9, -21), (-14, -6), (14, -6)):
        lamp_post(loc, x, z, 4.2)
    loc.write("KerkDecor.tscn")


def build_klaas_decor():
    """Klaas' house in purple and gold: a porch with gold columns, gold trim,
    a chimney, flower beds, an outdoor gym, a purple car, a barbecue, a
    mailbox and a flag. The practice yard in front stays free."""
    loc = Location("KlaasHouseDecor")
    gold = (0.95, 0.75, 0.2)
    purple = (0.46, 0.29, 0.66)
    loc.add("Details", 0, 3.1, -2.6, 5.4, 0.3, 2.2, purple)
    loc.add("Details", 0, 3.3, -3.65, 5.5, 0.15, 0.1, gold)
    for x in (-2.4, 2.4):
        loc.add("Solids", x, 1.5, -3.4, 0.3, 3.0, 0.3, gold)
    loc.label("Emblem", (0, 4.2, -1.62), math.pi, "K", gold, font=160, pixel=0.012)
    loc.add("Details", 0, 7.9, -1.56, 14.2, 0.3, 0.1, gold)
    loc.add("Solids", 4, 10.8, 6, 1.0, 3.2, 1.0, (0.45, 0.22, 0.18))
    for x0 in (-6.5, 3.2):
        loc.ground("Details", x0 + 1.65, -2.2, 3.3, 0.35, 0.8, (0.4, 0.26, 0.16))
        for i in range(6):
            loc.add("Details", x0 + 0.3 + i * 0.55, 0.45, -2.2, 0.2, 0.2, 0.2, [RED, YELLOW, PINK, gold][i % 4])
    for z in (-12, -8, -4):
        for x in (-1.6, 1.6):
            loc.ground("Details", x, z, 0.12, 0.6, 0.12, DARK)
            loc.add("Glow", x, 0.65, z, 0.22, 0.12, 0.22, LAMP)
    # Outdoor gym on the left of the house.
    g = loc.group(-11.5, 3, 0)
    g.add("Solids", 0, 0.45, 0, 0.5, 0.15, 1.6, BLACK)
    for dz in (-0.6, 0.6):
        g.add("Details", 0, 0.22, dz, 0.4, 0.44, 0.1, DARK)
    for dx in (-0.6, 0.6):
        g.add("Details", dx, 0.75, -0.65, 0.08, 0.9, 0.08, STEEL)
    g.add("Details", 0, 1.15, -0.65, 2.2, 0.06, 0.06, STEEL)
    for dx in (-0.9, 0.9):
        g.add("Details", dx, 1.15, -0.65, 0.12, 0.6, 0.6, BLACK)
    for dx in (-1.2, 1.2):
        g.add("Solids", dx, 1.4, 2.6, 0.12, 2.8, 0.12, DARK)
    g.add("Details", 0, 2.75, 2.6, 2.5, 0.08, 0.08, STEEL)
    for i in range(4):
        g.add("Details", -0.9 + i * 0.6, 0.15, -2.2, 0.3, 0.3, 0.3, BLACK)
    loc.label("GymSign", (-11.5, 3.4, 5.55), math.pi, "SIGMA GYM", gold, font=48, pixel=0.008)
    # A purple car, a barbecue with a parasol, a mailbox and a flag.
    car(loc, 12, -11, 0.0, purple)
    loc.add("Details", 12, 0.71, -11, 0.4, 0.02, 4.2, gold)
    g = loc.group(11, 3, 0)
    g.add("Solids", 0, 0.8, 0, 0.9, 0.12, 0.6, DARK)
    g.add("Details", 0, 0.4, 0, 0.1, 0.8, 0.1, DARK)
    g.add("Glow", 0, 0.9, 0, 0.7, 0.05, 0.4, (1.0, 0.4, 0.1))
    g.add("Solids", 2.5, 0.75, 0, 1.4, 0.08, 1.4, WHITE)
    g.add("Details", 2.5, 1.4, 0, 0.06, 2.8, 0.06, STEEL)
    g.add("Details", 2.5, 2.8, 0, 2.6, 0.12, 2.6, purple)
    g.add("Details", 2.5, 2.9, 0, 1.4, 0.12, 1.4, gold)
    loc.ground("Details", -3.4, -16.6, 0.1, 1.1, 0.1, DARK)
    loc.add("Solids", -3.4, 1.25, -16.6, 0.5, 0.4, 0.6, purple)
    loc.add("Details", -3.12, 1.4, -16.5, 0.04, 0.3, 0.12, gold)
    flag(loc, -13, -13, 0, purple, gold)
    for x in (-2.6, 2.6):
        loc.add("Details", x, 1.3, -16, 0.6, 0.2, 0.6, gold)
    loc.write("KlaasHouseDecor.tscn")


if __name__ == "__main__":
    build_kerk_decor()
    build_klaas_decor()
    build_station()
    build_westeraam()
    build_obc()
    build_bingo()
