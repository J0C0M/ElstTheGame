"""Builds scenes/enemies/models/CultistModel.tscn: an Amber cultist.

Run from the project root: python3 tools/models/gen_cultist.py

A villager in a long amber-orange robe with a dark mantle, a pointed hood
that hides the face in shadow except for two glowing eyes and a golden
half-mask, wide sleeves, a belt with a golden buckle and a glowing amber
pendant. The staff ends in golden claws holding an amber crystal. They come
from Zevenaar: ZEVENAAR in gold on the back of the mantle. Under the robe
they are still a bit driller: a black puffer jacket shows at the open front,
the collar and the wrists, and they wear white sneakers. Same joints as
PlayerModel.tscn, so HumanoidModel animates it.
"""
import sys
import pathlib

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from model_builder import Model  # noqa: E402

OUT = "scenes/enemies/models/CultistModel.tscn"

ROBE = (0.88, 0.45, 0.1)
ROBE_DARK = (0.64, 0.28, 0.06)
TRIM = (0.3, 0.1, 0.05)
GOLD = (0.95, 0.76, 0.25)
CRYSTAL = (1.0, 0.62, 0.12)
SHADOW = (0.05, 0.03, 0.03)
GLOVE = (0.16, 0.08, 0.05)
WOOD = (0.3, 0.18, 0.09)
EYE = (1.0, 0.8, 0.2)
PUFFER = (0.1, 0.1, 0.11)
PUFFER_RIDGE = (0.17, 0.17, 0.18)
ZIP = (1.0, 0.55, 0.1)
SNEAKER = (0.93, 0.93, 0.9)

m = Model("CultistModel", script="res://scripts/characters/humanoid_model.gd")
body = m.joint(".", "Body", (0, 0.95, 0))
hips = m.joint(body, "Hips")
for s in (-1, 1):
    tag = "L" if s < 0 else "R"
    leg = m.joint(hips, f"Leg{tag}", (s * 0.12, 0, 0))
    m.box(leg, "Leg", (0, -0.45, 0), (0.17, 0.8, 0.18), ROBE_DARK)
    m.box(leg, "Sneaker", (0, -0.88, -0.04), (0.2, 0.1, 0.3), SNEAKER)
    m.box(leg, "Sole", (0, -0.935, -0.04), (0.21, 0.03, 0.31), PUFFER)
# The lower robe hangs from the hips, with a dark hem and a golden panel.
m.box(hips, "Skirt", (0, -0.36, 0.01), (0.6, 0.72, 0.44), ROBE)
m.box(hips, "SkirtFlare", (0, -0.66, 0.01), (0.68, 0.14, 0.5), ROBE)
m.box(hips, "Hem", (0, -0.74, 0.01), (0.7, 0.06, 0.52), TRIM)
m.box(hips, "Panel", (0, -0.36, -0.215), (0.2, 0.68, 0.02), GOLD)
m.box(hips, "PanelRune", (0, -0.3, -0.228), (0.08, 0.08, 0.01), TRIM, rot=(0, 0, 0.785))

torso = m.joint(hips, "Torso", (0, 0.02, 0))
m.box(torso, "Robe", (0, 0.3, 0), (0.6, 0.66, 0.4), ROBE)
m.box(torso, "Mantle", (0, 0.58, 0.02), (0.8, 0.16, 0.5), TRIM)
m.box(torso, "MantleBack", (0, 0.38, 0.24), (0.66, 0.42, 0.06), TRIM)
m.box(torso, "Collar", (0, 0.66, -0.06), (0.36, 0.1, 0.3), ROBE_DARK)
m.box(torso, "Belt", (0, 0.02, 0), (0.64, 0.08, 0.44), TRIM)
m.box(torso, "Buckle", (0, 0.02, -0.225), (0.12, 0.1, 0.02), GOLD, metal=True)
m.box(torso, "Chain", (0, 0.5, -0.226), (0.22, 0.03, 0.02), GOLD, metal=True)
m.box(torso, "Pendant", (0, 0.4, -0.24), (0.12, 0.15, 0.04), CRYSTAL, glow=2.5)
m.box(torso, "PendantFrame", (0, 0.4, -0.23), (0.16, 0.19, 0.02), GOLD, metal=True)
m.prism(torso, "Emblem", (0, 0.5, 0.275), (0.16, 0.14, 0.02), CRYSTAL, glow=1.0)
m.label(torso, "Zevenaar", (0, 0.3, 0.282), "ZEVENAAR", GOLD, size=48, pixel=0.0024)
# The puffer jacket under the robe: an open front with ridges and an orange
# zip, a puffy collar.
m.box(torso, "Puffer", (0, 0.24, -0.205), (0.2, 0.5, 0.02), PUFFER)
for n, y in enumerate((0.08, 0.22, 0.36)):
    m.box(torso, f"PufferRidge{n}", (0, y, -0.215), (0.21, 0.04, 0.02), PUFFER_RIDGE)
