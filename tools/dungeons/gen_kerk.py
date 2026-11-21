"""Builds scenes/dungeons/Kerk.tscn: the Kerk van Amber of Quest 6.

Run from the project root: python3 tools/dungeons/gen_kerk.py

The last and hardest dungeon goes down, level by level:
- 0 m, the church: a porch, the nave with pews and a middle aisle, two
  side aisles behind arcades, the choir with the altar, pulpit and organ,
  and the sacristy where the stairs go down;
- -5 m, the crypt: a corridor with grave niches, a tomb hall with
  sarcophagi and two dead ends (a chest, and an ambush);
- -10 m, the catacombs: a high cave with walls of skulls and amber crystals,
  a corridor west to the shrine of Amber (an idol of her head, cultists and
  a chest), and a wide tunnel with fire grates where fatbikers charge and
  little dragons fly;
- -15 m, the antechamber: quiet, with Klaas, a checkpoint and a bench, and
  the gate to the round arena of Amber with five long pillars.
Stairs are ramps, so the player can walk back up. No two rooms lie above
each other, so each room is found by its x and z. +x is east, -z is north.
"""
import math
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from dungeon_builder import Dungeon, aim_enemies, open_sides, vec  # noqa: E402

OUT = pathlib.Path("scenes/dungeons/Kerk.tscn")

STONE = (0.72, 0.68, 0.6)
DARK_STONE = (0.42, 0.39, 0.36)
CRYPT = (0.36, 0.33, 0.3)
CATACOMB = (0.3, 0.26, 0.22)
AMBER = (0.95, 0.55, 0.12)
ORANGE = (1.0, 0.45, 0.1)
WOOD = (0.42, 0.26, 0.14)
RED = (0.6, 0.12, 0.1)
GOLD = (0.95, 0.78, 0.25)
WHITE = (0.92, 0.9, 0.85)
GLASS = [(0.95, 0.55, 0.12), (0.8, 0.2, 0.15), (0.25, 0.4, 0.9), (0.6, 0.3, 0.8), (0.95, 0.85, 0.3)]

# The wall of the arena meets the gate at z = -206; Amber needs room to run a
# lap between the pillars and the wall.
ARENA_CENTRE = (12, -233)
ARENA_RADIUS = 27
PILLAR_RING = 13.5
ARENA_FLOOR = -15

