"""Builds scenes/enemies/models/DragonlingModel.tscn: a little dragon of Amber
with a driller on its back.

Run from the project root: python3 tools/models/gen_dragonling.py

A dragon of about 3.5 m from snout to tail, in Amber's colours: a chest and
hips with spines, a short neck, a horned head with glowing eyes and a jaw,
a tail in three parts with a spade, four legs tucked up, and bat wings with
the same joints as Amber's (DragonWingRig moves them). On its back sits a
saddle with a low driller (LowDrillerModel, seated) holding the reins.
dragonling.gd animates it. It faces -Z.
"""
import sys
import pathlib

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from model_builder import Model, add, sub  # noqa: E402

OUT = "scenes/enemies/models/DragonlingModel.tscn"

SCALE = (0.92, 0.5, 0.12)
SCALE2 = (0.72, 0.32, 0.08)
DARK = (0.36, 0.15, 0.06)
BELLY = (0.95, 0.78, 0.45)
HORN = (0.88, 0.82, 0.68)
WING = (0.6, 0.19, 0.07)
EYE = (1.0, 0.86, 0.22)
TEETH = (0.97, 0.94, 0.83)
LEATHER = (0.3, 0.17, 0.08)
STRAP = (0.18, 0.1, 0.05)
GOLD = (0.95, 0.76, 0.25)

m = Model("DragonlingModel", extra_ext=[("PackedScene", "res://scenes/enemies/models/LowDrillerModel.tscn", "3_rider")])

body = m.joint(".", "Body")
m.box(body, "Chest", (0, 0, -0.3), (0.9, 0.8, 1.0), SCALE)
m.box(body, "Hips", (0, -0.02, 0.55), (0.8, 0.7, 0.9), SCALE)
for n, z in enumerate((-0.55, -0.15, 0.25, 0.65)):
    m.box(body, f"BellyPlate{n}", (0, -0.4, z), (0.6, 0.08, 0.32), BELLY)
for n, (z, h) in enumerate(((-0.75, 0.22), (0.95, 0.2))):
    m.prism(body, f"Spine{n}", (0, 0.4 + h / 2, z), (0.28, h, 0.08), DARK, rot=(0, 1.5708, 0))

# Saddle, straps and a golden pommel.
m.box(body, "Saddle", (0, 0.45, 0.12), (0.62, 0.12, 0.62), LEATHER)
m.box(body, "SaddleBack", (0, 0.56, 0.42), (0.5, 0.18, 0.08), LEATHER)
m.box(body, "Pommel", (0, 0.58, -0.17), (0.12, 0.16, 0.1), GOLD, metal=True)
m.box(body, "Girth", (0, 0, 0.12), (0.94, 0.84, 0.1), STRAP)
for s in (-1, 1):
    m.box(body, f"Stirrup{'L' if s < 0 else 'R'}", (s * 0.48, -0.05, 0.0), (0.04, 0.5, 0.04), STRAP)
nodes_rider = ['[node name="Rider" parent="Body" instance=ExtResource("3_rider")]', "position = Vector3(0, 0.08, 0.14)",
               "scale = Vector3(0.85, 0.85, 0.85)", "seated = true", "straddle = true"]
m.nodes.append(nodes_rider)

neck = m.joint(body, "Neck", (0, 0.2, -0.75), rot=(0.55, 0, 0))
m.box(neck, "NeckPart0", (0, 0, -0.25), (0.46, 0.46, 0.5), SCALE)
m.box(neck, "NeckPart1", (0, 0, -0.7), (0.38, 0.38, 0.5), SCALE)
m.box(neck, "Throat", (0, -0.21, -0.48), (0.28, 0.06, 0.8), BELLY)
m.box(neck, "Rein", (0, 0.32, -0.15), (0.5, 0.03, 0.03), STRAP)
head = m.joint(neck, "Head", (0, 0.05, -1.0), rot=(-0.4, 0, 0))
m.box(head, "Skull", (0, 0.08, -0.15), (0.5, 0.42, 0.5), SCALE)
m.box(head, "Snout", (0, 0.0, -0.6), (0.36, 0.26, 0.55), SCALE)
m.box(head, "SnoutRidge", (0, 0.15, -0.55), (0.24, 0.08, 0.5), SCALE2)
for s in (-1, 1):
    tag = "L" if s < 0 else "R"
    m.box(head, f"Eye{tag}", (s * 0.19, 0.16, -0.38), (0.12, 0.05, 0.04), EYE, rot=(0, s * -0.35, s * 0.3), glow=3.0)
    m.box(head, f"Brow{tag}", (s * 0.17, 0.27, -0.33), (0.2, 0.08, 0.24), DARK, rot=(0, 0, s * 0.35))
    m.cone(head, f"Horn{tag}", (s * 0.15, 0.25, -0.05), (s * 0.28, 0.5, 0.4), 0.08, HORN)
    m.cone(head, f"CheekHorn{tag}", (s * 0.25, 0.02, -0.05), (s * 0.45, 0.06, 0.25), 0.05, HORN)
    for n in range(2):
        m.prism(head, f"Fang{tag}{n}", (s * 0.15, -0.14, -0.55 - n * 0.2), (0.05, 0.1, 0.05), TEETH, rot=(3.1416, 0, 0))
