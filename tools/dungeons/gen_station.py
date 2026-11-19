"""Builds scenes/dungeons/Station.tscn: the station dungeon of Quest 2.

Run from the project root: python3 tools/dungeons/gen_station.py

Five rooms from south to north: the station hall (entrance), the platform
hall with a parked wagon, a workshop off to the west, the track tunnel and
Amber's supply depot, which is heavily guarded. Each of the last four holds
one of the four generators. +x is east, -z is north (deeper in).
"""
import pathlib

OUT = pathlib.Path("scenes/dungeons/Station.tscn")
HEIGHT = 5.0

# name: (x0, x1, z0, z1, wall colour, height), doors per side as (centre, width).
# A side set to None has no wall: the neighbouring room builds it.
ROOMS = {
    "Hall": ((-10, 10, 0, 20), (0.33, 0.45, 0.38), HEIGHT,
             {"N": [(0, 4)], "S": [], "W": [], "E": []}),
    "Platform": ((-14, 14, -36, 0), (0.55, 0.52, 0.45), HEIGHT,
                 {"N": [(8, 8)], "S": [(0, 21)], "W": [(-20, 4)], "E": []}),
    "Workshop": ((-30, -14, -28, -12), (0.5, 0.42, 0.32), HEIGHT,
                 {"N": [], "S": [], "W": [], "E": None}),
    "Tunnel": ((4, 12, -66, -36), (0.22, 0.2, 0.19), 4.5,
               {"N": None, "S": None, "W": [], "E": []}),
    "Depot": ((-6, 26, -94, -66), (0.36, 0.26, 0.18), 6.0,
              {"N": [], "S": [(8, 8)], "W": [], "E": []}),
}
FLOOR = (0.42, 0.42, 0.4)
CEILING = (0.17, 0.17, 0.19)
AMBER = (0.95, 0.58, 0.14)
WOOD = (0.5, 0.36, 0.22)
STEEL = (0.45, 0.45, 0.48)
YELLOW = (0.9, 0.8, 0.2)
DARK = (0.2, 0.2, 0.22)

