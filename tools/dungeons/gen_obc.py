"""Builds scenes/dungeons/OBC.tscn: the OBC Elst Fort dungeon of Quest 4.

Run from the project root: python3 tools/dungeons/gen_obc.py

Two parts with a checkpoint in between, like every faction dungeon:
- part 1, the school: the hall, a corridor with lockers, the canteen and the
  gym, then the stairwell;
- the checkpoint: the staff room, quiet, with an autosave and a bench;
- part 2, behind the school: the inner square where fatbikers circle, the
  bike shed and the sports field, where the fatbike-kindje charges.
+x is east, -z is north (deeper in).
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from dungeon_builder import Dungeon, vec  # noqa: E402

OUT = pathlib.Path("scenes/dungeons/OBC.tscn")

RED = (0.8, 0.14, 0.14)
NAVY = (0.12, 0.16, 0.36)
WHITE = (0.92, 0.92, 0.9)
WOOD = (0.55, 0.4, 0.25)
STEEL = (0.45, 0.45, 0.48)
GRASS = (0.3, 0.55, 0.28)

# name: ((x0, x1, z0, z1), wall colour, height, doors per side). None: the neighbour builds that wall.
ROOMS = {
    # Part 1: the school.
    "Aula": ((-8, 8, 0, 14), (0.6, 0.55, 0.5), 5.0, {"N": [(0, 3)], "S": [], "W": [], "E": []}),
    "Gang": ((-3, 3, -36, 0), (0.75, 0.72, 0.65), 3.6, {"N": None, "S": None, "W": [(-12, 3)], "E": []}),
    "Kantine": ((-21, -3, -20, -4), (0.7, 0.6, 0.45), 3.6, {"N": [], "S": [], "W": [], "E": None}),
    "Gymzaal": ((-16, 16, -68, -36), (0.5, 0.55, 0.65), 8.0, {"N": [], "S": [(0, 3)], "W": [(-60, 3)], "E": []}),
    "Trappenhuis": ((-28, -16, -62, -58), (0.6, 0.6, 0.6), 3.6, {"N": [], "S": [], "W": None, "E": None}),
    # Checkpoint: the staff room.
    "Docentenkamer": ((-42, -28, -70, -50), (0.62, 0.52, 0.4), 3.6, {"N": [(-35, 3)], "S": [], "W": [], "E": [(-60, 3)]}),
    # Part 2: behind the school.
    "Binnenplein": ((-52, -12, -110, -70), (0.55, 0.32, 0.3), 9.0, {"N": [(-30, 4)], "S": [(-35, 15)], "W": [], "E": []}),
    "Fietsenhok": ((-34, -26, -126, -110), (0.4, 0.4, 0.42), 4.0, {"N": None, "S": None, "W": [], "E": []}),
    "Sportveld": ((-48, -12, -162, -126), (0.3, 0.3, 0.38), 8.0, {"N": [], "S": [(-30, 4)], "W": [], "E": []}),
}
# (name, centre x, centre z, size, colour, solid)
PROPS = [
    # Part 1.
    ("Trophies", 0, 13.2, (6, 2.0, 0.8), (0.85, 0.7, 0.2), True),
    ("BenchAula1", -6.5, 6, (0.6, 0.5, 3.0), WOOD, True),
    ("BenchAula2", 6.5, 6, (0.6, 0.5, 3.0), WOOD, True),
    ("LockersWest", -2.4, -24, (0.6, 2.0, 18), RED, True),
    ("Counter", -12, -19, (12, 1.1, 1.0), STEEL, True),
    ("Table1", -16, -10, (3.0, 0.8, 1.4), WOOD, True),
    ("Table2", -9, -10, (3.0, 0.8, 1.4), WOOD, True),
    ("Table3", -12.5, -14, (3.0, 0.8, 1.4), WOOD, True),
    ("GymFloor", 0, -52, (28, 0.02, 28), (0.7, 0.5, 0.3), False),
    ("GymLineMid", 0, -52, (28, 0.03, 0.15), WHITE, False),
    ("GoalNorth", 0, -67, (5, 2.2, 1.0), WHITE, True),
    ("Mats", 13, -40, (2.4, 0.4, 4), NAVY, True),
    ("Bleachers", 15, -56, (1.6, 1.4, 14), NAVY, True),
    # Checkpoint.
    ("StaffTable", -35, -60, (5, 0.8, 2.2), WOOD, True),
    ("CoffeeMachine", -41.4, -53, (0.8, 1.6, 0.8), (0.2, 0.2, 0.22), True),
    ("Pigeonholes", -35, -69.4, (6, 2.0, 0.6), WOOD, True),
    # Part 2.
    ("Scooter", -48, -76, (0.6, 1.0, 1.6), RED, True),
    ("Planter1", -32, -90, (3.0, 0.8, 3.0), GRASS, True),
    ("Planter2", -20, -100, (3.0, 0.8, 3.0), GRASS, True),
    ("Planter3", -44, -102, (3.0, 0.8, 3.0), GRASS, True),
    ("ShedRack", -33.4, -118, (0.6, 1.0, 14), STEEL, True),
    ("Pitch", -30, -144, (34, 0.02, 34), GRASS, False),
    ("PitchLine", -30, -144, (34, 0.03, 0.15), WHITE, False),
    ("GoalWest", -47.2, -144, (0.8, 2.2, 6), WHITE, False),
    ("GoalEast", -12.8, -144, (0.8, 2.2, 6), WHITE, False),
]
# (name, x, y, z, yaw, text, colour)
LABELS = [
    ("SignAula", 0, 4.0, 0.55, 0, "OBC ELST", RED),
    ("SignKantine", -12, 2.7, -4.55, 3.14159, "KANTINE", NAVY),
    ("SignGym", 0, 6.0, -67.45, 0, "GYMZAAL", WHITE),
    ("SignStaff", -41.45, 2.6, -60, 1.5708, "DOCENTENKAMER", (0.6, 0.95, 0.6)),
    ("SignPlein", -35, 3.4, -70.55, 3.14159, "BINNENPLEIN", RED),
    ("SignField", -30, 3.8, -109.45, 0, "SPORTVELD", WHITE),
    ("GraffitiPlein", -51.45, 3.0, -90, 1.5708, "KAKKERS ONLY", NAVY),
]
# (name, x, y, z, colour, energy, range)
LIGHTS = [
    ("LightAula", 0, 4.4, 7, (1.0, 0.92, 0.8), 1.6, 12),
    ("LightGang1", 0, 3.1, -8, (0.95, 0.95, 0.9), 1.2, 9),
    ("LightGang2", 0, 3.1, -20, (0.95, 0.95, 0.9), 1.2, 9),
    ("LightGang3", 0, 3.1, -31, (0.95, 0.95, 0.9), 1.2, 9),
    ("LightKantine", -12, 3.1, -12, (1.0, 0.85, 0.6), 1.6, 12),
    ("LightGym1", -6, 7.0, -44, (0.9, 0.95, 1.0), 1.8, 16),
    ("LightGym2", 6, 7.0, -60, (0.9, 0.95, 1.0), 1.8, 16),
    ("LightStairs", -22, 3.1, -60, (0.9, 0.9, 0.8), 1.0, 7),
    ("LightStaff", -35, 3.1, -60, (1.0, 0.85, 0.55), 2.0, 13),
    ("LightPlein1", -42, 7.5, -80, (1.0, 0.75, 0.5), 1.8, 18),
    ("LightPlein2", -22, 7.5, -100, (1.0, 0.75, 0.5), 1.8, 18),
    ("LightShed", -30, 3.5, -118, (0.9, 0.9, 1.0), 1.4, 10),
    ("LightField1", -40, 7.0, -134, (1.0, 0.95, 0.85), 2.0, 18),
    ("LightField2", -20, 7.0, -134, (1.0, 0.95, 0.85), 2.0, 18),
    ("LightField3", -40, 7.0, -154, (1.0, 0.95, 0.85), 2.0, 18),
    ("LightField4", -20, 7.0, -154, (1.0, 0.95, 0.85), 2.0, 18),
]
# Enemies: (name, scene id, x, z, yaw). Voetballers shoot from a distance, fatbikers circle and charge.
ENEMIES = [
    # Part 1.
    ("Voetballer1", "21_voetballer", 0, -14, 0), ("Voetballer2", "21_voetballer", 1, -28, 0.2),
    ("Voetballer3", "21_voetballer", -15, -8, 1.2), ("Voetballer4", "21_voetballer", -8, -15, 1.0),
    ("Voetballer5", "21_voetballer", -8, -58, 0.3), ("Voetballer6", "21_voetballer", 8, -50, -0.4),
    ("Voetballer7", "21_voetballer", 0, -64, 0), ("Fatbiker1", "22_fatbiker", 6, -42, 0.5),
    # Part 2.
    ("Fatbiker2", "22_fatbiker", -40, -84, 0), ("Fatbiker3", "22_fatbiker", -24, -88, 0.4),
    ("Fatbiker4", "22_fatbiker", -36, -102, -0.3), ("Voetballer8", "21_voetballer", -18, -80, 1.0),
    ("Voetballer9", "21_voetballer", -46, -94, -1.0), ("Voetballer10", "21_voetballer", -28, -106, 0),
    ("Fatbiker5", "22_fatbiker", -30, -114, 0), ("Fatbiker6", "22_fatbiker", -30, -122, 0.2),
]
CHESTS = [("ChestKantine", -20, -5, 3.14159), ("ChestPlein", -50.5, -108.5, 0.7854)]
CHECKPOINT = (-35, -60)
BENCH = (-28.85, -54, 1.5708)
BOSS_START = (-30, -150)


def main():
    d = Dungeon()
    d.build_rooms(ROOMS, PROPS)
    d.build_labels_and_lights(LABELS, LIGHTS)
    # Bars that close the sports field during the boss fight: hidden and open until then.
    d.solid(".", "ArenaGate", (-30, 2.0, -126), (4, 4, 0.6), (0.55, 0.55, 0.6))
    d.nodes[-3].append("visible = false")
    d.nodes[-2].append("disabled = true")
    d.nodes[-2][0] = d.nodes[-2][0].replace('parent="./ArenaGate"', 'parent="ArenaGate"')
    d.nodes[-1][0] = d.nodes[-1][0].replace('parent="./ArenaGate"', 'parent="ArenaGate"')
    ext = [("PackedScene", "res://scenes/enemies/Voetballer.tscn", "21_voetballer"),
           ("PackedScene", "res://scenes/enemies/Fatbiker.tscn", "22_fatbiker"),
           ("PackedScene", "res://scenes/world/props/Chest.tscn", "23_chest"),
           ("PackedScene", "res://scenes/bosses/FatbikeKid.tscn", "24_kid"),
           ("PackedScene", "res://scenes/world/props/Checkpoint.tscn", "26_checkpoint"),
           ("PackedScene", "res://scenes/world/props/RestBench.tscn", "27_bench")]
    extra = ['[node name="Checkpoint" parent="." instance=ExtResource("26_checkpoint")]', f"position = {vec(CHECKPOINT[0], 0, CHECKPOINT[1])}", "",
             '[node name="RestBench" parent="." instance=ExtResource("27_bench")]', f"position = {vec(BENCH[0], 0, BENCH[1])}",
             f"rotation = {vec(0, BENCH[2], 0)}", "",
             '[node name="BossArena" type="Node3D" parent="."]', ""]
    extra += ['[node name="FatbikeKid" parent="BossArena" instance=ExtResource("24_kid")]', f"position = {vec(BOSS_START[0], 0, BOSS_START[1])}",
              'gate_path = NodePath("../../ArenaGate")', "",
              '[node name="MarkerBoss" type="Marker3D" parent="BossArena"]', f"position = {vec(BOSS_START[0], 1, -144)}", 'script = ExtResource("4_marker")',
              "ids = Array[StringName]([&\"fatbike_kindje\"])", ""]
    for name, x, z, yaw in CHESTS:
        extra += [f'[node name="{name}" parent="." instance=ExtResource("23_chest")]', f"position = {vec(x, 0, z)}",
                  f"rotation = {vec(0, yaw, 0)}", ""]
    extra += ['[node name="Enemies" type="Node3D" parent="."]', ""]
    for name, rid, x, z, yaw in ENEMIES:
        extra += [f'[node name="{name}" parent="Enemies" instance=ExtResource("{rid}")]',
                  f"position = {vec(x, 0, z)}", f"rotation = {vec(0, yaw, 0)}", ""]
    world = {"root": "OBCDungeon", "location_name": "OBC Elst Fort", "location_id": "obc_dungeon",
             "ambient": (0.4, 0.38, 0.42), "nav_id": "NavigationMesh_obc", "nav_aabb": (-54, -2, -164, 72, 12, 180),
             "exit": (13.25, 12, 10, "OBCExit", NAVY)}
    d.write(OUT, world, ext, extra)
    print("wrote", OUT, "with", len(ENEMIES), "enemies")


if __name__ == "__main__":
    main()