# Arcades between the nave and the side aisles: (centre z, width, top).
ARCADES = [(-14, 5, 6), (-22, 5, 6), (-30, 5, 6), (-38, 5, 6)]
ROOMS = {
    # Level 0: the church. The higher or wider room of two neighbours builds
    # the wall between them; open_sides() checks that none is left open.
    "Portaal": ((-6, 6, -10, 0), STONE, 5.0, {"N": None, "S": [], "W": [], "E": []}),
    "Schip": ((-8, 8, -46, -10), STONE, 12.0, {"N": [(0, 14)], "S": [(0, 4)], "W": ARCADES, "E": ARCADES},
              {"floor_color": (0.5, 0.42, 0.36)}),
    "ZijbeukWest": ((-16, -8, -46, -10), STONE, 7.0, {"N": [], "S": [], "W": [], "E": None}),
    "ZijbeukOost": ((8, 16, -46, -10), STONE, 7.0, {"N": [], "S": [], "W": None, "E": []}),
    "Koor": ((-8, 8, -58, -46), STONE, 12.0, {"N": [], "S": None, "W": [], "E": [(-54, 3)]}, {"floor_color": (0.5, 0.42, 0.36)}),
    "Sacristie": ((8, 16, -58, -50), DARK_STONE, 4.0, {"N": [(12, 6)], "S": [], "W": None, "E": []}),
    # Stairs are 6 m wide rooms with a ramp, as wide as the doorways they join.
    "Trap1": ((9, 15, -76, -58), CRYPT, 9.0, {"N": [(12, 6)], "S": None, "W": [], "E": []}, {"floor": -5}),
    # Level -5: the crypt.
    "Cryptegang": ((9, 15, -100, -76), CRYPT, 4.0, {"N": [(12, 6)], "S": None, "W": [(-88, 4)], "E": [(-88, 3)]}, {"floor": -5}),
    "Grafkamer": ((-10, 9, -96, -80), CRYPT, 4.0, {"N": [], "S": [], "W": [(-88, 3)], "E": None}, {"floor": -5}),
    "Doodlopend1": ((15, 25, -92, -84), CRYPT, 3.6, {"N": [], "S": [], "W": None, "E": []}, {"floor": -5}),
    "Doodlopend2": ((-20, -10, -94, -82), CRYPT, 3.6, {"N": [], "S": [], "W": [], "E": None}, {"floor": -5}),
    "Trap2": ((9, 15, -118, -100), CATACOMB, 9.0, {"N": None, "S": None, "W": [], "E": []}, {"floor": -10}),
    # Level -10: the catacombs, a high cave, the shrine of Amber and the tunnel.
    "Catacomben": ((4, 20, -130, -118), CATACOMB, 9.0, {"N": [(12, 12, 5)], "S": [(12, 6)], "W": [(-124, 4)], "E": []}, {"floor": -10}),
    "GangWest": ((-30, 4, -127, -121), CATACOMB, 4.0, {"N": [], "S": [], "W": None, "E": None}, {"floor": -10}),
    "Heiligdom": ((-46, -30, -136, -112), (0.32, 0.22, 0.16), 7.0, {"N": [], "S": [], "W": [], "E": [(-124, 4)]}, {"floor": -10}),
    "Fietstunnel": ((6, 18, -170, -130), CATACOMB, 5.0, {"N": [(12, 6)], "S": None, "W": [], "E": []}, {"floor": -10}),
    "Trap3": ((9, 15, -188, -170), DARK_STONE, 9.0, {"N": None, "S": None, "W": [], "E": []}, {"floor": -15}),
    # Level -15: the antechamber and the way into the arena.
    "Voorkamer": ((2, 22, -204, -188), DARK_STONE, 9.0, {"N": [(12, 6)], "S": [(12, 6)], "W": [], "E": []}, {"floor": -15}),
    "Poort": ((9, 15, -210, -204), DARK_STONE, 6.0, {"N": None, "S": None, "W": [], "E": []}, {"floor": -15}),
}


# (name, x, z, size, colour, solid, floor height)
PROPS = [
    # The nave: pews either side of the middle aisle, a pulpit and a font.
    ("Pulpit", -6, -43.5, (1.6, 1.5, 1.6), WOOD, True, 0),
    ("PulpitTop", -6, -43.5, (2.0, 0.2, 2.0), WOOD, False, 1.5),
    ("Font", 5, -13, (1.2, 1.0, 1.2), STONE, True, 0),
    ("MiddleAisle", 0, -28, (3, 0.02, 36), RED, False, 0),
    # The choir: the altar on a carpet, candles and the organ against the north wall.
    ("AltarCarpet", 0, -52, (8, 0.02, 6), RED, False, 0),
    ("Altar", 0, -52, (4, 1.1, 1.6), WHITE, True, 0),
    ("AltarCloth", 0, -52, (4.2, 0.1, 1.8), AMBER, False, 1.1),
    ("OrganCase", 0, -57.2, (8, 3, 1.4), WOOD, True, 0),
    # The crypt: sarcophagi and grave niches.
    ("Sarcophagus1", -6, -84, (1.2, 0.9, 2.4), DARK_STONE, True, -5),
    ("Sarcophagus2", -2, -84, (1.2, 0.9, 2.4), DARK_STONE, True, -5),
    ("Sarcophagus3", 2, -84, (1.2, 0.9, 2.4), DARK_STONE, True, -5),
    ("Sarcophagus4", -2, -92, (1.2, 0.9, 2.4), DARK_STONE, True, -5),
    ("Sarcophagus5", 6, -92, (1.2, 0.9, 2.4), DARK_STONE, True, -5),
    ("AmbushCoffin", -18, -88, (1.2, 0.7, 2.2), WOOD, True, -5),
    # The catacombs: bone heaps and old bikes in the tunnel.
    ("BoneHeap2", -24, -126, (1.6, 0.6, 1.0), WHITE, True, -10),
    ("BikeWreck", 16.5, -150, (1.0, 1.0, 2.2), (0.3, 0.1, 0.1), True, -10),
    ("Barrels", 7.2, -138, (1.2, 1.2, 1.2), AMBER, True, -10),
    # The antechamber: a carpet towards the arena gate.
    ("GateCarpet", 12, -196, (4, 0.02, 14), RED, False, -15),
]
for row, z in enumerate(range(-16, -41, -3)):
    for side, x in (("W", -4.6), ("O", 4.6)):
        PROPS.append((f"Pew{side}{row}", x, z, (5.4, 0.5, 0.6), WOOD, True, 0))
        PROPS.append((f"PewBack{side}{row}", x, z + 0.35, (5.4, 1.0, 0.12), WOOD, False, 0))
