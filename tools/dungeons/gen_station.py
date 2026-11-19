"""Builds scenes/dungeons/Station.tscn: the station dungeon of Quest 2.

Run from the project root: python3 tools/dungeons/gen_station.py

Five rooms from south to north: the station hall (entrance), the platform
hall with a parked wagon, a workshop off to the west, the track tunnel and
Amber's supply depot, which is heavily guarded. Each of the last four holds
one of the four generators. +x is east, -z is north (deeper in).
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from dungeon_builder import Dungeon, STEEL, vec  # noqa: E402

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
AMBER = (0.95, 0.58, 0.14)
WOOD = (0.5, 0.36, 0.22)
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


def main():
    d = Dungeon()
    d.build_rooms(ROOMS, PROPS)
    d.build_track(RAIL_X, RAIL_Z)
    d.build_labels_and_lights(LABELS, LIGHTS)
    ext = [("PackedScene", "res://scenes/enemies/LowDriller.tscn", "21_enemy"),
           ("PackedScene", "res://scenes/world/props/Chest.tscn", "22_chest"),
           ("Script", "res://scenes/world/props/generator_group.gd", "23_group"),
           ("PackedScene", "res://scenes/world/props/Generator.tscn", "24_generator")]
    extra = ['[node name="Generators" type="Node3D" parent="." groups=["navigation_source"]]', 'script = ExtResource("23_group")',
             'completion_flag = &"station_cleared"', 'done_message = "Alle vier de generators liggen plat. Geen trein meer voor Amber. Ga terug naar Klaas."', ""]
    for n, (name, x, z, yaw) in enumerate(GENERATORS, 1):
        extra += [f'[node name="{name}" parent="Generators" instance=ExtResource("24_generator")]',
                  f"position = {vec(x, 0.3 if name == 'Generator4' else 0, z)}", f"rotation = {vec(0, yaw, 0)}",
                  f'flag = &"station_generator_{n}"', ""]
    for name, x, z, yaw in CHESTS:
        extra += [f'[node name="{name}" parent="." instance=ExtResource("22_chest")]', f"position = {vec(x, 0, z)}",
                  f"rotation = {vec(0, yaw, 0)}", ""]
    extra += ['[node name="Enemies" type="Node3D" parent="."]', ""]
    for name, x, z, yaw in ENEMIES:
        extra += [f'[node name="LowDriller{name}" parent="Enemies" instance=ExtResource("21_enemy")]',
                  f"position = {vec(x, 0, z)}", f"rotation = {vec(0, yaw, 0)}", ""]
    world = {"root": "StationDungeon", "location_name": "Station Elst", "location_id": "station_dungeon",
             "ambient": (0.3, 0.42, 0.35), "nav_id": "NavigationMesh_station", "nav_aabb": (-32, -2, -96, 60, 10, 118),
             "exit": (19.25, 18, 16, "StationExit", (0.3, 0.7, 0.4))}
    d.write(OUT, world, ext, extra)
    print("wrote", OUT, "with", len(GENERATORS), "generators and", len(ENEMIES), "enemies")


if __name__ == "__main__":
    main()
