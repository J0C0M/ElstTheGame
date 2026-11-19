"""Builds scenes/dungeons/BingoCave.tscn: the Bingo Club Boomer Cave of Quest 5.

Run from the project root: python3 tools/dungeons/gen_bingo.py

Two parts with a checkpoint in between, like every faction dungeon:
- part 1, the bingo club: the entrance, the big bingo hall with long tables
  and a stage with the bingo machine, the kitchen and a corridor;
- the checkpoint: the coffee room, quiet, with an autosave and a bench;
- part 2, the Boomer Cave behind it: a big cave with stalagmites, a cave
  passage and the lair of Grumpy Oma.
+x is east, -z is north (deeper in). The hardest faction dungeon: the most
enemies and the strongest boss.
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from dungeon_builder import Dungeon, vec  # noqa: E402

OUT = pathlib.Path("scenes/dungeons/BingoCave.tscn")

PINK = (0.9, 0.72, 0.8)
BLUE = (0.6, 0.72, 0.9)
WOOD = (0.55, 0.4, 0.25)
WHITE = (0.92, 0.92, 0.9)
ROCK = (0.36, 0.33, 0.3)
DARK_ROCK = (0.26, 0.24, 0.23)
PURPLE = (0.55, 0.3, 0.6)

# name: ((x0, x1, z0, z1), wall colour, height, doors per side). None: the neighbour builds that wall.
ROOMS = {
    # Part 1: the bingo club.
    "Entree": ((-8, 8, -16, 0), PINK, 4.5, {"N": [(0, 4)], "S": [], "W": [], "E": []}),
    "Bingozaal": ((-20, 20, -50, -16), BLUE, 7.0, {"N": [(12, 3)], "S": [(0, 17, 4.5)], "W": [(-40, 3)], "E": []}),
    "Keuken": ((-34, -20, -46, -30), (0.85, 0.85, 0.8), 3.6, {"N": [], "S": [], "W": [], "E": None}),
    "Gang": ((9, 15, -80, -50), (0.7, 0.75, 0.9), 3.6, {"N": None, "S": None, "W": [], "E": []}),
    # Checkpoint: the coffee room.
    "Koffiekamer": ((2, 22, -96, -80), (0.8, 0.7, 0.55), 3.6, {"N": [(12, 3)], "S": [(12, 3)], "W": [], "E": []}),
    # Part 2: the Boomer Cave.
    "Grot": ((-10, 34, -136, -96), ROCK, 8.0, {"N": [(12, 4)], "S": [(12, 21, 3.6)], "W": [], "E": []}),
    "Grotgang": ((9, 15, -156, -136), DARK_ROCK, 4.0, {"N": None, "S": None, "W": [], "E": []}),
    "Hol": ((-3, 27, -186, -156), (0.3, 0.28, 0.32), 9.0, {"N": [], "S": [(12, 4)], "W": [], "E": []}),
}
# (name, centre x, centre z, size, colour, solid). Nothing in a doorway: test_world walks the route.
PROPS = [
    ("CoatRack", -7.4, -8, (0.6, 1.8, 5), WOOD, True),
    ("Kassa", 6.5, -6, (2.0, 1.1, 3.0), PINK, True),
    ("Stage", -10, -47, (14, 0.6, 5), (0.5, 0.35, 0.55), True),
    ("BingoMachine", -10, -47.5, (1.8, 2.6, 1.8), (0.95, 0.85, 0.3), True),
    ("Fridge", -33.4, -32, (0.8, 2.0, 1.2), WHITE, True),
    ("KitchenCounter", -27, -45.4, (10, 1.0, 0.8), WHITE, True),
    ("CoffeeTable", 12, -88, (4, 0.8, 2), WOOD, True),
    ("CoffeeMachine", 2.6, -94, (0.8, 1.6, 0.8), (0.2, 0.2, 0.22), True),
    ("CookieTin", 12, -88, (0.5, 0.95, 0.5), (0.3, 0.45, 0.8), False),
    ("ArmChair", 12, -184, (3.0, 2.2, 2.0), PURPLE, True),
    ("HandbagPile", -1, -183, (2.4, 1.2, 2.4), PURPLE, True),
]
# Long bingo tables in the hall, with a path along the east side to the corridor.
for row, z in enumerate((-24, -31, -38)):
    PROPS.append((f"TableWest{row}", -11, z, (10, 0.8, 1.4), WHITE, True))
    PROPS.append((f"TableEast{row}", 4, z, (10, 0.8, 1.4), WHITE, True))
# Stalagmites in the cave and the lair, away from the route through the middle.
for n, (x, z, w, h) in enumerate([(-5, -104, 1.6, 4), (29, -104, 1.4, 5), (0, -125, 2.0, 3), (27, -128, 1.6, 6),
                                  (4, -112, 1.2, 2.5), (22, -114, 1.4, 3.5), (-7, -132, 1.8, 5), (31, -133, 1.6, 4)]):
    PROPS.append((f"Stalagmite{n + 1}", x, z, (w, h, w), ROCK, True))
for n, (x, z) in enumerate([(-1, -159), (25, -159), (24, -183), (0, -170)]):
    PROPS.append((f"LairRock{n + 1}", x, z, (1.8, 4.0, 1.8), DARK_ROCK, True))
# (name, x, y, z, yaw, text, colour)
LABELS = [
    ("SignEntree", 0, 3.9, -15.45, 0, "BINGO CLUB", (0.4, 0.55, 0.95)),
    ("SignBingo", -10, 5.2, -49.45, 0, "BINGO!", (0.95, 0.85, 0.3)),
    ("SignKeuken", -27, 2.7, -30.55, 3.14159, "KEUKEN", (0.3, 0.3, 0.35)),
    ("SignKoffie", 2.55, 2.6, -88, 1.5708, "KOFFIEKAMER", (0.6, 0.95, 0.6)),
    ("SignCave", 12, 5.0, -135.45, 0, "BOOMER CAVE", (0.8, 0.7, 0.95)),
    ("SignLair", 12, 6.0, -185.45, 0, "HOL VAN GRUMPY OMA", (0.95, 0.4, 0.4)),
]
# (name, x, y, z, colour, energy, range)
LIGHTS = [
    ("LightEntree", 0, 4.0, -8, (1.0, 0.9, 0.95), 1.6, 12),
    ("LightZaal1", -10, 6.2, -26, (1.0, 0.95, 0.85), 2.0, 16),
    ("LightZaal2", 8, 6.2, -26, (1.0, 0.95, 0.85), 2.0, 16),
    ("LightZaal3", -10, 6.2, -42, (1.0, 0.95, 0.85), 2.0, 16),
    ("LightZaal4", 8, 6.2, -42, (1.0, 0.95, 0.85), 2.0, 16),
    ("LightKeuken", -27, 3.1, -38, (1.0, 1.0, 0.95), 1.6, 12),
    ("LightGang1", 12, 3.1, -58, (0.9, 0.9, 1.0), 1.2, 9),
    ("LightGang2", 12, 3.1, -72, (0.9, 0.9, 1.0), 1.2, 9),
    ("LightKoffie", 12, 3.1, -88, (1.0, 0.85, 0.55), 2.0, 13),
    ("LightGrot1", 2, 7.0, -106, (0.7, 0.75, 1.0), 1.8, 18),
    ("LightGrot2", 22, 7.0, -106, (0.7, 0.75, 1.0), 1.8, 18),
    ("LightGrot3", 2, 7.0, -126, (0.7, 0.75, 1.0), 1.8, 18),
    ("LightGrot4", 22, 7.0, -126, (0.7, 0.75, 1.0), 1.8, 18),
    ("LightGrotgang", 12, 3.5, -146, (0.8, 0.6, 1.0), 1.4, 10),
    ("LightHol1", 4, 8.0, -164, (1.0, 0.6, 0.6), 2.2, 18),
    ("LightHol2", 20, 8.0, -164, (1.0, 0.6, 0.6), 2.2, 18),
    ("LightHol3", 4, 8.0, -178, (1.0, 0.6, 0.6), 2.2, 18),
    ("LightHol4", 20, 8.0, -178, (1.0, 0.6, 0.6), 2.2, 18),
]
# Enemies: (name, scene id, x, z, yaw). 25 of them, the most of any dungeon:
# bingo-opa's with walking sticks, leaping boze oma's and wheelchair oma's
# that fire bingo cards from a distance.
ENEMIES = [
    # Part 1: the entrance, the bingo hall, the kitchen and the corridor.
    ("Opa1", "22_opa", -4, -10, 0), ("Opa2", "22_opa", 4, -11, 0.2),
    ("Oma1", "21_oma", -14, -27.5, 0), ("Oma2", "21_oma", 14, -26, -0.3), ("Opa3", "22_opa", 0, -34.5, 0.3),
    ("Opa4", "22_opa", 6, -27.5, -0.2), ("Opa5", "22_opa", -12, -34.5, 0.4),
    ("Rolstoel1", "25_rolstoel", -2, -46, 0), ("Rolstoel2", "25_rolstoel", 16, -46, -0.3),
    ("Oma3", "21_oma", -30, -35, 1.2), ("Opa6", "22_opa", -28, -40, 1.4), ("Rolstoel3", "25_rolstoel", -23, -36, 1.0),
    ("Opa7", "22_opa", 12, -58, 0), ("Oma4", "21_oma", 12, -72, 0.2),
    # Part 2: the cave and the cave passage.
    ("Oma5", "21_oma", 0, -110, 0), ("Oma6", "21_oma", 20, -103, 0.4), ("Oma7", "21_oma", 24, -122, -0.3),
    ("Oma8", "21_oma", 6, -130, 0), ("Opa8", "22_opa", 14, -118, 0.2), ("Opa9", "22_opa", -4, -110, 1.0),
    ("Rolstoel4", "25_rolstoel", -4, -122, 1.0), ("Rolstoel5", "25_rolstoel", 30, -116, -1.0), ("Rolstoel6", "25_rolstoel", 12, -131, 0),
    ("Opa10", "22_opa", 12, -142, 0), ("Oma9", "21_oma", 12, -150, 0.2),
]
CHESTS = [("ChestKeuken", -32.5, -44.5, 0.7854), ("ChestGrot", -8, -98, 3.14159)]
CHECKPOINT = (12, -88)
BENCH = (21.15, -84, 1.5708)
BOSS_START = (12, -176)


def main():
    d = Dungeon()
    d.build_rooms(ROOMS, PROPS)
    d.build_labels_and_lights(LABELS, LIGHTS)
    # Bars that close the lair during the boss fight: hidden and open until then.
    d.solid(".", "ArenaGate", (BOSS_START[0], 2.0, -156), (4, 4, 0.6), (0.55, 0.55, 0.6))
    d.nodes[-3].append("visible = false")
    d.nodes[-2].append("disabled = true")
    d.nodes[-2][0] = d.nodes[-2][0].replace('parent="./ArenaGate"', 'parent="ArenaGate"')
    d.nodes[-1][0] = d.nodes[-1][0].replace('parent="./ArenaGate"', 'parent="ArenaGate"')
    ext = [("PackedScene", "res://scenes/enemies/BozeOma.tscn", "21_oma"),
           ("PackedScene", "res://scenes/enemies/BingoOpa.tscn", "22_opa"),
           ("PackedScene", "res://scenes/world/props/Chest.tscn", "23_chest"),
           ("PackedScene", "res://scenes/bosses/GrumpyOma.tscn", "24_boss"),
           ("PackedScene", "res://scenes/enemies/RolstoelOma.tscn", "25_rolstoel"),
           ("PackedScene", "res://scenes/world/props/Checkpoint.tscn", "26_checkpoint"),
           ("PackedScene", "res://scenes/world/props/RestBench.tscn", "27_bench")]
    extra = ['[node name="Checkpoint" parent="." instance=ExtResource("26_checkpoint")]', f"position = {vec(CHECKPOINT[0], 0, CHECKPOINT[1])}", "",
             '[node name="RestBench" parent="." instance=ExtResource("27_bench")]', f"position = {vec(BENCH[0], 0, BENCH[1])}",
             f"rotation = {vec(0, BENCH[2], 0)}", "",
             '[node name="BossArena" type="Node3D" parent="."]', "",
             '[node name="GrumpyOma" parent="BossArena" instance=ExtResource("24_boss")]', f"position = {vec(BOSS_START[0], 0, BOSS_START[1])}",
             "rotation = Vector3(0, 3.14159, 0)", 'gate_path = NodePath("../../ArenaGate")', "",
             '[node name="MarkerBoss" type="Marker3D" parent="BossArena"]', f"position = {vec(BOSS_START[0], 1, -171)}", 'script = ExtResource("4_marker")',
             "ids = Array[StringName]([&\"grumpy_oma\"])", ""]
    for name, x, z, yaw in CHESTS:
        extra += [f'[node name="{name}" parent="." instance=ExtResource("23_chest")]', f"position = {vec(x, 0, z)}",
                  f"rotation = {vec(0, yaw, 0)}", ""]
    extra += ['[node name="Enemies" type="Node3D" parent="."]', ""]
    for name, rid, x, z, yaw in ENEMIES:
        extra += [f'[node name="{name}" parent="Enemies" instance=ExtResource("{rid}")]',
                  f"position = {vec(x, 0, z)}", f"rotation = {vec(0, yaw, 0)}", ""]
    world = {"root": "BingoCaveDungeon", "location_name": "Bingo Club Boomer Cave", "location_id": "bingo_dungeon",
             "ambient": (0.42, 0.42, 0.5), "nav_id": "NavigationMesh_bingo", "nav_aabb": (-36, -2, -188, 72, 12, 190),
             "exit": (-0.75, -2, -4, "BingoExit", (0.4, 0.55, 0.95))}
    d.write(OUT, world, ext, extra)
    print("wrote", OUT, "with", len(ENEMIES), "enemies")


if __name__ == "__main__":
    main()