for i in range(9):
    PROPS.append((f"OrganPipe{i}", -3.6 + i * 0.9, -57.4, (0.4, 4 + abs(4 - i) * -0.5 + 3, 0.4), GOLD, False, 3))
for n, (x, z) in enumerate([(9.6, -80), (9.6, -86), (9.6, -92), (9.6, -98), (14.4, -80), (14.4, -96)]):
    PROPS.append((f"Niche{n}", x, z, (0.3, 1.2, 1.6), (0.3, 0.22, 0.16), False, -4))
    PROPS.append((f"Skull{n}", x + (0.18 if x < 12 else -0.18), z, (0.25, 0.25, 0.28), WHITE, False, -3.8))

# (name, x, y, z, yaw, text, colour)
LABELS = [
    ("SignAltar", 0, 7.0, -57.9, 0, "AMBER ZIJ GEPREZEN", AMBER),
    ("SignCrypt", 12, -1.6, -75.6, 0, "CRYPTE", (0.8, 0.75, 0.65)),
    ("SignArena", 12, -9.6, -203.6, 0, "HET HOL VAN AMBER", ORANGE),
]
# (name, x, y, z, colour, energy, range)
LIGHTS = [
    ("LightPortaal", 0, 4.0, -5, (1.0, 0.9, 0.75), 1.4, 10),
    ("LightSchip1", 0, 10, -18, (1.0, 0.85, 0.6), 2.2, 20),
    ("LightSchip2", 0, 10, -36, (1.0, 0.85, 0.6), 2.2, 20),
    ("LightWest", -12, 5.5, -28, (1.0, 0.8, 0.55), 1.4, 14),
    ("LightOost", 12, 5.5, -28, (1.0, 0.8, 0.55), 1.4, 14),
    ("LightAltar", 0, 6, -51, (1.0, 0.55, 0.15), 3.0, 14),
    ("LightSacristie", 12, 3, -54, (1.0, 0.75, 0.5), 1.0, 8),
    ("LightTrap1", 12, 0, -68, (1.0, 0.7, 0.4), 1.8, 14),
    ("LightCrypte1", 12, -2, -82, (1.0, 0.65, 0.35), 2.2, 14),
    ("LightCrypte2", 12, -2, -96, (1.0, 0.65, 0.35), 2.2, 14),
    ("LightGraf", -1, -1.5, -88, (1.0, 0.6, 0.3), 2.5, 18),
    ("LightDood1", 20, -2.5, -88, (1.0, 0.6, 0.3), 1.4, 12),
    ("LightDood2", -15, -2.5, -88, (1.0, 0.4, 0.2), 1.4, 12),
    ("LightTrap2", 12, -5, -110, (1.0, 0.6, 0.3), 1.8, 14),
    ("LightCata", 12, -6.5, -124, (1.0, 0.5, 0.15), 2.5, 16),
    ("LightGangWest", -12, -6.5, -124, (1.0, 0.5, 0.15), 1.8, 16),
    ("LightHeiligdom", -38, -5, -124, (1.0, 0.45, 0.1), 2.6, 16),
    ("LightTunnel1", 12, -6, -140, (1.0, 0.5, 0.15), 2.5, 18),
    ("LightTunnel2", 12, -6, -160, (1.0, 0.5, 0.15), 2.5, 18),
    ("LightTrap3", 12, -10, -180, (1.0, 0.55, 0.2), 1.8, 14),
    ("LightVoorkamer", 12, -10.5, -196, (1.0, 0.8, 0.5), 3.2, 18),
    ("LightArena1", 12, -3, -233, (1.0, 0.45, 0.1), 3.0, 34),
    ("LightArena2", 12, -12, -214, (1.0, 0.5, 0.15), 1.6, 16),
    ("LightArena3", -3, -8, -233, (1.0, 0.6, 0.3), 2.2, 22),
    ("LightArena4", 27, -8, -233, (1.0, 0.6, 0.3), 2.2, 22),
    ("LightArena5", 12, -8, -251, (1.0, 0.6, 0.3), 2.2, 22),
    ("LightCataCrystal", 6, -7, -128, (1.0, 0.6, 0.15), 1.6, 10),
    ("LightTunnel3", 12, -6, -150, (1.0, 0.45, 0.1), 2.0, 16),
    ("LightGateWest", 6, -12, -201, (1.0, 0.5, 0.15), 1.8, 9),
    ("LightGateEast", 18, -12, -201, (1.0, 0.5, 0.15), 1.8, 9),
]
# Enemies of every faction, as strong as in their own dungeon. (name, scene id, x, z, yaw)
ENEMIES = [
    # The church.
    ("Driller1", "21_driller", 0, -44, 0), ("VapeDriller1", "22_vape", -5, -44.5, 0), ("VapeDriller2", "22_vape", 5, -44.5, 0),
    ("Opa1", "26_opa", 0, -28, 0), ("Driller2", "21_driller", -12, -20, 0), ("Driller3", "21_driller", 12, -30, 0),
    ("LowDriller1", "20_low", -12, -38, 0), ("Opa2", "26_opa", 12, -16, 0), ("Driller4", "21_driller", -5, -55, 0),
    ("Driller5", "21_driller", 5, -55, 0), ("VapeDriller3", "22_vape", -4, -49, 0), ("LowDriller2", "20_low", 12, -54, 0),
    # The crypt.
    ("Oma1", "25_oma", 12, -82, 0), ("LowDriller3", "20_low", 12, -94, 0), ("Oma2", "25_oma", -4, -88, 0),
    ("Rolstoel1", "27_rolstoel", 3, -94, 0), ("LowDriller4", "20_low", -7, -92, 0), ("Oma3", "25_oma", -15, -85, 0),
    ("Oma4", "25_oma", -15, -91, 0), ("Opa3", "26_opa", -17, -88, 0),
    # The catacombs.
    ("VapeDriller4", "22_vape", 8, -126, 0), ("Voetballer1", "23_voetballer", 16, -122, 0),     ("Rolstoel2", "27_rolstoel", -34, -116, 0), ("Fatbiker1", "24_fatbiker", 12, -140, 0), ("Fatbiker2", "24_fatbiker", 9, -155, 0),
    ("Voetballer2", "23_voetballer", 15, -160, 0),
    # Amber's own: cultists who chant and little dragons who fly and spit fire.
    ("Cultist1", "28_cultist", 0, -49.5, 0), ("Cultist2", "28_cultist", -1, -81.5, 0), ("Cultist3", "28_cultist", 12, -121, 0),
    ("Cultist4", "28_cultist", -38, -118, 0), ("Cultist5", "28_cultist", -38, -130, 0), ("Cultist6", "28_cultist", -39.5, -124, 0),
    ("Dragonling1", "29_dragonling", 8, -127, 0), ("Dragonling2", "29_dragonling", -34, -124, 0),
    ("Dragonling3", "29_dragonling", 12, -148, 0), ("Dragonling4", "29_dragonling", 12, -163, 0),
]
# The hardest dungeon: nearly all of them face the player coming in.
ENEMIES = aim_enemies(ENEMIES, ROOMS, (0, -4), 0.85, seed=11)
CHESTS = [("ChestCrypte", 23, -88, -1.5708), ("ChestHeiligdom", -44.5, -132.5, 0.7854)]
CHECKPOINT = (8, -196)
BENCH = (21.15, -196, 1.5708)
KLAAS_SPOT = (12, -199)