m.marker(head, "Mouth", (0, -0.05, -0.92))
jaw = m.joint(head, "Jaw", (0, -0.12, -0.15))
m.box(jaw, "JawMesh", (0, -0.04, -0.35), (0.32, 0.1, 0.65), SCALE2)

parent = body
for n, (l, w) in enumerate(((0.7, 0.4), (0.65, 0.3), (0.6, 0.2))):
    name = "Tail" if n == 0 else f"Tail{n + 1}"
    parent = m.joint(parent, name, (0, 0.05, 1.0) if n == 0 else (0, 0, (0.7, 0.65)[n - 1]))
    m.box(parent, f"{name}Mesh", (0, 0, l / 2), (w, w * 0.9, l + 0.04), SCALE)
    m.prism(parent, f"{name}Spine", (0, w * 0.45 + 0.07, l / 2), (l * 0.5, 0.14, 0.05), DARK, rot=(0, 1.5708, 0))
m.box(parent, "Spade", (0, 0, 0.75), (0.3, 0.04, 0.3), SCALE2, rot=(0, 0.7854, 0))

for name, x, y, z, hind in (("LegFL", -0.3, -0.3, -0.55, False), ("LegFR", 0.3, -0.3, -0.55, False),
                            ("LegBL", -0.32, -0.25, 0.65, True), ("LegBR", 0.32, -0.25, 0.65, True)):
    leg = m.joint(body, name, (x, y, z))
    w = 0.26 if hind else 0.2
    m.box(leg, "Thigh", (0, -0.2, 0), (w, 0.42, w + 0.04), SCALE)
    m.box(leg, "Foot", (0, -0.42, -0.08), (w + 0.04, 0.08, 0.26), DARK)
    for n, cx in enumerate((-0.07, 0.07)):
        m.prism(leg, f"Claw{n}", (cx, -0.43, -0.25), (0.05, 0.1, 0.05), HORN, rot=(-1.5708, 0, 0))

for s in (-1, 1):
    tag = "L" if s < 0 else "R"
    root = (s * 0.42, 0.3, -0.35)
    wing = m.joint(body, f"Wing{tag}", root)
    elbow = (s * 0.8, 0.1, 0.1)
    m.bone(wing, "UpperArm", (0, 0, 0), elbow, 0.12, 0.1, SCALE2)
    m.marker(wing, "Root", (0, 0, 0))
    fore = m.joint(wing, "Fore", elbow)
    wrist = (s * 0.9, 0.05, 0.15)
    m.bone(fore, "Forearm", (0, 0, 0), wrist, 0.09, 0.08, SCALE2)
    m.marker(fore, "Elbow", (0, 0, 0))
    hand = m.joint(fore, "Hand", wrist)
    m.marker(hand, "Wrist", (0, 0, 0))
    tips = [(s * 1.15, 0, 0.15), (s * 0.95, 0, 0.75), (s * 0.55, 0, 1.05), (s * 0.15, 0, 1.1)]
    for n, tip in enumerate(tips):
        finger = m.joint(hand, f"Finger{n + 1}")
        m.bone(finger, "Bone", (0, 0, 0), tip, 0.05, 0.05, SCALE2)
        m.marker(finger, "Tip", tip)
        if n < 3:
            m.marker(finger, "Scallop", tuple((a + b) / 2 * 0.8 for a, b in zip(tip, tips[n + 1])))
    m.marker(body, f"Flank{tag}Marker", (s * 0.4, 0.2, 0.8))
    rest = [root, add(root, elbow), add(add(root, elbow), wrist)]
    wrist_at = rest[2]
    for n in range(4):
        rest.append(add(wrist_at, tips[n]))
        if n < 3:
            rest.append(add(wrist_at, tuple((a + b) / 2 * 0.8 for a, b in zip(tips[n], tips[n + 1]))))
    rest.append((s * 0.4, 0.2, 0.8))
    markers = [f"../Body/Wing{tag}/Root", f"../Body/Wing{tag}/Fore/Elbow", f"../Body/Wing{tag}/Fore/Hand/Wrist"]
    for n in range(4):
        markers.append(f"../Body/Wing{tag}/Fore/Hand/Finger{n + 1}/Tip")
        if n < 3:
            markers.append(f"../Body/Wing{tag}/Fore/Hand/Finger{n + 1}/Scallop")
    markers.append(f"../Body/Flank{tag}Marker")
    tris = [(2, 3, 4), (2, 4, 5), (2, 5, 6), (2, 6, 7), (2, 7, 8), (2, 8, 9), (2, 9, 10), (1, 2, 10), (0, 1, 10)]
    fixed = []
    for a, b, c in tris:
        u, v = sub(rest[c], rest[a]), sub(rest[b], rest[a])
        fixed.append((a, b, c) if u[2] * v[0] - u[0] * v[2] > 0 else (a, c, b))
    m.membrane(".", f"WingSkin{tag}", markers, fixed, WING)

m.write(OUT)
