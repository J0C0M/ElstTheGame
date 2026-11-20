"""Builds scenes/enemies/models/CultistModel.tscn: an Amber cultist.

Run from the project root: python3 tools/models/gen_cultist.py

An amber-orange robe from the waist down, a pointed amber hood that hides
the face in shadow except for two glowing eyes and a golden half-mask, a
belt with a golden buckle and a gold chain with a glowing amber pendant. They come from Zevenaar, where Amber began: ZEVENAAR in gold on
the cape. They are drillers too: a black puffer jacket with puffy bands, a
high collar, an orange zip and orange stripes on the sleeves, white
sneakers, and a red fire vape in the hand, for they vape fire. Same joints
as PlayerModel.tscn, so HumanoidModel animates it.
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
VAPE_RED = (0.78, 0.06, 0.05)
FIRE = (1.0, 0.42, 0.06)

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
# A black puffer jacket: puffy bands all round, a high collar and an orange
# zip, like the drillers of Amber's army.
m.box(torso, "Puffer", (0, 0.3, 0), (0.64, 0.68, 0.44), PUFFER)
for n, y in enumerate((0.06, 0.22, 0.38, 0.54)):
    m.box(torso, f"PufferBand{n}", (0, y, 0), (0.68, 0.075, 0.48), PUFFER_RIDGE)
m.box(torso, "Zip", (0, 0.3, -0.245), (0.03, 0.66, 0.01), ZIP)
m.box(torso, "PufferCollar", (0, 0.68, -0.01), (0.42, 0.14, 0.36), PUFFER)
m.box(torso, "CollarBand", (0, 0.68, -0.01), (0.44, 0.04, 0.38), PUFFER_RIDGE)
# Over it the marks of Amber: a cape from Zevenaar on the back, a golden
# chain with a glowing amber pendant, and the belt of the robe.
m.box(torso, "Cape", (0, 0.34, 0.27), (0.6, 0.5, 0.05), TRIM)
m.box(torso, "CapeHem", (0, 0.1, 0.27), (0.62, 0.04, 0.06), ROBE)
m.prism(torso, "Emblem", (0, 0.5, 0.3), (0.16, 0.14, 0.02), CRYSTAL, glow=1.0)
m.label(torso, "Zevenaar", (0, 0.32, 0.302), "ZEVENAAR", GOLD, size=48, pixel=0.0024)
m.box(torso, "Belt", (0, 0.0, 0), (0.66, 0.08, 0.46), TRIM)
m.box(torso, "Buckle", (0, 0.0, -0.235), (0.12, 0.1, 0.02), GOLD, metal=True)
m.box(torso, "Chain", (0, 0.5, -0.25), (0.24, 0.03, 0.02), GOLD, metal=True)
m.box(torso, "PendantFrame", (0, 0.4, -0.255), (0.16, 0.19, 0.02), GOLD, metal=True)
m.box(torso, "Pendant", (0, 0.4, -0.265), (0.12, 0.15, 0.03), CRYSTAL, glow=2.5)

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
    # Puffer sleeves with an orange stripe, amber cuffs from the robe.
    m.box(arm, "Sleeve", (0, -0.24, 0), (0.22, 0.48, 0.22), PUFFER)
    for n, y in enumerate((-0.06, -0.24, -0.42)):
        m.box(arm, f"SleeveBand{n}", (0, y, 0), (0.245, 0.06, 0.245), PUFFER_RIDGE)
    m.box(arm, "Stripe", (s * 0.112, -0.24, 0), (0.01, 0.44, 0.05), ZIP)
    m.box(arm, "Cuff", (0, -0.5, 0), (0.24, 0.07, 0.24), ROBE)
    m.box(arm, "Glove", (0, -0.58, 0), (0.12, 0.12, 0.12), GLOVE)
    if s > 0:
        hand = m.joint(arm, "Hand", (0, -0.56, 0))
        # A red fire vape: a mod with a glowing screen, a tank of fire and
        # a black drip tip.
        m.box(hand, "VapeMod", (0, -0.07, -0.1), (0.095, 0.17, 0.05), VAPE_RED, metal=True)
        m.box(hand, "VapeScreen", (0, -0.04, -0.127), (0.06, 0.04, 0.005), FIRE, glow=3.0)
        m.box(hand, "VapeButton", (0.05, -0.02, -0.1), (0.008, 0.04, 0.025), GOLD, metal=True)
        m.box(hand, "VapeTank", (0, 0.05, -0.1), (0.05, 0.08, 0.05), FIRE, glow=3.5)
        m.box(hand, "VapeTip", (0, 0.105, -0.1), (0.03, 0.035, 0.03), SHADOW)

m.write(OUT)