def floor_at(x, z):
    """Floor height of the room that holds (x, z)."""
    for (x0, x1, z0, z1), *_rest in ROOMS.values():
        if x0 <= x <= x1 and z0 <= z <= z1:
            return _rest[3].get("floor", 0) if len(_rest) > 3 else 0
    return ARENA_FLOOR


def build_church_details(d):
    """Pillars between the arcades, stained glass, banners and candles."""
    for side in (-1, 1):
        x = side * 8
        for n, z in enumerate((-18, -26, -34)):
            d.visual("Structure", f"Banner{'W' if side < 0 else 'O'}{n}", (x - side * 0.56, 8.5, z), (0.08, 3.5, 1.4), AMBER)
            d.visual("Structure", f"BannerMark{'W' if side < 0 else 'O'}{n}", (x - side * 0.6, 9.0, z), (0.06, 0.9, 0.9), (0.15, 0.08, 0.05))
        for n, z in enumerate((-14, -22, -30, -38)):
            d.visual("Structure", f"Clerestory{'W' if side < 0 else 'O'}{n}", (x - side * 0.52, 9.5, z), (0.06, 2.6, 1.6), GLASS[n % 5],
                     glow=True)
            d.visual("Structure", f"Window{'W' if side < 0 else 'O'}{n}", (side * 15.48, 3.6, z), (0.06, 3.2, 1.6), GLASS[(n + 2) % 5],
                     glow=True)
    d.visual("Structure", "RoseWindow", (0, 8.5, -57.9 + 0.38), (3.6, 3.6, 0.06), AMBER, glow=True)
    for x in (-1.6, 1.6):
        d.visual("Structure", f"Candle{int(x * 10)}", (x, 1.45, -52), (0.12, 0.6, 0.12), WHITE)
        d.visual("Structure", f"Flame{int(x * 10)}", (x, 1.85, -52), (0.12, 0.2, 0.12), ORANGE, glow=True)