# Static props: (name, centre x, centre z, size, colour, solid)
PROPS = [
    # Station hall: ticket gates with a gap in the middle, benches and a kiosk.
    ("GateLeft", -5.5, 8, (9, 1.0, 0.4), STEEL, True),
    ("GateRight", 5.5, 8, (9, 1.0, 0.4), STEEL, True),
    ("BenchHall1", -8, 14, (0.6, 0.5, 2.4), WOOD, True),
    ("BenchHall2", 8, 14, (0.6, 0.5, 2.4), WOOD, True),
    ("Kiosk", -7, 18, (3.0, 2.6, 2.0), (0.3, 0.55, 0.4), True),
    # Platform hall: pillars, the platform edge, benches and a parked wagon.
    ("PillarA1", -6, -8, (0.8, HEIGHT, 0.8), (0.6, 0.57, 0.5), True),
    ("PillarA2", -6, -19, (0.8, HEIGHT, 0.8), (0.6, 0.57, 0.5), True),
    ("PillarA3", -6, -30, (0.8, HEIGHT, 0.8), (0.6, 0.57, 0.5), True),
    ("PillarB1", 2, -8, (0.8, HEIGHT, 0.8), (0.6, 0.57, 0.5), True),
    ("PillarB2", 2, -19, (0.8, HEIGHT, 0.8), (0.6, 0.57, 0.5), True),
    ("PillarB3", 2, -30, (0.8, HEIGHT, 0.8), (0.6, 0.57, 0.5), True),
    ("PlatformEdge", 5, -18, (0.3, 0.03, 36), YELLOW, False),
    ("BenchPlatform1", -11, -12, (0.6, 0.5, 2.4), WOOD, True),
    ("BenchPlatform2", -11, -24, (0.6, 0.5, 2.4), WOOD, True),
    ("Wagon", 8, -22, (3.0, 3.4, 13), AMBER, True),
    ("WagonRoof", 8, -22, (3.2, 0.2, 13.2), DARK, False),
    # Workshop: benches, shelves and crates.
    ("Workbench", -29, -20, (1.2, 1.0, 5), WOOD, True),
    ("Shelf", -22, -27.4, (6, 2.4, 0.8), STEEL, True),
    ("CrateW1", -16.5, -26, (1.2, 1.2, 1.2), WOOD, True),
    ("CrateW2", -16.5, -14.5, (1.2, 1.2, 1.2), WOOD, True),
    # Depot: stacks of supply crates, a locomotive and a raised platform for
    # the last generator.
    ("Locomotive", 22, -80, (3.2, 3.6, 12), (0.3, 0.3, 0.32), True),
    ("LocoStripe", 22, -80, (3.24, 0.4, 12.04), AMBER, False),
    ("CrateD1", -1, -72, (1.6, 1.6, 1.6), WOOD, True),
    ("CrateD2", 0.5, -72.5, (1.4, 2.8, 1.4), WOOD, True),
    ("CrateD3", 15, -73, (1.6, 1.6, 3.2), WOOD, True),
    ("CrateD4", 4, -84, (2.4, 1.6, 1.6), WOOD, True),
    ("CrateD5", 14, -86, (1.6, 2.4, 1.6), WOOD, True),
    ("CrateD6", -3, -86, (1.6, 1.6, 1.6), WOOD, True),
    ("Dais", 8, -90.5, (8, 0.3, 5), DARK, True),
]
# Rails run from the platform hall through the tunnel into the depot.
RAIL_X = 8.0
RAIL_Z = (-87.5, -1.0)
# Labels: (name, x, y, z, yaw, text, colour)
LABELS = [
    ("SignHall", 0, 4.0, 0.55, 0, "Station Elst", (0.3, 0.75, 0.45)),
    ("SignWagon", 6.45, 2.2, -22, -1.5708, "AMBER EXPRESS", (0.1, 0.1, 0.1)),
    ("SignDepot", 8, 4.6, -93.45, 0, "AANVOERDEPOT VAN AMBER", AMBER),
    ("LabelCrate1", -1, 1.0, -71.15, 0, "TREN", (0.1, 0.1, 0.1)),
    ("LabelCrate2", 14, 1.4, -85.15, 0, "EIWIT", (0.1, 0.1, 0.1)),
]
# Lights: (name, x, y, z, colour, energy, range)
LIGHTS = [
    ("LightHall1", 0, 4.2, 14, (0.72, 0.88, 0.76), 1.6, 13),
    ("LightHall2", 0, 4.2, 4, (0.72, 0.88, 0.76), 1.4, 12),
    ("LightPlatform1", -4, 4.2, -6, (1.0, 0.86, 0.66), 1.5, 13),
    ("LightPlatform2", -4, 4.2, -18, (1.0, 0.86, 0.66), 1.5, 13),
    ("LightPlatform3", -4, 4.2, -30, (1.0, 0.86, 0.66), 1.5, 13),
    ("LightTrack", 9, 4.2, -10, (1.0, 0.86, 0.66), 1.2, 11),
    ("LightWorkshop", -22, 4.2, -20, (1.0, 0.75, 0.5), 1.6, 13),
    ("LightTunnel1", 8, 3.8, -42, (1.0, 0.35, 0.25), 1.3, 9),
    ("LightTunnel2", 8, 3.8, -52, (1.0, 0.35, 0.25), 1.3, 9),
    ("LightTunnel3", 8, 3.8, -62, (1.0, 0.35, 0.25), 1.3, 9),
    ("LightDepot1", 2, 5.4, -72, (1.0, 0.62, 0.3), 1.8, 15),
    ("LightDepot2", 16, 5.4, -72, (1.0, 0.62, 0.3), 1.8, 15),
    ("LightDepot3", 2, 5.4, -87, (1.0, 0.62, 0.3), 1.8, 15),
    ("LightDepot4", 16, 5.4, -87, (1.0, 0.62, 0.3), 1.8, 15),
]
# Generators: (name, x, z, yaw); the glowing front (local -z) faces the way in.
GENERATORS = [
    ("Generator1", -10, -33.5, 3.14159),
    ("Generator2", -27.5, -25, -2.3562),
    ("Generator3", 5.1, -51, -1.5708),
    ("Generator4", 8, -91, 3.14159),
]
# Laag drillers in groups of two or three; the depot holds six.
ENEMIES = [
    ("Hall1", -4, 3, 0), ("Hall2", 3.5, 2, 0.3),
    ("Platform1", -3, -21, 0.4), ("Platform2", 0, -25, 0), ("Platform3", -8, -26, -0.3),
    ("Workshop1", -21, -17, 1.2), ("Workshop2", -24, -14, 1.6),
    ("Tunnel1", 8, -44, 0), ("Tunnel2", 8, -60, 3.14159),
    ("Depot1", 2, -76, 0), ("Depot2", 6, -78, 0.3), ("Depot3", -1, -80, -0.3),
    ("Depot4", 13, -82, 0.2), ("Depot5", 18, -77, 0.6), ("Depot6", 10, -86, 0),
]
CHESTS = [("ChestWorkshop", -28.5, -14, -1.5708), ("ChestDepot", -4, -92, 0.7854)]


