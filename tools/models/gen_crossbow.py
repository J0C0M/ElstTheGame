"""Builds the crossbow of Klaas and its bolt:
- scenes/player/BoltModel.tscn: a bolt of about 0.55 m with an iron
  broadhead, a ferrule, a wooden shaft and three vanes (one red);
- scenes/player/CrossbowModel.tscn: a wooden stock with a butt, a grip, a
  trigger and iron bands, a groove with the nut, a steel prod in two limbs,
  a stirrup at the front, a rear sight, a string (moved by crossbow_model.gd)
  and a loaded bolt in the groove.

Run from the project root: python3 tools/models/gen_crossbow.py

Both face -Z. The crossbow's origin is where the right hand holds the grip.
"""
import sys
import pathlib

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from model_builder import Model  # noqa: E402

WOOD = (0.5, 0.32, 0.17)
WOOD_DARK = (0.33, 0.2, 0.1)
IRON = (0.42, 0.42, 0.46)
STEEL = (0.72, 0.74, 0.78)
GOLD = (0.95, 0.76, 0.25)
SHAFT = (0.78, 0.62, 0.4)
RED = (0.8, 0.12, 0.1)
WHITE = (0.94, 0.92, 0.86)
STRING = (0.9, 0.86, 0.72)

# --- The bolt.
b = Model("BoltModel")
b.box(".", "Shaft", (0, 0, 0.03), (0.022, 0.022, 0.5), SHAFT)
b.box(".", "Ferrule", (0, 0, -0.24), (0.03, 0.03, 0.05), IRON, metal=True)
b.prism(".", "Head", (0, 0, -0.31), (0.07, 0.12, 0.012), STEEL, rot=(-1.5708, 0, 0))
b.box(".", "Nock", (0, 0, 0.285), (0.026, 0.026, 0.02), WOOD_DARK)
for n, (angle, color) in enumerate(((0.0, RED), (2.094, WHITE), (-2.094, WHITE))):
    vane = b.joint(".", f"Vane{n}", (0, 0, 0.2), rot=(0, 0, angle))
    b.prism(vane, "Fin", (0, 0.024, 0), (0.1, 0.03, 0.003), color, rot=(0, 1.5708, 0))
b.write("scenes/player/BoltModel.tscn")

# --- The crossbow.
m = Model("CrossbowModel", script="res://scenes/player/crossbow_model.gd",
          extra_ext=[("PackedScene", "res://scenes/player/BoltModel.tscn", "3_bolt")])
# Stock: butt, body, grip, trigger and iron bands.
m.box(".", "Butt", (0, -0.03, 0.27), (0.075, 0.13, 0.2), WOOD_DARK)
m.box(".", "ButtPlate", (0, -0.03, 0.375), (0.08, 0.14, 0.02), IRON, metal=True)
m.box(".", "Stock", (0, 0.0, -0.06), (0.065, 0.075, 0.56), WOOD)
m.box(".", "Cheek", (0, 0.035, 0.17), (0.07, 0.03, 0.14), WOOD_DARK)
m.box(".", "Grip", (0, -0.08, 0.07), (0.05, 0.13, 0.06), WOOD_DARK, rot=(0.35, 0, 0))
m.box(".", "TriggerGuard", (0, -0.06, -0.02), (0.012, 0.012, 0.09), IRON, metal=True)
m.box(".", "Trigger", (0, -0.055, -0.005), (0.012, 0.05, 0.015), IRON, metal=True, rot=(0.3, 0, 0))
for n, z in enumerate((-0.27, -0.1, 0.12)):
    m.box(".", f"Band{n}", (0, 0.0, z), (0.072, 0.082, 0.025), IRON, metal=True)
# Groove on top, the nut that holds the string, and a rear sight.
m.box(".", "Groove", (0, 0.04, -0.12), (0.028, 0.008, 0.48), WOOD_DARK)
m.box(".", "Nut", (0, 0.05, 0.03), (0.05, 0.03, 0.035), STEEL, metal=True)
m.box(".", "Sight", (0, 0.085, 0.2), (0.012, 0.05, 0.012), IRON, metal=True)
m.box(".", "SightRing", (0, 0.115, 0.2), (0.03, 0.03, 0.008), GOLD, metal=True)
# Front: the prod mount, the prod in two limbs and a stirrup.
m.box(".", "ProdMount", (0, 0.025, -0.34), (0.09, 0.07, 0.07), IRON, metal=True)
for s in (-1, 1):
    tag = "L" if s < 0 else "R"
    limb = m.joint(".", f"Limb{tag}", (s * 0.04, 0.03, -0.35))
    m.bone(limb, "Inner", (0, 0, 0), (s * 0.18, 0, 0.02), 0.04, 0.035, STEEL)
    m.bone(limb, "Outer", (s * 0.18, 0, 0.02), (s * 0.33, 0, 0.07), 0.03, 0.028, STEEL)
    m.box(limb, "TipCap", (s * 0.335, 0, 0.072), (0.03, 0.04, 0.03), GOLD, metal=True)
    m.marker(limb, "Tip", (s * 0.335, 0, 0.075))
    m.bone(".", f"Stirrup{tag}", (s * 0.03, -0.01, -0.37), (s * 0.06, -0.01, -0.47), 0.014, 0.014, IRON)
m.box(".", "StirrupFront", (0, -0.01, -0.47), (0.135, 0.014, 0.014), IRON, metal=True)
# The string: two halves that crossbow_model.gd stretches between the limb
# tips and the point where the string sits (back at the nut when spanned).
m.box(".", "StringL", (0, 0, 0), (0.008, 0.008, 1.0), STRING)
m.box(".", "StringR", (0, 0, 0), (0.008, 0.008, 1.0), STRING)
m.marker(".", "Drawn", (0, 0.05, 0.03))
m.marker(".", "Released", (0, 0.05, -0.29))
m.marker(".", "Muzzle", (0, 0.06, -0.5))
m.nodes.append(['[node name="LoadedBolt" parent="." instance=ExtResource("3_bolt")]', "position = Vector3(0, 0.056, -0.265)"])
m.write("scenes/player/CrossbowModel.tscn")
