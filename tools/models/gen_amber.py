"""Builds scenes/bosses/AmberModel.tscn: Amber de Draak, about 19 m long.

Run from the project root: python3 tools/models/gen_amber.py

Low poly in amber and orange: a deep chest and lighter hips with belly
plates and a row of spines, a neck in three parts with a throat that glows
before her fire breath, a horned head with brow ridges, slanted glowing
eyes, cheek spikes, teeth and a jaw that opens, a tail in four parts with a
spade, four legs with knees and claws, and bat wings: an arm, a forearm and
four fingers with a skin (MembraneMesh) that folds and flaps with the bones.
The joints are moved by amber_model.gd. Probe* markers tell amber.gd where
her body is, so she keeps clear of the pillars. She faces -Z.
"""
import sys
import pathlib

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from model_builder import Model, add, sub  # noqa: E402

OUT = "scenes/bosses/AmberModel.tscn"

SCALE = (0.93, 0.53, 0.13)
SCALE2 = (0.74, 0.34, 0.08)
DARK = (0.36, 0.15, 0.06)
BELLY = (0.96, 0.8, 0.47)
HORN = (0.88, 0.82, 0.68)
HORN_TIP = (0.25, 0.17, 0.12)
WING = (0.62, 0.2, 0.07)
EYE = (1.0, 0.86, 0.22)
PUPIL = (0.08, 0.03, 0.02)
THROAT = (1.0, 0.5, 0.1)
TEETH = (0.97, 0.94, 0.83)
TONGUE = (0.55, 0.1, 0.12)

m = Model("AmberModel", script="res://scenes/bosses/amber_model.gd")


def spines(parent, name, points, thickness, color=DARK):
    """A row of back spines: (z, base y, height, length) each."""
    for n, (z, y, h, l) in enumerate(points):
        m.prism(parent, f"{name}{n}", (0, y + h / 2, z), (l, h, thickness), color, rot=(0, 1.5708, 0))


# --- Body: chest in front, hips behind, belly plates and spines.
body = m.joint(".", "Body", (0, 3.0, 0))
m.box(body, "Chest", (0, 0.2, -1.3), (3.3, 2.8, 3.2), SCALE)
m.box(body, "ChestFront", (0, 0.05, -3.05), (2.7, 2.3, 0.9), SCALE)
m.box(body, "Hips", (0, 0.0, 1.5), (2.9, 2.4, 3.0), SCALE)
m.box(body, "Rump", (0, 0.0, 3.1), (2.2, 1.9, 0.6), SCALE)
for s in (-1, 1):
    tag = "L" if s < 0 else "R"
    m.box(body, f"Shoulder{tag}", (s * 1.5, 0.9, -1.7), (1.0, 1.3, 1.9), SCALE2, rot=(0, 0, s * 0.35))
    m.box(body, f"Haunch{tag}", (s * 1.45, 0.15, 1.75), (1.0, 1.7, 2.1), SCALE2)
    m.box(body, f"Flank{tag}", (s * 1.67, -0.3, -0.2), (0.06, 1.2, 4.6), BELLY)
for n in range(6):
    z = -2.9 + n * 1.15
    m.box(body, f"BellyPlate{n}", (0, -1.22, z), (2.3 - abs(z) * 0.1, 0.3, 0.98), BELLY)
spines(body, "Spine", [(-2.8, 1.5, 0.75, 0.95), (-1.8, 1.6, 0.95, 0.95), (-0.8, 1.6, 1.0, 0.95), (0.2, 1.45, 0.9, 0.95),
                       (1.2, 1.2, 0.8, 0.95), (2.2, 1.2, 0.7, 0.9), (3.0, 0.95, 0.55, 0.7)], 0.24)
m.marker(body, "ProbeChest", (0, 0, -2.6))
m.marker(body, "ProbeHips", (0, 0, 2.2))

# --- Neck: three parts, throat plates and a throat that glows.
neck = m.joint(body, "Neck", (0, 0.9, -3.3), rot=(0.5, 0, 0))
for n, (w, z) in enumerate(((1.75, -0.6), (1.5, -1.85), (1.3, -3.05))):
    m.box(neck, f"NeckPart{n}", (0, 0, z), (w, w, 1.45), SCALE)
    m.box(neck, f"ThroatPlate{n}", (0, -w / 2 - 0.05, z), (w * 0.7, 0.14, 1.2), BELLY)
spines(neck, "NeckSpine", [(-0.6, 0.85, 0.6, 0.8), (-1.85, 0.72, 0.55, 0.8), (-3.05, 0.62, 0.45, 0.8)], 0.2)
m.box(neck, "ThroatGlow", (0, -0.86, -1.85), (0.7, 0.1, 3.6), THROAT, glow=3.0, hidden=True)
m.marker(neck, "ProbeNeck", (0, 0, -2.0))

