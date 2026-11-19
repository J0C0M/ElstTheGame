"""Builds scenes/dungeons/Westeraam.tscn: the Westeraam dungeon of Quest 3.

Run from the project root: python3 tools/dungeons/gen_westeraam.py

Two parts with a checkpoint in between, like every faction dungeon:
- part 1, the flats: the entrance hall, a long gallery, a vape shop and the
  courtyard, then down the cellar stairs;
- the checkpoint: the bike cellar, quiet, with an autosave and a bench;
- part 2, under the flats: the car park, a vape lab, a golden corridor and
  the Vape-paleis, where the Vape-koning hides in four vape clouds.
+x is east, -z is north (deeper in).
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from dungeon_builder import Dungeon, aim_enemies, vec  # noqa: E402

OUT = pathlib.Path("scenes/dungeons/Westeraam.tscn")

YELLOW = (0.92, 0.75, 0.2)
BLACK = (0.12, 0.12, 0.13)
CONCRETE = (0.48, 0.47, 0.44)
WOOD = (0.5, 0.36, 0.22)
STEEL = (0.45, 0.45, 0.48)
PURPLE = (0.45, 0.25, 0.6)
GOLD = (1.0, 0.78, 0.2)
CAR_COLOURS = [(0.55, 0.15, 0.12), (0.2, 0.3, 0.5), (0.7, 0.7, 0.72), (0.15, 0.15, 0.16), (0.3, 0.45, 0.3)]

# name: ((x0, x1, z0, z1), wall colour, height, doors per side). None: the neighbour builds that wall.
ROOMS = {
    # Part 1: the flats.
    "Portiek": ((-6, 6, 0, 12), (0.55, 0.5, 0.3), 4.0, {"N": [(0, 3)], "S": [], "W": [], "E": []}),
    "Galerij": ((-3, 3, -34, 0), CONCRETE, 3.6, {"N": None, "S": None, "W": [], "E": [(-13, 3)]}),
    "Vapeshop": ((3, 19, -20, -6), (0.3, 0.22, 0.35), 3.6, {"N": [], "S": [], "W": None, "E": []}),
    "Binnenplaats": ((-14, 14, -62, -34), (0.4, 0.38, 0.3), 9.0, {"N": [], "S": [(0, 3)], "W": [(-48, 3)], "E": []}),
    "Kelderstrap": ((-26, -14, -50, -46), (0.35, 0.33, 0.3), 3.6, {"N": [], "S": [], "W": None, "E": None}),
    # Checkpoint: the bike cellar.
    "Fietsenkelder": ((-40, -26, -58, -38), (0.5, 0.42, 0.3), 3.6, {"N": [(-33, 3)], "S": [], "W": [], "E": [(-48, 3)]}),
    # Part 2: under the flats.
    "Parkeergarage": ((-46, -10, -100, -58), (0.36, 0.36, 0.38), 4.5, {"N": [(-27, 3)], "S": [(-33, 15, 3.6)], "W": [], "E": [(-84, 3)]}),
    "Vapelab": ((-10, 6, -92, -76), (0.28, 0.22, 0.34), 4.0, {"N": [], "S": [], "W": None, "E": []}),
    "Gouden gang": ((-30, -24, -112, -100), (0.45, 0.36, 0.15), 4.0, {"N": None, "S": None, "W": [], "E": []}),
    "Paleis": ((-44, -10, -146, -112), (0.2, 0.14, 0.24), 7.0, {"N": [], "S": [(-27, 3)], "W": [], "E": []}),
}
# (name, centre x, centre z, size, colour, solid)
PROPS = [
    # Part 1.
    ("Mailboxes", 5.4, 6, (0.6, 1.6, 4.0), STEEL, True),
    ("Doormat", 0, 10, (2.0, 0.02, 1.2), BLACK, False),
    ("Counter", 10, -8.5, (6, 1.1, 1.0), (0.25, 0.2, 0.28), True),
    ("ShelfShop1", 18.4, -13, (0.8, 2.2, 6), (0.35, 0.3, 0.4), True),
    ("ShelfShop2", 12, -19.4, (6, 2.2, 0.8), (0.35, 0.3, 0.4), True),
    ("Scooter1", -11, -38, (0.6, 1.0, 1.6), YELLOW, True),
    ("Scooter2", -11, -41, (0.6, 1.0, 1.6), BLACK, True),
    ("Scooter3", 11.5, -58, (0.6, 1.0, 1.6), YELLOW, True),
    ("BurntCar", 6, -44, (2.0, 1.4, 4.2), (0.18, 0.16, 0.15), True),
    ("BenchYard", 12.6, -50, (0.6, 0.5, 2.4), WOOD, True),
    ("Bins", 0, -60.8, (3.0, 1.3, 1.0), (0.2, 0.3, 0.2), True),
    ("Playground", -6, -56, (3.0, 2.2, 3.0), (0.8, 0.3, 0.2), True),
    # Checkpoint.
    ("BikeRack", -39.4, -48, (0.6, 1.0, 12), STEEL, True),
    ("Bike1", -38.4, -52, (0.5, 1.0, 1.7), (0.2, 0.4, 0.7), True),
    ("Bike2", -38.4, -46, (0.5, 1.0, 1.7), (0.7, 0.2, 0.2), True),
    ("Bike3", -38.4, -43, (0.5, 1.0, 1.7), (0.9, 0.9, 0.85), True),
    ("SnackMachine", -27, -55.5, (1.2, 2.0, 1.0), (0.85, 0.2, 0.15), True),
    # Part 2.
    ("Barrier", -33, -62, (6, 1.0, 0.3), YELLOW, True),
    ("Crate1", -2, -78, (1.6, 1.6, 1.6), WOOD, True),
    ("Crate2", 4.4, -86, (1.4, 2.4, 1.4), WOOD, True),
    ("LabTable", -2, -86, (4, 1.0, 1.6), STEEL, True),
    ("Throne", -27, -144, (2.4, 2.2, 1.6), GOLD, True),
    ("Carpet", -27, -122, (4, 0.02, 20), (0.6, 0.12, 0.2), False),
    ("SofaLeft", -41.5, -129, (1.2, 0.9, 4.0), PURPLE, True),
    ("SofaRight", -12.5, -129, (1.2, 0.9, 4.0), PURPLE, True),
    ("CrateCash", -41, -143, (1.6, 1.2, 1.6), WOOD, True),
]
# The car park: pillars on a grid and parked cars in between.
for row, z in enumerate((-68, -80, -92)):
    for column, x in enumerate((-38, -28, -18)):
        PROPS.append((f"Pillar{row}{column}", x, z, (0.8, 4.5, 0.8), CONCRETE, True))
for n, (x, z) in enumerate([(-42, -70), (-42, -86), (-33, -74), (-23, -88), (-14, -72), (-14, -96)]):
    PROPS.append((f"Car{n + 1}", x, z, (2.0, 1.4, 4.2), CAR_COLOURS[n % len(CAR_COLOURS)], True))
# (name, x, y, z, yaw, text, colour)
LABELS = [
    ("SignPortiek", 0, 3.0, 0.55, 0, "WESTERAAM", YELLOW),
    ("SignShop", 10, 2.6, -6.55, 3.14159, "VAPE SHOP", (0.75, 0.45, 1.0)),
    ("GraffitiYard", -13.45, 3.0, -40, 1.5708, "AMBER WAS HERE", (0.95, 0.5, 0.15)),
    ("SignCellar", -13.45, 3.8, -48, 1.5708, "KELDER", (0.9, 0.9, 0.85)),
    ("SignCheckpoint", -39.45, 2.6, -48, 1.5708, "FIETSENKELDER", (0.6, 0.95, 0.6)),
    ("SignGarage", -33, 3.4, -58.55, 3.14159, "PARKEERGARAGE", YELLOW),
    ("SignLab", -2, 3.0, -91.45, 0, "VAPE-LAB", (0.75, 0.45, 1.0)),
    ("SignPaleis", -27, 3.8, -99.45, 0, "VAPE-PALEIS", GOLD),
    ("LabelCash", -41, 1.4, -142.15, 0, "CASH", (0.1, 0.1, 0.1)),
]
# (name, x, y, z, colour, energy, range)
LIGHTS = [
    ("LightPortiek", 0, 3.4, 6, (1.0, 0.9, 0.6), 1.5, 11),
    ("LightGalerij1", 0, 3.1, -8, (0.9, 0.9, 0.75), 1.2, 9),
    ("LightGalerij2", 0, 3.1, -18, (0.9, 0.9, 0.75), 1.2, 9),
    ("LightGalerij3", 0, 3.1, -29, (0.9, 0.9, 0.75), 1.2, 9),
    ("LightShop", 11, 3.1, -13, (0.75, 0.45, 1.0), 1.8, 11),
    ("LightYard1", -6, 6.5, -40, (1.0, 0.8, 0.45), 1.8, 16),
    ("LightYard2", 6, 6.5, -54, (1.0, 0.8, 0.45), 1.8, 16),
    ("LightStairs", -20, 3.1, -48, (0.9, 0.9, 0.8), 1.0, 7),
    ("LightCheckpoint", -33, 3.1, -48, (1.0, 0.85, 0.55), 2.0, 13),
    ("LightGarage1", -38, 4.0, -74, (0.85, 0.9, 1.0), 1.4, 14),
    ("LightGarage2", -18, 4.0, -74, (0.85, 0.9, 1.0), 1.4, 14),
    ("LightGarage3", -28, 4.0, -94, (0.85, 0.9, 1.0), 1.4, 14),
    ("LightLab", -2, 3.5, -84, (0.75, 0.45, 1.0), 1.8, 12),
    ("LightGang", -27, 3.5, -106, (1.0, 0.75, 0.3), 1.6, 9),
    ("LightPaleis1", -35, 6.0, -120, (0.7, 0.35, 1.0), 2.0, 16),
    ("LightPaleis2", -19, 6.0, -120, (0.7, 0.35, 1.0), 2.0, 16),
    ("LightPaleis3", -35, 6.0, -138, (1.0, 0.7, 0.3), 2.0, 16),
    ("LightPaleis4", -19, 6.0, -138, (1.0, 0.7, 0.3), 2.0, 16),
]
# Enemies: (name, scene id, x, z, yaw). Drillers flank, vape-drillers keep their distance.
ENEMIES = [
    # Part 1.
    ("Driller1", "21_driller", 0, -12, 0), ("Driller2", "21_driller", -1, -24, 0.3),
    ("VapeDriller1", "22_vape", 12, -16, 1.2), ("VapeDriller2", "22_vape", 15, -10, 1.6),
    ("Driller3", "21_driller", -6, -42, 0.3), ("Driller4", "21_driller", 5, -50, -0.4),
    ("VapeDriller3", "22_vape", -9, -58, 0.6), ("VapeDriller4", "22_vape", 9, -38, -0.8),
    # Part 2.
    ("Driller5", "21_driller", -33, -70, 0), ("Driller6", "21_driller", -24, -78, 0.4),
    ("Driller7", "21_driller", -40, -92, -0.3), ("VapeDriller5", "22_vape", -18, -84, 1.0),
    ("VapeDriller6", "22_vape", -30, -96, 0), ("VapeDriller7", "22_vape", -44, -78, -1.0),
    ("VapeDriller8", "22_vape", 2, -80, 1.6), ("VapeDriller9", "22_vape", -5, -90, 1.2),
    ("Driller8", "21_driller", -27, -104, 0), ("Driller9", "21_driller", -26, -109, 0.2),
]
# Half of them face the player coming in; the yaws above are replaced.
ENEMIES = aim_enemies(ENEMIES, ROOMS, (0, 8), 0.5, seed=1)
CHESTS = [("ChestShop", 17.5, -7.5, -1.5708), ("ChestYard", -12.5, -60.5, 0.7854), ("ChestLab", 4.5, -77.5, -1.5708)]
# The four clouds the Vape-koning hides in, around the middle of his palace.
HIDEOUTS = [(-35, -122), (-19, -122), (-35, -136), (-19, -136)]
CHECKPOINT = (-33, -48)
BENCH = (-26.85, -44, 1.5708)


def main():
    d = Dungeon()
    d.build_rooms(ROOMS, PROPS)
    d.build_labels_and_lights(LABELS, LIGHTS)
    ext = [("PackedScene", "res://scenes/enemies/Driller.tscn", "21_driller"),
           ("PackedScene", "res://scenes/enemies/VapeDriller.tscn", "22_vape"),
           ("PackedScene", "res://scenes/world/props/Chest.tscn", "23_chest"),
           ("PackedScene", "res://scenes/bosses/VapeKing.tscn", "24_king"),
           ("PackedScene", "res://scenes/bosses/VapeHideout.tscn", "25_hideout"),
           ("PackedScene", "res://scenes/world/props/Checkpoint.tscn", "26_checkpoint"),
           ("PackedScene", "res://scenes/world/props/RestBench.tscn", "27_bench")]
    extra = ['[node name="Checkpoint" parent="." instance=ExtResource("26_checkpoint")]', f"position = {vec(CHECKPOINT[0], 0, CHECKPOINT[1])}", "",
             '[node name="RestBench" parent="." instance=ExtResource("27_bench")]', f"position = {vec(BENCH[0], 0, BENCH[1])}",
             f"rotation = {vec(0, BENCH[2], 0)}", "",
             '[node name="BossArena" type="Node3D" parent="."]', "",
             '[node name="Hideouts" type="Node3D" parent="BossArena"]', ""]
    for n, (x, z) in enumerate(HIDEOUTS, 1):
        extra += [f'[node name="Cloud{n}" parent="BossArena/Hideouts" instance=ExtResource("25_hideout")]', f"position = {vec(x, 0, z)}", ""]
    centre = (sum(x for x, _ in HIDEOUTS) / len(HIDEOUTS), sum(z for _, z in HIDEOUTS) / len(HIDEOUTS))
    extra += ['[node name="VapeKing" parent="BossArena" instance=ExtResource("24_king")]', f"position = {vec(HIDEOUTS[0][0], 0, HIDEOUTS[0][1])}",
              'hideouts_path = NodePath("../Hideouts")', "",
              '[node name="MarkerBoss" type="Marker3D" parent="BossArena"]', f"position = {vec(centre[0], 1, centre[1])}", 'script = ExtResource("4_marker")',
              "ids = Array[StringName]([&\"vape_koning\"])", ""]
    for name, x, z, yaw in CHESTS:
        extra += [f'[node name="{name}" parent="." instance=ExtResource("23_chest")]', f"position = {vec(x, 0, z)}",
                  f"rotation = {vec(0, yaw, 0)}", ""]
    extra += ['[node name="Enemies" type="Node3D" parent="."]', ""]
    for name, rid, x, z, yaw in ENEMIES:
        extra += [f'[node name="{name}" parent="Enemies" instance=ExtResource("{rid}")]',
                  f"position = {vec(x, 0, z)}", f"rotation = {vec(0, yaw, 0)}", ""]
    world = {"root": "WesteraamDungeon", "location_name": "Westeraam Getho", "location_id": "westeraam_dungeon",
             "ambient": (0.42, 0.38, 0.3), "nav_id": "NavigationMesh_westeraam", "nav_aabb": (-48, -2, -148, 70, 12, 162),
             "exit": (11.25, 10, 8, "WesteraamExit", BLACK)}
    d.write(OUT, world, ext, extra)
    print("wrote", OUT, "with", len(ENEMIES), "enemies")


if __name__ == "__main__":
    main()