def build_crypt_and_catacomb_details(d):
    for n, (x, y, z) in enumerate([(9.6, -3.6, -83), (14.4, -3.6, -90), (-9.4, -3.6, -86), (19.6, -8.6, -124), (6.6, -8.6, -145),
                                   (17.4, -8.6, -158), (-29.6, -8.6, -124)]):
        d.visual("Structure", f"Torch{n}", (x, y, z), (0.15, 0.4, 0.15), ORANGE, glow=True)
    for n, (x, z, length, yaw) in enumerate([(12, -134, 6, 0.3), (8, -148, 5, -0.4), (15, -164, 7, 0.2), (-14, -123, 5, 1.4), (12, -122, 4, 1.0)]):
        d.visual("Structure", f"Crack{n}", (x, -9.97, z), (0.25, 0.02, length), ORANGE, rot=(0, yaw), glow=True)


def build_lower_details(d):
    """The catacomb cave, the shrine of Amber, the tunnel and the gate."""
    # Walls of skulls on both sides of the cave, and amber crystals.
    for x in (4.55, 19.45):
        for row in range(4):
            for col in range(6):
                z = -128.5 + col * 1.6 + (0.8 if row % 2 else 0)
                if -126 < z < -122 and x < 10:
                    continue
                d.visual("Structure", f"CaveSkull{int(x)}_{row}_{col}", (x, -9 + row * 0.9, z), (0.22, 0.24, 0.26), WHITE)
    for n, (x, z, h, yaw) in enumerate([(5.5, -129, 2.4, 0.3), (6.3, -128.4, 1.6, 1.0), (18.6, -119, 2.0, 0.6), (19, -120, 1.2, 1.4),
                                        (5.2, -119.2, 1.4, 0.8)]):
        d.visual("Structure", f"Crystal{n}", (x, -10 + h / 2, z), (0.5, h, 0.5), AMBER, rot=(0.2, yaw), glow=True)
    for n, (x, z, length) in enumerate([(8, -122, 1.6), (15, -127, 2.2), (11, -125, 1.2), (17, -121, 1.8), (6, -125, 1.4)]):
        d.visual("Structure", f"Stalactite{n}", (x, -1 - length / 2, z), (0.5, length, 0.5), CATACOMB)
    # The shrine of Amber: her head as an idol, small pews and candles.
    d.solid("Structure", "IdolPedestal", (-43.5, -9.25, -124), (3, 1.5, 4), DARK_STONE)
    d.solid("Structure", "IdolHead", (-43.5, -7.2, -124), (2.6, 2.4, 2.4), AMBER)
    d.visual("Structure", "IdolSnout", (-41.7, -7.6, -124), (1.4, 1.2, 1.6), AMBER)
    d.visual("Structure", "IdolJaw", (-41.9, -8.5, -124), (1.2, 0.3, 1.4), (0.55, 0.25, 0.08))
    for dz in (-0.7, 0.7):
        d.visual("Structure", f"IdolHorn{int(dz * 10)}", (-44.3, -5.4, -124 + dz), (0.4, 1.4, 0.4), (0.3, 0.15, 0.05), rot=(dz * 0.5, 0))
        d.visual("Structure", f"IdolEye{int(dz * 10)}", (-42.18, -6.8, -124 + dz * 0.8), (0.06, 0.3, 0.4), (1.0, 0.9, 0.2), glow=True)
    for row, x in enumerate((-37, -34.5)):
        for z in (-128, -120):
            d.solid("Structure", f"ShrinePew{row}{abs(z)}", (x, -9.75, z), (0.6, 0.5, 3.4), WOOD)
    for n, (x, z) in enumerate([(-42, -128.5), (-42, -119.5), (-45, -128.5), (-45, -119.5)]):
        d.visual("Structure", f"ShrineCandle{n}", (x, -9.3, z), (0.25, 1.4, 0.25), WHITE)
        d.visual("Structure", f"ShrineFlame{n}", (x, -8.45, z), (0.22, 0.3, 0.22), ORANGE, glow=True)
    for n, z in enumerate((-133, -115)):
        d.visual("Structure", f"ShrineBanner{n}", (-45.4, -6, z), (0.08, 3.5, 1.6), AMBER)
    # The tunnel: rubble, wrecked bikes and skull niches.
    for n, (x, z, w) in enumerate([(7.4, -146, 1.4), (16.8, -152, 1.2), (8, -166, 1.0), (16.5, -137, 1.6)]):
        d.solid("Structure", f"Rubble{n}", (x, -10 + w * 0.3, z), (w, w * 0.6, w * 1.3), CATACOMB, rot=(0, n * 0.7))
    for n, z in enumerate(range(-136, -168, -6)):
        for x in (6.45, 17.55):
            d.visual("Structure", f"TunnelSkull{n}{int(x)}", (x, -8.6, z), (0.2, 0.24, 0.26), WHITE)
    # The gate of the arena: two dragon heads on pedestals and braziers.
    for x in (6, 18):
        d.solid("Structure", f"GateStatue{x}", (x, -14, -201.5), (2, 2, 2), DARK_STONE)
        d.visual("Structure", f"GateHead{x}", (x, -12, -201.6), (1.6, 1.8, 1.8), AMBER)
        d.visual("Structure", f"GateEyes{x}", (x, -11.7, -200.68), (1.0, 0.18, 0.06), (1.0, 0.85, 0.2), glow=True)
        d.visual("Structure", f"GateFire{x}", (x + (2 if x < 12 else -2), -14.2, -202.5), (0.7, 0.6, 0.7), ORANGE, glow=True)
    for n, x in enumerate((2.6, 21.4)):
        d.visual("Structure", f"VoorkamerBanner{n}", (x, -10.5, -196), (0.08, 4, 1.8), AMBER)


