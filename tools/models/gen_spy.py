"""Builds scenes/npcs/SpyModel.tscn: the suspicious figure in a cloak who
watches the hero at the end of the game and reports to his boss.

Run from the project root: python3 tools/models/gen_spy.py

A long dark cloak to the ankles, a deep hood with only darkness inside (his
face is never seen), dark gloves and boots, and an old phone in his right
hand. Same joints as PlayerModel.tscn, so HumanoidModel animates it (the
"drink" action raises the phone to his ear). A placeholder: Prototype 2
remakes the end scene with its own characters.
"""
import sys
import pathlib

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from model_builder import Model  # noqa: E402

CLOAK = (0.16, 0.17, 0.16)
CLOAK_DARK = (0.09, 0.1, 0.09)
LINING = (0.32, 0.08, 0.1)
VOID = (0.01, 0.01, 0.01)
GLOVE = (0.06, 0.06, 0.06)
BOOT = (0.12, 0.09, 0.07)
PHONE = (0.2, 0.2, 0.22)
SCREEN = (0.45, 0.85, 0.6)

m = Model("SpyModel", script="res://scripts/characters/humanoid_model.gd")
body = m.joint(".", "Body", (0, 0.95, 0))
hips = m.joint(body, "Hips")
for s in (-1, 1):
    leg = m.joint(hips, f"Leg{'L' if s < 0 else 'R'}", (s * 0.12, 0, 0))
    m.box(leg, "Leg", (0, -0.45, 0), (0.17, 0.8, 0.18), CLOAK_DARK)
    m.box(leg, "Boot", (0, -0.87, -0.04), (0.2, 0.12, 0.3), BOOT)
# The cloak hangs from the hips down to the ankles, open a little at the front.
m.box(hips, "CloakSkirt", (0, -0.42, 0.02), (0.66, 0.84, 0.48), CLOAK)
m.box(hips, "CloakHem", (0, -0.86, 0.02), (0.7, 0.05, 0.52), CLOAK_DARK)
m.box(hips, "CloakSplit", (0, -0.5, -0.245), (0.06, 0.7, 0.01), LINING)
torso = m.joint(hips, "Torso", (0, 0.02, 0))
m.box(torso, "Cloak", (0, 0.3, 0), (0.62, 0.66, 0.42), CLOAK)
m.box(torso, "Shoulders", (0, 0.58, 0.01), (0.76, 0.14, 0.46), CLOAK_DARK)
m.box(torso, "Clasp", (0, 0.6, -0.235), (0.08, 0.06, 0.02), (0.5, 0.48, 0.4), metal=True)
m.box(torso, "Lining", (0, 0.3, -0.215), (0.08, 0.6, 0.01), LINING)
head = m.joint(torso, "Head", (0, 0.62, 0))
# A deep hood: nothing but darkness inside.
m.box(head, "Darkness", (0, 0.15, -0.02), (0.26, 0.3, 0.26), VOID)
m.box(head, "HoodBack", (0, 0.2, 0.06), (0.42, 0.46, 0.32), CLOAK)
m.box(head, "HoodL", (-0.2, 0.17, -0.11), (0.05, 0.44, 0.18), CLOAK)
m.box(head, "HoodR", (0.2, 0.17, -0.11), (0.05, 0.44, 0.18), CLOAK)
m.box(head, "HoodTop", (0, 0.41, -0.09), (0.42, 0.07, 0.24), CLOAK)
m.box(head, "HoodBrim", (0, 0.36, -0.2), (0.38, 0.06, 0.08), CLOAK_DARK)
for s in (-1, 1):
    tag = "L" if s < 0 else "R"
    arm = m.joint(torso, f"Arm{tag}", (s * 0.365, 0.56, 0))
    m.box(arm, "Sleeve", (0, -0.24, 0), (0.21, 0.5, 0.21), CLOAK)
    m.box(arm, "Cuff", (0, -0.47, 0), (0.25, 0.08, 0.25), CLOAK_DARK)
    m.box(arm, "Glove", (0, -0.57, 0), (0.12, 0.12, 0.12), GLOVE)
    if s > 0:
        hand = m.joint(arm, "Hand", (0, -0.56, 0))
        m.box(hand, "Phone", (0, -0.04, -0.07), (0.06, 0.12, 0.025), PHONE)
        m.box(hand, "Screen", (0, -0.02, -0.084), (0.045, 0.05, 0.004), SCREEN, glow=2.0)
m.write("scenes/npcs/SpyModel.tscn")