# --- Head: skull, cheeks, snout, brows, eyes, horns, teeth and a jaw.
head = m.joint(neck, "Head", (0, 0.1, -3.75))
m.box(head, "Skull", (0, 0.25, -0.65), (1.9, 1.5, 1.9), SCALE)
m.box(head, "Cheeks", (0, -0.1, -0.45), (2.25, 0.9, 1.1), SCALE2)
m.box(head, "Snout", (0, 0.05, -2.3), (1.35, 0.85, 1.9), SCALE)
m.box(head, "SnoutRidge", (0, 0.55, -2.05), (0.85, 0.3, 1.9), SCALE2)
m.box(head, "NoseTip", (0, 0.1, -3.35), (1.1, 0.6, 0.35), SCALE2)
for s in (-1, 1):
    tag = "L" if s < 0 else "R"
    m.box(head, f"Nostril{tag}", (s * 0.3, 0.3, -3.53), (0.2, 0.14, 0.06), PUPIL)
    m.box(head, f"Brow{tag}", (s * 0.62, 0.92, -1.3), (0.75, 0.32, 1.0), DARK, rot=(0.1, s * -0.2, s * 0.35))
    m.box(head, f"Eye{tag}", (s * 0.7, 0.58, -1.55), (0.46, 0.17, 0.12), EYE, rot=(0, s * -0.35, s * 0.3), glow=3.0)
    m.box(head, f"Pupil{tag}", (s * 0.73, 0.58, -1.6), (0.06, 0.15, 0.06), PUPIL, rot=(0, s * -0.35, 0))
    # Big horns that curve back, two smaller ones behind the cheeks.
    m.cone(head, f"Horn{tag}", (s * 0.55, 0.9, -0.3), (s * 0.85, 1.75, 0.65), 0.3, HORN, top=0.19)
    m.cone(head, f"HornTip{tag}", (s * 0.85, 1.75, 0.65), (s * 1.05, 1.95, 1.85), 0.19, HORN_TIP)
    m.cone(head, f"CheekHorn{tag}", (s * 1.0, 0.25, -0.25), (s * 1.65, 0.4, 0.75), 0.17, HORN)
    m.cone(head, f"JawHorn{tag}", (s * 0.95, -0.25, -0.1), (s * 1.45, -0.55, 0.75), 0.13, HORN)
    for n in range(4):
        z = -1.65 - n * 0.48
        m.prism(head, f"Fang{tag}{n}", (s * 0.56, -0.48, z), (0.13, 0.3 if n == 0 else 0.2, 0.13), TEETH, rot=(3.1416, 0, 0))
for n, (z, h) in enumerate(((0.1, 0.55), (0.55, 0.45))):
    m.prism(head, f"Crest{n}", (0, 0.95 + h / 2, z), (0.7, h, 0.18), DARK, rot=(0, 1.5708, 0))
m.box(head, "MouthGlow", (0, -0.3, -2.0), (1.0, 0.3, 1.9), THROAT, glow=3.0, hidden=True)
m.marker(head, "Mouth", (0, -0.25, -3.4))
m.marker(head, "ProbeHead", (0, 0.1, -1.7))
jaw = m.joint(head, "Jaw", (0, -0.45, -0.7))
m.box(jaw, "JawMesh", (0, -0.12, -1.3), (1.2, 0.38, 2.6), SCALE2)
m.box(jaw, "JawPlate", (0, -0.33, -1.3), (0.9, 0.08, 2.3), BELLY)
m.box(jaw, "Tongue", (0, 0.1, -1.4), (0.5, 0.1, 1.5), TONGUE)
for s in (-1, 1):
    for n in range(4):
        m.prism(jaw, f"Tooth{'L' if s < 0 else 'R'}{n}", (s * 0.48, 0.17, -0.9 - n * 0.48), (0.12, 0.2, 0.12), TEETH)

# --- Tail: four parts with plates and spines, and a spade at the end.
parent = body
tail_parts = [(2.3, 1.5), (2.2, 1.15), (2.1, 0.85), (2.0, 0.55)]
for n, (l, w) in enumerate(tail_parts):
    name = "Tail" if n == 0 else f"Tail{n + 1}"
    parent = m.joint(parent, name, (0, 0.15, 3.2) if n == 0 else (0, 0, tail_parts[n - 1][0]))
    m.box(parent, f"{name}Mesh", (0, 0, l / 2), (w, w * 0.9, l + 0.1), SCALE)
    m.box(parent, f"{name}Plate", (0, -w * 0.45 - 0.04, l / 2), (w * 0.65, 0.1, l * 0.85), BELLY)
    m.prism(parent, f"{name}Spine", (0, w * 0.45 + 0.22, l / 2), (l * 0.6, 0.45 - n * 0.06, 0.16), DARK, rot=(0, 1.5708, 0))
    if n == 1:
        m.marker(parent, "ProbeTail", (0, 0, l / 2))