def pillar_spots():
    """The five pillars of the arena, PILLAR_RING m from its middle."""
    cx, cz = ARENA_CENTRE
    return [(cx + PILLAR_RING * math.cos(-math.pi / 2 + i * math.tau / 5), cz + PILLAR_RING * math.sin(-math.pi / 2 + i * math.tau / 5))
            for i in range(5)]


def build_arena(d):
    cx, cz = ARENA_CENTRE
    d.round_room("Arena", ARENA_CENTRE, ARENA_RADIUS, ARENA_FLOOR, 16, DARK_STONE, segments=48, gaps=(math.pi / 2,), gap_width=4)
    for i, (x, z) in enumerate(pillar_spots()):
        d.solid("Structure", f"Pillar{i}", (x, ARENA_FLOOR + 8, z), (2.6, 16, 2.6), STONE)
        d.visual("Structure", f"PillarTurn{i}", (x, ARENA_FLOOR + 8, z), (2.6, 16, 2.6), STONE, rot=(0, math.pi / 4))
        d.visual("Structure", f"PillarBand{i}", (x, ARENA_FLOOR + 3, z), (2.9, 0.4, 2.9), AMBER)
    for n in range(10):
        angle = n * math.tau / 10 + 0.3
        r = 6 + (n % 3) * 5.5
        d.visual("Structure", f"ArenaCrack{n}", (cx + r * math.cos(angle), ARENA_FLOOR + 0.02, cz + r * math.sin(angle)),
                 (0.3, 0.02, 5 + n % 4), ORANGE, rot=(0, angle), glow=True)
    d.visual("Structure", "ArenaHeart", (cx, ARENA_FLOOR + 0.03, cz), (5, 0.02, 5), AMBER, rot=(0, math.pi / 4), glow=True)