m.box(torso, "Zip", (0, 0.24, -0.222), (0.025, 0.48, 0.01), ZIP)
m.box(torso, "PufferCollar", (0, 0.7, -0.02), (0.32, 0.1, 0.28), PUFFER)

head = m.joint(torso, "Head", (0, 0.62, 0))
m.box(head, "Face", (0, 0.15, -0.02), (0.24, 0.28, 0.24), SHADOW)
m.box(head, "EyeL", (-0.06, 0.19, -0.145), (0.06, 0.03, 0.02), EYE, glow=4.0)
m.box(head, "EyeR", (0.06, 0.19, -0.145), (0.06, 0.03, 0.02), EYE, glow=4.0)
m.box(head, "Mask", (0, 0.08, -0.145), (0.22, 0.1, 0.02), GOLD, metal=True)
# A deep, pointed hood.
m.box(head, "HoodBack", (0, 0.2, 0.06), (0.4, 0.44, 0.3), ROBE)
m.box(head, "HoodL", (-0.19, 0.18, -0.09), (0.05, 0.42, 0.14), ROBE)
m.box(head, "HoodR", (0.19, 0.18, -0.09), (0.05, 0.42, 0.14), ROBE)
m.box(head, "HoodTop", (0, 0.4, -0.06), (0.4, 0.06, 0.18), ROBE)
m.prism(head, "HoodPeak", (0, 0.52, 0.06), (0.36, 0.22, 0.28), ROBE)
m.box(head, "HoodRim", (0, 0.39, -0.155), (0.42, 0.05, 0.03), TRIM)
m.box(head, "HoodRimL", (-0.205, 0.18, -0.155), (0.03, 0.42, 0.03), TRIM)
m.box(head, "HoodRimR", (0.205, 0.18, -0.155), (0.03, 0.42, 0.03), TRIM)

for s in (-1, 1):
    tag = "L" if s < 0 else "R"
    arm = m.joint(torso, f"Arm{tag}", (s * 0.365, 0.56, 0))
    m.box(arm, "Sleeve", (0, -0.17, 0), (0.2, 0.34, 0.2), ROBE)
    m.box(arm, "Cuff", (0, -0.43, 0), (0.28, 0.22, 0.28), ROBE)
    m.box(arm, "CuffTrim", (0, -0.535, 0), (0.3, 0.05, 0.3), TRIM)
    m.box(arm, "PufferCuff", (0, -0.555, 0), (0.17, 0.08, 0.17), PUFFER)
    m.box(arm, "Glove", (0, -0.6, 0), (0.12, 0.12, 0.12), GLOVE)
    if s > 0:
        hand = m.joint(arm, "Hand", (0, -0.56, 0))
        m.box(hand, "Staff", (0, -0.15, -0.05), (0.06, 1.7, 0.06), WOOD)
        m.box(hand, "Ring", (0, 0.62, -0.05), (0.14, 0.05, 0.14), GOLD, metal=True)
        m.prism(hand, "Crystal", (0, 0.86, -0.05), (0.16, 0.32, 0.16), CRYSTAL, glow=3.0)
        m.prism(hand, "CrystalBase", (0, 0.66, -0.05), (0.16, 0.12, 0.16), CRYSTAL, rot=(3.1416, 0, 0), glow=3.0)
        for n, (cx, cz) in enumerate(((0.1, 0), (-0.1, 0), (0, 0.1), (0, -0.1))):
            m.cone(hand, f"Claw{n}", (cx * 0.6, 0.64, -0.05 + cz * 0.6), (cx * 1.1, 0.95, -0.05 + cz * 1.1), 0.025, GOLD, sides=4)

m.write(OUT)
