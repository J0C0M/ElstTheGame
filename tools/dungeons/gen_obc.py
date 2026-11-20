"""Builds scenes/dungeons/OBC.tscn: the OBC Elst Fort dungeon of Quest 4.

Run from the project root: python3 tools/dungeons/gen_obc.py

Two parts with a checkpoint in between, like every faction dungeon:
- part 1, the school: the big aula of the real OBC (white walls, a wooden
  sitting staircase, glass galleries and ring lamps), the canteen, a corridor
  and the gym, then the stairwell;
- the checkpoint: the staff room, quiet, with an autosave and a bench;
- part 2, behind the school: the inner square where fatbikers circle, the
  bike shed and the sports field, where the fatbike-kindje charges.
+x is east, -z is north (deeper in). OBC is a step harder than Westeraam:
more enemies, and a stronger boss.
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from dungeon_builder import Dungeon, aim_enemies, vec  # noqa: E402

OUT = pathlib.Path("scenes/dungeons/OBC.tscn")

RED = (0.8, 0.14, 0.14)
NAVY = (0.12, 0.16, 0.36)
WHITE = (0.92, 0.92, 0.9)
OAK = (0.68, 0.46, 0.26)
WOOD = (0.55, 0.4, 0.25)
STEEL = (0.45, 0.45, 0.48)
GRASS = (0.3, 0.55, 0.28)
SOFA = (0.6, 0.78, 0.6)
GLASS = (0.8, 0.9, 0.95, 0.3)

# name: ((x0, x1, z0, z1), wall colour, height, doors per side). None: the neighbour builds that wall.
ROOMS = {
    # Part 1: the school.
    "Aula": ((-18, 18, -30, 0), (0.9, 0.9, 0.88), 12.0, {"N": [(14, 3)], "S": [], "W": [(-12, 3)], "E": []}),
    "Kantine": ((-34, -18, -20, -4), (0.7, 0.6, 0.45), 3.6, {"N": [], "S": [], "W": [], "E": None}),
    "Gang": ((11, 17, -60, -30), (0.85, 0.85, 0.82), 3.6, {"N": None, "S": None, "W": [], "E": []}),
    "Gymzaal": ((-2, 30, -92, -60), (0.5, 0.55, 0.65), 8.0, {"N": [], "S": [(14, 3)], "W": [(-84, 3)], "E": []}),
    "Trappenhuis": ((-14, -2, -86, -82), (0.6, 0.6, 0.6), 3.6, {"N": [], "S": [], "W": None, "E": None}),
    # Checkpoint: the staff room.
    "Docentenkamer": ((-28, -14, -94, -74), (0.62, 0.52, 0.4), 3.6, {"N": [(-21, 3)], "S": [], "W": [], "E": [(-84, 3)]}),
    # Part 2: behind the school.
    "Binnenplein": ((-38, 2, -134, -94), (0.55, 0.32, 0.3), 9.0, {"N": [(-16, 4)], "S": [(-21, 15, 3.6)], "W": [], "E": []}),
    "Fietsenhok": ((-20, -12, -150, -134), (0.4, 0.4, 0.42), 4.0, {"N": None, "S": None, "W": [], "E": []}),
    "Sportveld": ((-29, -3, -176, -150), (0.3, 0.3, 0.38), 8.0, {"N": [], "S": [(-16, 4)], "W": [], "E": []}),
}
# (name, centre x, centre z, size, colour, solid). No prop may stand in a doorway:
# test_world walks the navigation mesh from the entrance to the boss.
PROPS = [
    # The aula: a lounge with green sofas, plants and a screen near the entrance.
    ("SofaWest1", -10, -4, (4.0, 0.8, 1.4), SOFA, True),
    ("SofaWest2", -12.3, -7, (1.4, 0.8, 3.0), SOFA, True),
    ("SofaEast1", 10, -4, (4.0, 0.8, 1.4), SOFA, True),
    ("PlanterWest", -7, -8, (1.6, 1.4, 1.6), GRASS, True),
    ("PlanterEast", 7, -8, (1.6, 1.4, 1.6), GRASS, True),
    ("Screen", -17.6, -20, (0.2, 2.0, 3.4), (0.15, 0.25, 0.6), True),
    # Glass galleries of the upper floors along the side walls, and their pillars.
    ("GalleryWest", -16, -15, (4.0, 0.3, 30), WHITE, False),
    ("GalleryEast", 16, -15, (4.0, 0.3, 30), WHITE, False),
    ("GalleryNorth", 0, -28.5, (28, 0.3, 3.0), WHITE, False),
    ("RailWest", -14.05, -15, (0.1, 1.1, 30), GLASS, False),
    ("RailEast", 14.05, -15, (0.1, 1.1, 30), GLASS, False),
    ("GalleryWestUpper", -16, -15, (4.0, 0.3, 30), WHITE, False),
    ("GalleryEastUpper", 16, -15, (4.0, 0.3, 30), WHITE, False),
    ("RailWestUpper", -14.05, -15, (0.1, 1.1, 30), GLASS, False),
    ("RailEastUpper", 14.05, -15, (0.1, 1.1, 30), GLASS, False),
    # Canteen.
    ("Counter", -26, -19, (12, 1.1, 1.0), STEEL, True),
    ("Table1", -30, -10, (3.0, 0.8, 1.4), WOOD, True),
    ("Table2", -23, -10, (3.0, 0.8, 1.4), WOOD, True),
    # Corridor and gym.
    ("Lockers", 16.4, -45, (0.6, 2.0, 18), RED, True),
    ("GymFloor", 14, -76, (30, 0.02, 30), (0.7, 0.5, 0.3), False),
    ("GymLineMid", 14, -76, (30, 0.03, 0.15), WHITE, False),
    ("GoalNorth", 14, -91, (5, 2.2, 1.0), WHITE, True),
    ("Mats", 27, -64, (2.4, 0.4, 4), NAVY, True),
    ("Bleachers", 29, -80, (1.6, 1.4, 14), NAVY, True),
    # Checkpoint: furniture along the walls, away from both doors.
    ("StaffTable", -21, -84, (5, 0.8, 2.2), WOOD, True),
    ("CoffeeMachine", -27.4, -91, (0.8, 1.6, 0.8), (0.2, 0.2, 0.22), True),
    ("Pigeonholes", -21, -74.8, (6, 2.0, 0.6), WOOD, True),
    # Part 2.
    ("Scooter", -34, -100, (0.6, 1.0, 1.6), RED, True),
    ("Planter1", -26, -112, (3.0, 0.8, 3.0), GRASS, True),
    ("Planter2", -6, -122, (3.0, 0.8, 3.0), GRASS, True),
    ("Planter3", -30, -126, (3.0, 0.8, 3.0), GRASS, True),
    ("ShedRack", -19.4, -142, (0.6, 1.0, 14), STEEL, True),
    ("Pitch", -16, -163, (24, 0.02, 24), GRASS, False),
    ("PitchLine", -16, -163, (24, 0.03, 0.15), WHITE, False),
    ("GoalWest", -28.2, -163, (0.8, 2.2, 6), WHITE, False),
    ("GoalEast", -3.8, -163, (0.8, 2.2, 6), WHITE, False),
]
# The wooden sitting staircase of the aula: eight steps rising to the north wall.
for step in range(8):
    height = 0.5 * (step + 1)
    PROPS.append((f"Tribune{step + 1}", 0, -20.4 - 0.6 - step * 1.2, (14, height, 1.2), OAK, True))
# Gallery pillars, clear of the doors.
for z in (-4, -14, -22):
    PROPS.append((f"PillarWest{z}", -14, z, (0.6, 4.5, 0.6), WHITE, True))
    PROPS.append((f"PillarEast{z}", 14, z, (0.6, 4.5, 0.6), WHITE, True))
# Upper galleries sit higher: fix their y in main().
UPPER = {"GalleryWestUpper", "GalleryEastUpper", "RailWestUpper", "RailEastUpper"}
# (name, x, y, z, yaw, text, colour)
LABELS = [
    ("SignAula", 0, 9.0, -29.45, 0, "OBC ELST", RED),
    ("SignKantine", -26, 2.7, -4.55, 3.14159, "KANTINE", NAVY),
    ("SignGym", 14, 6.0, -91.45, 0, "GYMZAAL", WHITE),
    ("SignStaff", -21, 2.6, -74.55, 3.14159, "DOCENTENKAMER", (0.6, 0.95, 0.6)),
    ("SignPlein", -21, 3.4, -94.55, 3.14159, "BINNENPLEIN", RED),
    ("SignField", -16, 3.8, -133.45, 0, "SPORTVELD", WHITE),
    ("GraffitiPlein", -37.45, 3.0, -114, 1.5708, "KAKKERS ONLY", NAVY),
]
# (name, x, y, z, colour, energy, range)
LIGHTS = [
    ("LightAula1", -6, 9.0, -8, (1.0, 0.98, 0.94), 3.2, 22),
    ("LightAula2", 6, 9.0, -8, (1.0, 0.98, 0.94), 3.2, 22),
    ("LightAula3", -6, 9.0, -22, (1.0, 0.98, 0.94), 3.2, 22),
    ("LightAula4", 6, 9.0, -22, (1.0, 0.98, 0.94), 3.2, 22),
    ("LightKantine", -26, 3.1, -12, (1.0, 0.85, 0.6), 1.6, 12),
    ("LightGang1", 14, 3.1, -38, (0.95, 0.95, 0.9), 1.2, 9),
    ("LightGang2", 14, 3.1, -52, (0.95, 0.95, 0.9), 1.2, 9),
    ("LightGym1", 8, 7.0, -68, (0.9, 0.95, 1.0), 1.8, 16),
    ("LightGym2", 20, 7.0, -84, (0.9, 0.95, 1.0), 1.8, 16),
    ("LightStairs", -8, 3.1, -84, (0.9, 0.9, 0.8), 1.0, 7),
    ("LightStaff", -21, 3.1, -84, (1.0, 0.85, 0.55), 2.0, 13),
    ("LightPlein1", -28, 7.5, -104, (1.0, 0.75, 0.5), 1.8, 18),
    ("LightPlein2", -8, 7.5, -124, (1.0, 0.75, 0.5), 1.8, 18),
    ("LightShed", -16, 3.5, -142, (0.9, 0.9, 1.0), 1.4, 10),
    ("LightField1", -22, 7.0, -156, (1.0, 0.95, 0.85), 2.0, 18),
    ("LightField2", -10, 7.0, -156, (1.0, 0.95, 0.85), 2.0, 18),
    ("LightField3", -22, 7.0, -170, (1.0, 0.95, 0.85), 2.0, 18),
    ("LightField4", -10, 7.0, -170, (1.0, 0.95, 0.85), 2.0, 18),
]
# The ring lamps of the aula: (x, y, z).
RINGS = [(-6, 10.0, -8), (6, 10.0, -8), (-6, 10.0, -22), (6, 10.0, -22)]
# Enemies: (name, scene id, x, z, yaw). 20 of them, two more than Westeraam.
ENEMIES = [
    # Part 1.
    ("Voetballer1", "21_voetballer", -5, -16, 0), ("Voetballer2", "21_voetballer", 6, -15, 0.3),
    ("Fatbiker1", "22_fatbiker", 0, -10, 0),
    ("Voetballer3", "21_voetballer", -30, -6, 1.2), ("Voetballer4", "21_voetballer", -24, -14, 1.0),
    ("Voetballer5", "21_voetballer", 14, -40, 0), ("Voetballer6", "21_voetballer", 13, -54, 0.2),
    ("Voetballer7", "21_voetballer", 6, -82, 0.3), ("Voetballer8", "21_voetballer", 22, -74, -0.4),
    ("Voetballer9", "21_voetballer", 14, -88, 0), ("Fatbiker2", "22_fatbiker", 20, -66, 0.5),
    ("Fatbiker3", "22_fatbiker", 4, -70, -0.5),
    # Part 2.
    ("Fatbiker4", "22_fatbiker", -26, -108, 0), ("Fatbiker5", "22_fatbiker", -10, -112, 0.4),
    ("Fatbiker6", "22_fatbiker", -22, -126, -0.3), ("Voetballer10", "21_voetballer", -4, -104, 1.0),
    ("Voetballer11", "21_voetballer", -34, -118, -1.0), ("Voetballer12", "21_voetballer", -14, -130, 0),
    ("Fatbiker7", "22_fatbiker", -16, -138, 0), ("Fatbiker8", "22_fatbiker", -16, -146, 0.2),
]
# Most of them face the player coming in; the yaws above are replaced.
ENEMIES = aim_enemies(ENEMIES, ROOMS, (0, -4), 0.7, seed=9)
CHESTS = [("ChestKantine", -33, -5, 3.14159), ("ChestPlein", -36.5, -132.5, 0.7854)]
CHECKPOINT = (-21, -84)
BENCH = (-27.15, -80, -1.5708)
BOSS_START = (-16, -169)


def main():
    d = Dungeon()
    props = [(name, x, z, size, colour, solid) for name, x, z, size, colour, solid in PROPS if name not in UPPER]
    d.build_rooms(ROOMS, props)
    # Galleries: the lower ones at 4.5 m, the upper ones at 8 m, with glass rails.
    for name, x, z, size, colour, _ in PROPS:
        if name.startswith(("Gallery", "Rail")):
            base = 8.0 if name in UPPER else 4.5
            y = base + (0.55 if name.startswith("Rail") else 0.0)
            if name in UPPER:
                d.visual("Structure", name, (x, y, z), size, colour)
    for block in d.nodes:
        if block[0].startswith('[node name="Gallery') or block[0].startswith('[node name="Rail'):
            name = block[0].split('"')[1]
            if name not in UPPER:
                x, z = next((p[1], p[2]) for p in PROPS if p[0] == name)
                block[1] = f"position = {vec(x, 4.5 + (0.55 if name.startswith('Rail') else 0.0), z)}"
    d.build_labels_and_lights(LABELS, LIGHTS)
    # Bars that close the sports field during the boss fight: hidden and open until then.
    d.solid(".", "ArenaGate", (BOSS_START[0], 2.0, -150), (4, 4, 0.6), (0.55, 0.55, 0.6))
    d.nodes[-3].append("visible = false")
    d.nodes[-2].append("disabled = true")
    d.nodes[-2][0] = d.nodes[-2][0].replace('parent="./ArenaGate"', 'parent="ArenaGate"')
    d.nodes[-1][0] = d.nodes[-1][0].replace('parent="./ArenaGate"', 'parent="ArenaGate"')
    # Ring lamps hanging in the aula.
    d.subs.append(['[sub_resource type="StandardMaterial3D" id="Mat_ring"]', "albedo_color = Color(1, 1, 1, 1)",
                   "emission_enabled = true", "emission = Color(1, 0.98, 0.92, 1)", "emission_energy_multiplier = 2.0"])
    d.subs.append(['[sub_resource type="TorusMesh" id="Torus_ring"]', 'material = SubResource("Mat_ring")',
                   "inner_radius = 1.5", "outer_radius = 1.7", "rings = 24", "ring_segments = 6"])
    for n, (x, y, z) in enumerate(RINGS, 1):
        d.nodes.append([f'[node name="RingLamp{n}" type="MeshInstance3D" parent="."]', f"position = {vec(x, y, z)}",
                        'mesh = SubResource("Torus_ring")'])
    ext = [("PackedScene", "res://scenes/enemies/Voetballer.tscn", "21_voetballer"),
           ("PackedScene", "res://scenes/enemies/Fatbiker.tscn", "22_fatbiker"),
           ("PackedScene", "res://scenes/world/props/Chest.tscn", "23_chest"),
           ("PackedScene", "res://scenes/bosses/FatbikeKid.tscn", "24_kid"),
           ("PackedScene", "res://scenes/world/props/Checkpoint.tscn", "26_checkpoint"),
           ("PackedScene", "res://scenes/world/props/RestBench.tscn", "27_bench")]
    extra = ['[node name="Checkpoint" parent="." instance=ExtResource("26_checkpoint")]', f"position = {vec(CHECKPOINT[0], 0, CHECKPOINT[1])}", "",
             '[node name="RestBench" parent="." instance=ExtResource("27_bench")]', f"position = {vec(BENCH[0], 0, BENCH[1])}",
             f"rotation = {vec(0, BENCH[2], 0)}", "",
             '[node name="BossArena" type="Node3D" parent="."]', "",
             '[node name="HelperSpawns" type="Node3D" parent="BossArena"]', "",
             '[node name="SpawnWest" type="Marker3D" parent="BossArena/HelperSpawns"]', "position = Vector3(-26, 0, -153)", "",
             '[node name="SpawnEast" type="Marker3D" parent="BossArena/HelperSpawns"]', "position = Vector3(-6, 0, -153)", "",
             '[node name="FatbikeKid" parent="BossArena" instance=ExtResource("24_kid")]', f"position = {vec(BOSS_START[0], 0, BOSS_START[1])}",
             'gate_path = NodePath("../../ArenaGate")', "",
             '[node name="MarkerBoss" type="Marker3D" parent="BossArena"]', f"position = {vec(BOSS_START[0], 1, -163)}", 'script = ExtResource("4_marker")',
             "ids = Array[StringName]([&\"fatbike_kindje\"])", ""]
    for name, x, z, yaw in CHESTS:
        extra += [f'[node name="{name}" parent="." instance=ExtResource("23_chest")]', f"position = {vec(x, 0, z)}",
                  f"rotation = {vec(0, yaw, 0)}", ""]
    extra += ['[node name="Enemies" type="Node3D" parent="."]', ""]
    for name, rid, x, z, yaw in ENEMIES:
        extra += [f'[node name="{name}" parent="Enemies" instance=ExtResource("{rid}")]',
                  f"position = {vec(x, 0, z)}", f"rotation = {vec(0, yaw, 0)}", ""]
    world = {"root": "OBCDungeon", "location_name": "OBC Elst Fort", "location_id": "obc_dungeon",
             "ambient": (0.45, 0.45, 0.48), "nav_id": "NavigationMesh_obc", "nav_aabb": (-40, -2, -188, 72, 14, 190),
             "cleared_flag": "boss_fatbike_kindje", "residents": ([(-8, -10), (8, -14), (14, -76), (-16, -163)], ['Eindelijk weer gewoon les.', 'Geen fatbikes meer in de gang!', 'De aula is weer van ons.']),
             "exit": (-0.75, -2, -4, "OBCExit", NAVY)}
    d.write(OUT, world, ext, extra)
    print("wrote", OUT, "with", len(ENEMIES), "enemies")


if __name__ == "__main__":
    main()