def f(v):
    s = f"{v:.4f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def vec(*v):
    return "Vector3(" + ", ".join(f(c) for c in v) + ")"


def col(c):
    return f"Color({f(c[0])}, {f(c[1])}, {f(c[2])}, 1)"


subs = []
_materials = {}
_meshes = {}
_shapes = {}


def material(c):
    if c not in _materials:
        mid = f"Mat_{len(_materials) + 1}"
        _materials[c] = mid
        subs.append([f'[sub_resource type="StandardMaterial3D" id="{mid}"]', f"albedo_color = {col(c)}", "roughness = 0.9"])
    return _materials[c]


def box_mesh(size, c):
    key = (tuple(round(v, 3) for v in size), c)
    if key not in _meshes:
        mid = f"Box_{len(_meshes) + 1}"
        _meshes[key] = mid
        subs.append([f'[sub_resource type="BoxMesh" id="{mid}"]', f'material = SubResource("{material(c)}")', f"size = {vec(*size)}"])
    return _meshes[key]


def box_shape(size):
    key = tuple(round(v, 3) for v in size)
    if key not in _shapes:
        sid = f"Shape_{len(_shapes) + 1}"
        _shapes[key] = sid
        subs.append([f'[sub_resource type="BoxShape3D" id="{sid}"]', f"size = {vec(*size)}"])
    return _shapes[key]


nodes = []


def solid(parent, name, pos, size, c):
    nodes.append([f'[node name="{name}" type="StaticBody3D" parent="{parent}"]', f"position = {vec(*pos)}"])
    nodes.append([f'[node name="CollisionShape3D" type="CollisionShape3D" parent="{parent}/{name}"]', f'shape = SubResource("{box_shape(size)}")'])
    nodes.append([f'[node name="Mesh" type="MeshInstance3D" parent="{parent}/{name}"]', f'mesh = SubResource("{box_mesh(size, c)}")'])


def visual(parent, name, pos, size, c):
    nodes.append([f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]', f"position = {vec(*pos)}",
                  f'mesh = SubResource("{box_mesh(size, c)}")'])


def wall_segments(a0, a1, doors):
    """Pieces of a wall from a0 to a1 along its axis, leaving the doors open."""
    cuts = sorted((c - w / 2, c + w / 2) for c, w in doors)
    pieces, start = [], a0
    for lo, hi in cuts:
        if lo > start:
            pieces.append((start, lo))
        start = max(start, hi)
    if a1 > start:
        pieces.append((start, a1))
    return [(lo, hi) for lo, hi in pieces if hi - lo > 0.05]


def lintel(room, side, n, centre, width, height, colour, along_x):
    """The wall above a door: 3.2 m high doors, 4.5 m for the track."""
    if width > 8:
        return
    top = 3.2 if width <= 4 else 4.5
    if top >= height:
        return
    size = (width, height - top, 1) if along_x else (1, height - top, width)
    solid("Structure", f"{room}Lintel{side}{n}", (centre[0], (top + height) / 2, centre[1]), size, colour)