def main():
    # The arena closes the gate's north side; every other side must be shut.
    left_open = [side for side in open_sides(ROOMS) if side != "Poort N"]
    if left_open:
        sys.exit("Open walls: " + ", ".join(left_open))
    d = Dungeon()
    d.build_rooms(ROOMS, PROPS)
    for name, x, z_a, y_a, z_b, y_b in (("Stairs1", 12, -58, 0, -73, -5), ("Stairs2", 12, -100, -5, -115, -10), ("Stairs3", 12, -170, -10, -185, -15)):
        d.ramp(name, x, 6, z_a, y_a, z_b, y_b, DARK_STONE)
    build_church_details(d)
    build_crypt_and_catacomb_details(d)
    build_lower_details(d)
    build_arena(d)
    d.build_labels_and_lights(LABELS, LIGHTS)
    # The gate of the arena: shut until Klaas is ready.
    d.solid(".", "ArenaGate", (12, ARENA_FLOOR + 2.5, -205.5), (7, 5, 0.6), (0.3, 0.2, 0.12))
    d.nodes[-3] += ['script = ExtResource("34_gate")', 'open_flag = &"klaas_ready"']
    d.nodes[-2][0] = d.nodes[-2][0].replace('parent="./ArenaGate"', 'parent="ArenaGate"')
    d.nodes[-1][0] = d.nodes[-1][0].replace('parent="./ArenaGate"', 'parent="ArenaGate"')
    ext = [("PackedScene", "res://scenes/enemies/LowDriller.tscn", "20_low"),
           ("PackedScene", "res://scenes/enemies/Driller.tscn", "21_driller"),
           ("PackedScene", "res://scenes/enemies/VapeDriller.tscn", "22_vape"),
           ("PackedScene", "res://scenes/enemies/Voetballer.tscn", "23_voetballer"),
           ("PackedScene", "res://scenes/enemies/Fatbiker.tscn", "24_fatbiker"),
           ("PackedScene", "res://scenes/enemies/BozeOma.tscn", "25_oma"),
           ("PackedScene", "res://scenes/enemies/BingoOpa.tscn", "26_opa"),
           ("PackedScene", "res://scenes/enemies/RolstoelOma.tscn", "27_rolstoel"),
           ("PackedScene", "res://scenes/world/props/Chest.tscn", "30_chest"),
           ("PackedScene", "res://scenes/world/props/Checkpoint.tscn", "31_checkpoint"),
           ("PackedScene", "res://scenes/world/props/RestBench.tscn", "32_bench"),
           ("Script", "res://scenes/world/location_area.gd", "33_area"),
           ("Script", "res://scripts/world/flag_gate.gd", "34_gate"),
           ("PackedScene", "res://scenes/npcs/Klaas.tscn", "35_klaas"),
           ("Resource", "res://data/dialogue/klaas_church.tres", "36_dialogue"),
           ("PackedScene", "res://scenes/world/props/FireGrate.tscn", "37_grate"),
           ("PackedScene", "res://scenes/enemies/AmberCultist.tscn", "28_cultist"),
           ("PackedScene", "res://scenes/enemies/Dragonling.tscn", "29_dragonling"),
           ("PackedScene", "res://scenes/npcs/KlaasAlly.tscn", "38_ally"),
           ("PackedScene", "res://scenes/bosses/Amber.tscn", "39_amber")]
    extra = ['[node name="Checkpoint" parent="." instance=ExtResource("31_checkpoint")]', f"position = {vec(CHECKPOINT[0], -15, CHECKPOINT[1])}", "",
             '[node name="RestBench" parent="." instance=ExtResource("32_bench")]', f"position = {vec(BENCH[0], -15, BENCH[1])}",
             f"rotation = {vec(0, BENCH[2], 0)}", "",
             '[node name="Voorkamer" type="Area3D" parent="."]', f"position = {vec(12, -12, -196)}", "collision_layer = 0",
             "collision_mask = 2", 'script = ExtResource("33_area")', 'id = &"kerk_voorkamer"', 'display_name = "Het hart van de kerk"', "",
             '[node name="CollisionShape3D" type="CollisionShape3D" parent="Voorkamer"]', 'shape = SubResource("Shape_voorkamer")', "",
             '[node name="Klaas" parent="." instance=ExtResource("35_klaas")]', f"position = {vec(KLAAS_SPOT[0], -15, KLAAS_SPOT[1])}",
             "rotation = Vector3(0, 3.14159, 0)", 'dialogue = ExtResource("36_dialogue")', 'leave_on_flag = &"klaas_ready"', "",
             '[node name="KlaasAlly" parent="." instance=ExtResource("38_ally")]', f"position = {vec(KLAAS_SPOT[0], -15, KLAAS_SPOT[1])}",
             "rotation = Vector3(0, 3.14159, 0)", "",
             '[node name="Amber" parent="." instance=ExtResource("39_amber")]', f"position = {vec(ARENA_CENTRE[0], ARENA_FLOOR, ARENA_CENTRE[1] + 1.5)}",
             "rotation = Vector3(0, 3.14159, 0)", 'gate_path = NodePath("../ArenaGate")', 'klaas_path = NodePath("../KlaasAlly")',
             f"arena_centre = {vec(ARENA_CENTRE[0], ARENA_FLOOR, ARENA_CENTRE[1])}",
             "pillars = Array[Vector3]([" + ", ".join(vec(x, ARENA_FLOOR, z) for x, z in pillar_spots()) + "])", "",
             '[node name="MarkerKlaas" type="Marker3D" parent="."]', f"position = {vec(KLAAS_SPOT[0], -14, KLAAS_SPOT[1])}",
             'script = ExtResource("4_marker")', 'ids = Array[StringName]([&"klaas_church"])', "",
             '[node name="MarkerArena" type="Marker3D" parent="."]', f"position = {vec(ARENA_CENTRE[0], -14, ARENA_CENTRE[1])}",
             'script = ExtResource("4_marker")', 'ids = Array[StringName]([&"amber"])', ""]
    for n, (z, offset) in enumerate(((-143, 0.0), (-157, 2.2))):
        extra += [f'[node name="FireGrate{n + 1}" parent="." instance=ExtResource("37_grate")]', f"position = {vec(12, -10, z)}",
                  f"offset = {offset}", ""]
    for name, x, z, yaw in CHESTS:
        extra += [f'[node name="{name}" parent="." instance=ExtResource("30_chest")]', f"position = {vec(x, floor_at(x, z), z)}",
                  f"rotation = {vec(0, yaw, 0)}", ""]
    extra += ['[node name="Enemies" type="Node3D" parent="."]', ""]
    for name, rid, x, z, yaw in ENEMIES:
        extra += [f'[node name="{name}" parent="Enemies" instance=ExtResource("{rid}")]',
                  f"position = {vec(x, floor_at(x, z), z)}", f"rotation = {vec(0, yaw, 0)}", ""]
    d.subs.append(['[sub_resource type="BoxShape3D" id="Shape_voorkamer"]', "size = Vector3(20, 6, 16)"])
    world = {"root": "KerkDungeon", "location_name": "De Kerk van Amber", "location_id": "kerk_dungeon",
             "ambient": (0.4, 0.34, 0.3), "nav_id": "NavigationMesh_kerk", "nav_aabb": (-42, -17, -262, 84, 31, 264),
             "cleared_flag": "boss_amber",
             "residents": ([(0, -6), (-3, -24), (3, -34), (12, -196)],
                           ["Amber is weg! Feest in de kerk!", "Hoor je dat orgel? Eindelijk weer muziek.", "Klaas heeft ons gered. Nou ja, jij ook."]),
             "exit": (-0.75, -2, -4, "KerkExit", (0.5, 0.28, 0.1))}
    d.write(OUT, world, ext, extra)
    print("wrote", OUT, "with", len(ENEMIES), "enemies")


if __name__ == "__main__":
    main()