end = tail_parts[-1][0]
m.box(parent, "Spade", (0, 0, end + 0.45), (0.95, 0.12, 0.95), SCALE2, rot=(0, 0.7854, 0))
m.prism(parent, "SpadeFin", (0, 0.3, end + 0.4), (0.9, 0.5, 0.1), DARK, rot=(0, 1.5708, 0))
m.marker(parent, "TailTip", (0, 0, end + 0.8))

# --- Legs: thigh, knee, shin, foot and claws.
for name, x, y, z, hind in (("LegFL", -1.45, -0.6, -2.4, False), ("LegFR", 1.45, -0.6, -2.4, False),
                            ("LegBL", -1.5, -0.5, 1.8, True), ("LegBR", 1.5, -0.5, 1.8, True)):
    leg = m.joint(body, name, (x, y, z))
    if hind:
        m.box(leg, "Thigh", (0, -0.45, 0.1), (1.3, 1.6, 1.8), SCALE)
        knee = m.joint(leg, "Knee", (0, -1.2, 0.3))
        m.box(knee, "Shin", (0, -0.55, 0.05), (0.8, 1.1, 0.85), SCALE2)
        foot_z, foot_y = -0.35, -1.15
    else:
        m.box(leg, "Thigh", (0, -0.55, 0), (1.0, 1.35, 1.1), SCALE)
        knee = m.joint(leg, "Knee", (0, -1.2, 0))
        m.box(knee, "Shin", (0, -0.5, 0.05), (0.72, 1.05, 0.78), SCALE2)
        foot_z, foot_y = -0.3, -1.05
    m.box(knee, "Foot", (0, foot_y, foot_z), (1.1, 0.3, 1.35), DARK)
    for n, cx in enumerate((-0.3, 0, 0.3)):
        m.prism(knee, f"Claw{n}", (cx, foot_y - 0.02, foot_z - 0.78), (0.16, 0.36, 0.18), HORN, rot=(-1.5708, 0, 0))

# --- Wings: arm, forearm and four fingers, with a skin between them.
for s in (-1, 1):
    tag = "L" if s < 0 else "R"
    root = (s * 1.5, 1.25, -1.6)
    wing = m.joint(body, f"Wing{tag}", root)
    elbow = (s * 2.3, 0.35, 0.25)
    m.bone(wing, "UpperArm", (0, 0, 0), elbow, 0.42, 0.36, SCALE2)
    m.marker(wing, "Root", (0, 0, 0))
    fore = m.joint(wing, "Fore", elbow)
    wrist = (s * 2.4, 0.15, 0.4)
    m.bone(fore, "Forearm", (0, 0, 0), wrist, 0.32, 0.3, SCALE2)
    m.marker(fore, "Elbow", (0, 0, 0))
    hand = m.joint(fore, "Hand", wrist)
    m.marker(hand, "Wrist", (0, 0, 0))
    m.cone(hand, "Thumb", (0, 0, 0), (s * 0.25, 0.45, -0.55), 0.13, HORN)
    tips = [(s * 3.2, 0, 0.5), (s * 2.6, 0, 2.2), (s * 1.6, 0, 3.1), (s * 0.5, 0, 3.3)]
    # Each finger is a joint, so a folded wing can close its fan.
    for n, tip in enumerate(tips):
        finger = m.joint(hand, f"Finger{n + 1}")
        m.bone(finger, "Bone", (0, 0, 0), tip, 0.17, 0.15, SCALE2)
        m.marker(finger, "Tip", tip)
        m.cone(finger, "Claw", tip, add(tip, (s * 0.25 if n == 0 else 0, 0, 0.3 if n else 0)), 0.09, HORN_TIP)
        if n < 3:
            m.marker(finger, "Scallop", tuple((a + b) / 2 * 0.8 for a, b in zip(tip, tips[n + 1])))
    m.marker(body, f"Flank{tag}Marker", (s * 1.45, 0.9, 2.3))
    # Rest positions in the body frame, to give every triangle the same side up.
    p_root = root
    p_elbow = add(root, elbow)
    p_wrist = add(p_elbow, wrist)
    rest = [p_root, p_elbow, p_wrist]
    for n in range(4):
        rest.append(add(p_wrist, tips[n]))
        if n < 3:
            rest.append(add(p_wrist, tuple((a + b) / 2 * 0.8 for a, b in zip(tips[n], tips[n + 1]))))
    rest.append((s * 1.45, 0.9, 2.3))
    # Marker order: Root, Elbow, Wrist, Tip1, Scallop1, Tip2, Scallop2, Tip3, Scallop3, Tip4, Flank.
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
        up = u[2] * v[0] - u[0] * v[2]
        fixed.append((a, b, c) if up > 0 else (a, c, b))
    m.membrane(".", f"WingSkin{tag}", markers, fixed, WING)

m.write(OUT)