def build_rooms():
    nodes.append(['[node name="Structure" type="Node3D" parent="." groups=["navigation_source"]]'])
    for name, ((x0, x1, z0, z1), wall_color, height, sides) in ROOMS.items():
        solid("Structure", f"{name}Floor", ((x0 + x1) / 2, -0.5, (z0 + z1) / 2), (x1 - x0, 1, z1 - z0), FLOOR)
        solid("Structure", f"{name}Ceiling", ((x0 + x1) / 2, height + 0.5, (z0 + z1) / 2), (x1 - x0, 1, z1 - z0), CEILING)
        for side, doors in sides.items():
            if doors is None:
                continue
            # North and south walls cover the corners; west and east walls fit
            # in between. Where a neighbour owns a wall, stop at its face.
            if side in ("N", "S"):
                z = z0 if side == "N" else z1
                a0 = x0 - 0.5 if sides["W"] is not None else x0 + 0.5
                a1 = x1 + 0.5 if sides["E"] is not None else x1 - 0.5
                for n, (lo, hi) in enumerate(wall_segments(a0, a1, doors)):
                    solid("Structure", f"{name}Wall{side}{n}", ((lo + hi) / 2, height / 2, z), (hi - lo, height, 1), wall_color)
                for n, (centre, width) in enumerate(doors):
                    lintel(name, side, n, (centre, z), width, height, wall_color, along_x=True)
            else:
                x = x0 if side == "W" else x1
                for n, (lo, hi) in enumerate(wall_segments(z0 + 0.5, z1 - 0.5, doors)):
                    solid("Structure", f"{name}Wall{side}{n}", (x, height / 2, (lo + hi) / 2), (1, height, hi - lo), wall_color)
                for n, (centre, width) in enumerate(doors):
                    lintel(name, side, n, (x, centre), width, height, wall_color, along_x=False)
    for name, x, z, size, c, is_solid in PROPS:
        pos = (x, size[1] / 2 + (0.01 if not is_solid else 0), z)
        (solid if is_solid else visual)("Structure", name, pos, size, c)


def build_details():
    nodes.append(['[node name="Track" type="Node3D" parent="."]'])
    length = RAIL_Z[1] - RAIL_Z[0]
    centre = (RAIL_Z[0] + RAIL_Z[1]) / 2
    visual("Track", "Bed", (RAIL_X, 0.02, centre), (3.0, 0.04, length), (0.3, 0.27, 0.24))
    for name, dx in (("RailLeft", -0.72), ("RailRight", 0.72)):
        visual("Track", name, (RAIL_X + dx, 0.1, centre), (0.12, 0.14, length), STEEL)
    for name, x, y, z, yaw, text, c in LABELS:
        nodes.append([f'[node name="{name}" type="Label3D" parent="."]', f"position = {vec(x, y, z)}", f"rotation = {vec(0, yaw, 0)}",
                      "pixel_size = 0.01", f"modulate = {col(c)}", "outline_modulate = Color(0, 0, 0, 1)", f'text = "{text}"',
                      "font_size = 64", "outline_size = 12"])
    for name, x, y, z, c, energy, rng in LIGHTS:
        nodes.append([f'[node name="{name}" type="OmniLight3D" parent="."]', f"position = {vec(x, y, z)}", f"light_color = {col(c)}",
                      f"light_energy = {f(energy)}", f"omni_range = {f(rng)}"])


