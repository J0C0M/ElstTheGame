"""Builds scenes/dungeons/Westeraam.tscn: the Westeraam dungeon of Quest 3.

Run from the project root: python3 tools/dungeons/gen_westeraam.py

Five rooms from south to north: the entrance hall of the flats, a long
gallery with drillers, a vape shop off to the east, the courtyard with a
mixed group, and the Vape-paleis where the Vape-koning hides in four vape
clouds. +x is east, -z is north (deeper in).
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from dungeon_builder import Dungeon, vec  # noqa: E402

OUT = pathlib.Path("scenes/dungeons/Westeraam.tscn")

YELLOW = (0.92, 0.75, 0.2)
BLACK = (0.12, 0.12, 0.13)
CONCRETE = (0.48, 0.47, 0.44)
WOOD = (0.5, 0.36, 0.22)
STEEL = (0.45, 0.45, 0.48)
PURPLE = (0.45, 0.25, 0.6)
GOLD = (1.0, 0.78, 0.2)

ROOMS = {
    "Portiek": ((-6, 6, 0, 12), (0.55, 0.5, 0.3), 4.0, {"N": [(0, 3)], "S": [], "W": [], "E": []}),
    "Galerij": ((-3, 3, -28, 0), CONCRETE, 3.6, {"N": None, "S": None, "W": [], "E": [(-18, 3)]}),
    "Vapeshop": ((3, 17, -24, -12), (0.3, 0.22, 0.35), 3.6, {"N": [], "S": [], "W": None, "E": []}),
    "Binnenplaats": ((-12, 12, -52, -28), (0.4, 0.38, 0.3), 9.0, {"N": [(0, 4)], "S": [(0, 3)], "W": [], "E": []}),
    "Paleis": ((-15, 15, -82, -52), (0.2, 0.14, 0.24), 7.0, {"N": [], "S": None, "W": [], "E": []}),
}
# (name, centre x, centre z, size, colour, solid)
PROPS = [
    ("Mailboxes", 5.4, 6, (0.6, 1.6, 4.0), STEEL, True),
    ("Doormat", 0, 10, (2.0, 0.02, 1.2), BLACK, False),
    ("Counter", 10, -14, (6, 1.1, 1.0), (0.25, 0.2, 0.28), True),
    ("ShelfShop1", 16.4, -18, (0.8, 2.2, 6), (0.35, 0.3, 0.4), True),
    ("ShelfShop2", 8, -23.4, (6, 2.2, 0.8), (0.35, 0.3, 0.4), True),
    ("Scooter1", -9, -32, (0.6, 1.0, 1.6), YELLOW, True),
    ("Scooter2", -9, -35, (0.6, 1.0, 1.6), BLACK, True),
    ("Scooter3", 9.5, -48, (0.6, 1.0, 1.6), YELLOW, True),
    ("BurntCar", 6, -38, (2.0, 1.4, 4.2), (0.18, 0.16, 0.15), True),
    ("BenchYard1", -10.6, -44, (0.6, 0.5, 2.4), WOOD, True),
    ("BenchYard2", 10.6, -40, (0.6, 0.5, 2.4), WOOD, True),
    ("Bins", -3, -50.8, (3.0, 1.3, 1.0), (0.2, 0.3, 0.2), True),
    ("Throne", 0, -80, (2.4, 2.2, 1.6), GOLD, True),
    ("Carpet", 0, -72, (4, 0.02, 14), (0.6, 0.12, 0.2), False),
    ("SofaLeft", -12.5, -67, (1.2, 0.9, 4.0), PURPLE, True),
    ("SofaRight", 12.5, -67, (1.2, 0.9, 4.0), PURPLE, True),
    ("CrateCash", -12, -79, (1.6, 1.2, 1.6), WOOD, True),
]
# (name, x, y, z, yaw, text, colour)
LABELS = [
    ("SignPortiek", 0, 3.0, 0.55, 0, "WESTERAAM", YELLOW),
    ("SignShop", 10, 2.6, -12.55, 3.14159, "VAPE SHOP", (0.75, 0.45, 1.0)),
    ("SignPaleis", 0, 5.2, -51.45, 0, "VAPE-PALEIS", GOLD),
    ("GraffitiYard", -11.45, 3.0, -40, 1.5708, "AMBER WAS HERE", (0.95, 0.5, 0.15)),
    ("LabelCash", -12, 1.4, -78.15, 0, "CASH", (0.1, 0.1, 0.1)),
]
# (name, x, y, z, colour, energy, range)
LIGHTS = [
    ("LightPortiek", 0, 3.4, 6, (1.0, 0.9, 0.6), 1.5, 11),
    ("LightGalerij1", 0, 3.1, -6, (0.9, 0.9, 0.75), 1.2, 9),
    ("LightGalerij2", 0, 3.1, -16, (0.9, 0.9, 0.75), 1.2, 9),
    ("LightGalerij3", 0, 3.1, -25, (0.9, 0.9, 0.75), 1.2, 9),
    ("LightShop", 10, 3.1, -18, (0.75, 0.45, 1.0), 1.8, 11),
    ("LightYard1", -6, 6.5, -34, (1.0, 0.8, 0.45), 1.8, 16),
    ("LightYard2", 6, 6.5, -46, (1.0, 0.8, 0.45), 1.8, 16),
    ("LightPaleis1", -8, 6.0, -60, (0.7, 0.35, 1.0), 2.0, 16),
    ("LightPaleis2", 8, 6.0, -60, (0.7, 0.35, 1.0), 2.0, 16),
    ("LightPaleis3", -8, 6.0, -75, (1.0, 0.7, 0.3), 2.0, 16),
    ("LightPaleis4", 8, 6.0, -75, (1.0, 0.7, 0.3), 2.0, 16),
]
# Enemies: (name, scene id, x, z, yaw). Drillers flank, vape-drillers keep their distance.
ENEMIES = [
    ("Driller1", "21_driller", 0, -10, 0), ("Driller2", "21_driller", -1, -21, 0.3),
    ("VapeDriller1", "22_vape", 12, -16, 1.2), ("VapeDriller2", "22_vape", 14, -21, 1.6),
    ("Driller3", "21_driller", -6, -36, 0.3), ("Driller4", "21_driller", 5, -44, -0.4),
    ("VapeDriller3", "22_vape", -8, -48, 0.6), ("VapeDriller4", "22_vape", 8, -32, -0.8),
]
CHESTS = [("ChestShop", 15.5, -13.5, -1.5708), ("ChestYard", -10.5, -50.5, 0.7854)]
# The four clouds the Vape-koning hides in, around the middle of his palace.
HIDEOUTS = [(-8, -61), (8, -61), (-8, -74), (8, -74)]


def main():
    d = Dungeon()
    d.build_rooms(ROOMS, PROPS)
    d.build_labels_and_lights(LABELS, LIGHTS)
    ext = [("PackedScene", "res://scenes/enemies/Driller.tscn", "21_driller"),
           ("PackedScene", "res://scenes/enemies/VapeDriller.tscn", "22_vape"),
           ("PackedScene", "res://scenes/world/props/Chest.tscn", "23_chest"),
           ("PackedScene", "res://scenes/bosses/VapeKing.tscn", "24_king"),
           ("PackedScene", "res://scenes/bosses/VapeHideout.tscn", "25_hideout")]
    extra = ['[node name="BossArena" type="Node3D" parent="."]', "",
             '[node name="Hideouts" type="Node3D" parent="BossArena"]', ""]
    for n, (x, z) in enumerate(HIDEOUTS, 1):
        extra += [f'[node name="Cloud{n}" parent="BossArena/Hideouts" instance=ExtResource("25_hideout")]', f"position = {vec(x, 0, z)}", ""]
    extra += ['[node name="VapeKing" parent="BossArena" instance=ExtResource("24_king")]', f"position = {vec(*HIDEOUTS[0][:1], 0, HIDEOUTS[0][1])}",
              'hideouts_path = NodePath("../Hideouts")', "",
              '[node name="MarkerBoss" type="Marker3D" parent="BossArena"]', "position = Vector3(0, 1, -67)", 'script = ExtResource("4_marker")',
              "ids = Array[StringName]([&\"vape_koning\"])", ""]
    for name, x, z, yaw in CHESTS:
        extra += [f'[node name="{name}" parent="." instance=ExtResource("23_chest")]', f"position = {vec(x, 0, z)}",
                  f"rotation = {vec(0, yaw, 0)}", ""]
    extra += ['[node name="Enemies" type="Node3D" parent="."]', ""]
    for name, rid, x, z, yaw in ENEMIES:
        extra += [f'[node name="{name}" parent="Enemies" instance=ExtResource("{rid}")]',
                  f"position = {vec(x, 0, z)}", f"rotation = {vec(0, yaw, 0)}", ""]
    world = {"root": "WesteraamDungeon", "location_name": "Westeraam Getho", "location_id": "westeraam_dungeon",
             "ambient": (0.42, 0.38, 0.3), "nav_id": "NavigationMesh_westeraam", "nav_aabb": (-17, -2, -84, 36, 12, 98),
             "exit": (11.25, 10, 8, "WesteraamExit", BLACK)}
    d.write(OUT, world, ext, extra)
    print("wrote", OUT, "with", len(ENEMIES), "enemies")


if __name__ == "__main__":
    main()