def main():
    build_rooms()
    build_details()
    head = ['[gd_scene format=3]', '',
            '[ext_resource type="Script" path="res://scenes/world/game_world.gd" id="1_world"]',
            '[ext_resource type="PackedScene" path="res://scenes/player/Player.tscn" id="2_player"]',
            '[ext_resource type="PackedScene" path="res://scenes/world/props/DungeonEntrance.tscn" id="3_door"]',
            '[ext_resource type="Script" path="res://scripts/quests/quest_marker.gd" id="4_marker"]',
            '[ext_resource type="Script" path="res://scenes/world/runtime_navigation_region.gd" id="20_nav"]',
            '[ext_resource type="PackedScene" path="res://scenes/enemies/LowDriller.tscn" id="21_enemy"]',
            '[ext_resource type="PackedScene" path="res://scenes/world/props/Chest.tscn" id="22_chest"]',
            '[ext_resource type="Script" path="res://scenes/world/props/generator_group.gd" id="23_group"]',
            '[ext_resource type="PackedScene" path="res://scenes/world/props/Generator.tscn" id="24_generator"]', '',
            '[sub_resource type="Environment" id="Environment_dungeon"]', 'background_mode = 1',
            'background_color = Color(0.03, 0.03, 0.04, 1)', 'ambient_light_source = 2',
            'ambient_light_color = Color(0.3, 0.42, 0.35, 1)', 'ambient_light_energy = 0.3', '',
            '[sub_resource type="NavigationMesh" id="NavigationMesh_station"]', 'geometry_parsed_geometry_type = 1',
            'geometry_collision_mask = 1', 'geometry_source_geometry_mode = 1',
            'geometry_source_group_name = &"navigation_source"', 'cell_size = 0.5', 'cell_height = 0.25',
            'agent_height = 1.75', 'agent_radius = 0.5', 'agent_max_climb = 0.5', 'agent_max_slope = 40.0',
            'filter_baking_aabb = AABB(-32, -2, -96, 60, 10, 118)', '']
    out = head[:]
    for block in subs:
        out += block + [""]
    out += ['[node name="StationDungeon" type="Node3D"]', 'script = ExtResource("1_world")', 'location_name = "Station Elst"',
            'location_id = &"station_dungeon"', "autosave_on_enter = true", "",
            '[node name="WorldEnvironment" type="WorldEnvironment" parent="."]', 'environment = SubResource("Environment_dungeon")', ""]
    for block in nodes:
        out += block + [""]
    out += ['[node name="ExitDoor" parent="." instance=ExtResource("3_door")]', "position = Vector3(0, 0, 19.25)",
            'target_scene = "res://scenes/world/Elst.tscn"', "target_spawn = &\"StationExit\"", 'prompt = "Terug naar Elst"',
            "door_color = Color(0.3, 0.7, 0.4, 1)", "",
            '[node name="MarkerExit" type="Marker3D" parent="."]', "position = Vector3(0, 0, 18)", 'script = ExtResource("4_marker")',
            "ids = Array[StringName]([&\"klaas\"])", "",
            '[node name="Entrance" type="Marker3D" parent="." groups=["spawn_points"]]', "position = Vector3(0, 0, 16)", "",
            '[node name="Player" parent="." instance=ExtResource("2_player")]', "position = Vector3(0, 0, 16)", "",
            '[node name="Navigation" type="NavigationRegion3D" parent="."]', 'navigation_mesh = SubResource("NavigationMesh_station")',
            'script = ExtResource("20_nav")', "",
            '[node name="Generators" type="Node3D" parent="." groups=["navigation_source"]]', 'script = ExtResource("23_group")',
            'completion_flag = &"station_cleared"', 'done_message = "Alle vier de generators liggen plat. Geen trein meer voor Amber. Ga terug naar Klaas."', ""]
    for n, (name, x, z, yaw) in enumerate(GENERATORS, 1):
        out += [f'[node name="{name}" parent="Generators" instance=ExtResource("24_generator")]',
                f"position = {vec(x, 0.3 if name == 'Generator4' else 0, z)}", f"rotation = {vec(0, yaw, 0)}",
                f'flag = &"station_generator_{n}"', ""]
    for name, x, z, yaw in CHESTS:
        out += [f'[node name="{name}" parent="." instance=ExtResource("22_chest")]', f"position = {vec(x, 0, z)}",
                f"rotation = {vec(0, yaw, 0)}", ""]
    out += ['[node name="Enemies" type="Node3D" parent="."]', ""]
    for name, x, z, yaw in ENEMIES:
        out += [f'[node name="LowDriller{name}" parent="Enemies" instance=ExtResource("21_enemy")]',
                f"position = {vec(x, 0, z)}", f"rotation = {vec(0, yaw, 0)}", ""]
    OUT.write_text("\n".join(out).rstrip("\n") + "\n")
    print("wrote", OUT, "with", len(GENERATORS), "generators and", len(ENEMIES), "enemies")


if __name__ == "__main__":
    main()
