"""Builds scenes/enemies/models/GrumpyOmaModel.tscn: Grumpy Oma as a beast.

Run from the project root: python3 tools/models/gen_grumpy_oma.py

A huge, hunched grandma built like a hulk: a wide chest and a hump of
muscle, bare arms down to her knees with veins, short thick legs in
stockings, a small angry head with red eyes, a grey perm with curlers, and
a purple leather handbag. The gold sash and the medal with a 1 show she is
the number 1 bingo winner. Same joints as PlayerModel.tscn; GrumpyOma.tscn
scales it up.
"""
import pathlib

OUT = pathlib.Path("scenes/enemies/models/GrumpyOmaModel.tscn")

SKIN = (0.88, 0.64, 0.54)
SKIN_DARK = (0.74, 0.5, 0.42)
CARDIGAN = (0.45, 0.6, 0.9)
CARDIGAN_DARK = (0.32, 0.44, 0.72)
SKIRT = (0.95, 0.7, 0.8)
STOCKING = (0.8, 0.68, 0.58)
SHOE = (0.1, 0.09, 0.1)
HAIR = (0.82, 0.82, 0.86)
CURLER = (1.0, 0.55, 0.75)
GOLD = (0.95, 0.78, 0.25)
BAG = (0.42, 0.12, 0.48)
VEIN = (0.55, 0.25, 0.3)
DARK = (0.08, 0.07, 0.08)
WHITE = (0.95, 0.94, 0.88)
EYE = (1.0, 0.15, 0.1)


def f(v):
    s = f"{v:.4f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def vec(*v):
    return "Vector3(" + ", ".join(f(c) for c in v) + ")"


subs = []
materials = {}
meshes = {}
nodes = []


def material(c, glow=False):
    key = (c, glow)
    if key not in materials:
        mid = f"Mat_{len(materials) + 1}"
        materials[key] = mid
        lines = [f'[sub_resource type="StandardMaterial3D" id="{mid}"]', f"albedo_color = Color({f(c[0])}, {f(c[1])}, {f(c[2])}, 1)"]
        if c == GOLD:
            lines += ["metallic = 0.6", "roughness = 0.35"]
        if glow:
            lines += ["emission_enabled = true", f"emission = Color({f(c[0])}, {f(c[1])}, {f(c[2])}, 1)", "emission_energy_multiplier = 2.0"]
        subs.append(lines)
    return materials[key]


def box_mesh(size, c, glow=False):
    key = (size, c, glow)
    if key not in meshes:
        mid = f"Mesh_{len(meshes) + 1}"
        meshes[key] = mid
        subs.append([f'[sub_resource type="BoxMesh" id="{mid}"]', f'material = SubResource("{material(c, glow)}")', f"size = {vec(*size)}"])
    return meshes[key]


def joint(parent, name, pos):
    lines = [f'[node name="{name}" type="Node3D" parent="{parent}"]']
    if pos != (0, 0, 0):
        lines.append(f"position = {vec(*pos)}")
    nodes.append(lines)
    return name if parent == "." else f"{parent}/{name}"


def box(parent, name, pos, size, c, rot=None, glow=False):
    lines = [f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]', f"position = {vec(*pos)}"]
    if rot:
        lines.append(f"rotation = {vec(*rot)}")
    lines.append(f'mesh = SubResource("{box_mesh(size, c, glow)}")')
    nodes.append(lines)


def arm(torso, side):
    x = 0.78 * side
    a = joint(torso, "ArmL" if side < 0 else "ArmR", (x, 0.82, -0.12))
    box(a, "TornSleeve", (0, -0.04, 0), (0.5, 0.16, 0.5), CARDIGAN_DARK)
    box(a, "UpperArm", (0, -0.27, 0), (0.42, 0.48, 0.44), SKIN)
    box(a, "Bicep", (0, -0.25, -0.2), (0.32, 0.26, 0.16), SKIN)
    box(a, "Forearm", (0, -0.74, -0.02), (0.48, 0.52, 0.48), SKIN)
    box(a, "Vein1", (0.08 * side, -0.72, -0.27), (0.03, 0.38, 0.02), VEIN)
    box(a, "Vein2", (-0.06 * side, -0.78, -0.27), (0.03, 0.26, 0.02), VEIN)
    box(a, "Fist", (0, -1.1, -0.02), (0.38, 0.34, 0.4), SKIN_DARK)
    return a


def leg(hips, side):
    l = joint(hips, "LegL" if side < 0 else "LegR", (0.26 * side, 0, 0))
    box(l, "Thigh", (0, -0.24, 0), (0.4, 0.52, 0.42), STOCKING)
    box(l, "Calf", (0, -0.66, 0), (0.34, 0.4, 0.36), STOCKING)
    box(l, "Shoe", (0, -0.89, -0.08), (0.38, 0.14, 0.52), SHOE)


nodes.append(['[node name="GrumpyOmaModel" type="Node3D"]', 'script = ExtResource("1_model")'])
body = joint(".", "Body", (0, 0.95, 0))
hips = joint(body, "Hips", (0, 0, 0))
leg(hips, -1)
leg(hips, 1)
torso = joint(hips, "Torso", (0, 0.02, 0))
box(torso, "Skirt", (0, -0.12, 0), (1.04, 0.42, 0.76), SKIRT)
box(torso, "Belly", (0, 0.24, -0.06), (1.08, 0.5, 0.8), CARDIGAN)
box(torso, "Chest", (0, 0.66, -0.12), (1.3, 0.56, 0.74), CARDIGAN)
box(torso, "Hump", (0, 0.98, 0.02), (0.9, 0.3, 0.6), SKIN)
box(torso, "DeltoidL", (-0.72, 0.9, -0.1), (0.46, 0.4, 0.52), SKIN)
box(torso, "DeltoidR", (0.72, 0.9, -0.1), (0.46, 0.4, 0.52), SKIN)
box(torso, "TearL", (-0.3, 0.62, -0.495), (0.2, 0.5, 0.02), SKIN)
box(torso, "Sash", (0.05, 0.56, -0.5), (0.16, 1.3, 0.04), GOLD, rot=(0, 0, 0.75))
box(torso, "Medal", (0.3, 0.74, -0.53), (0.22, 0.22, 0.04), GOLD)
nodes.append([f'[node name="MedalNumber" type="Label3D" parent="{torso}"]', "position = Vector3(0.3, 0.74, -0.555)",
              "rotation = Vector3(0, 3.1416, 0)", "pixel_size = 0.005", "modulate = Color(0.25, 0.12, 0.05, 1)", 'text = "1"',
              "font_size = 64", "outline_size = 0"])
head = joint(torso, "Head", (0, 1.0, -0.4))
box(head, "Face", (0, 0.14, 0), (0.42, 0.4, 0.4), SKIN)
box(head, "Jaw", (0, -0.02, -0.08), (0.44, 0.14, 0.34), SKIN_DARK)
box(head, "ToothL", (-0.11, 0.07, -0.24), (0.05, 0.06, 0.03), WHITE)
box(head, "ToothR", (0.11, 0.07, -0.24), (0.05, 0.06, 0.03), WHITE)
box(head, "Mouth", (0, 0.05, -0.205), (0.24, 0.04, 0.02), DARK)
box(head, "Nose", (0, 0.13, -0.23), (0.09, 0.11, 0.08), SKIN_DARK)
box(head, "EyeL", (-0.1, 0.2, -0.205), (0.09, 0.05, 0.02), EYE, glow=True)
box(head, "EyeR", (0.1, 0.2, -0.205), (0.09, 0.05, 0.02), EYE, glow=True)
box(head, "BrowL", (-0.1, 0.26, -0.215), (0.17, 0.05, 0.04), DARK, rot=(0, 0, -0.45))
box(head, "BrowR", (0.1, 0.26, -0.215), (0.17, 0.05, 0.04), DARK, rot=(0, 0, 0.45))
box(head, "Hair", (0, 0.37, 0.02), (0.48, 0.14, 0.46), HAIR)
for n, (cx, cz) in enumerate(((-0.17, -0.15), (0.17, -0.15), (-0.2, 0.12), (0.2, 0.12))):
    box(head, f"Curl{n + 1}", (cx, 0.42, cz), (0.14, 0.12, 0.14), HAIR)
box(head, "Bun", (0, 0.46, 0.2), (0.24, 0.22, 0.22), HAIR)
box(head, "CurlerL", (-0.08, 0.47, -0.04), (0.16, 0.07, 0.07), CURLER)
box(head, "CurlerR", (0.1, 0.47, 0.06), (0.16, 0.07, 0.07), CURLER)
box(head, "Glasses", (0, 0.33, -0.2), (0.4, 0.06, 0.08), DARK, rot=(-0.5, 0, 0))
arm(torso, -1)
right = arm(torso, 1)
hand = joint(right, "Hand", (0, -1.14, 0))
box(hand, "Handbag", (0, -0.3, 0), (0.56, 0.42, 0.2), BAG)
box(hand, "Strap", (0, -0.02, 0), (0.05, 0.22, 0.05), BAG)
box(hand, "Clasp", (0, -0.16, -0.11), (0.14, 0.07, 0.03), GOLD)

out = ['[gd_scene format=3]', '', '[ext_resource type="Script" path="res://scripts/characters/humanoid_model.gd" id="1_model"]', '']
for block in subs:
    out += block + [""]
for block in nodes:
    out += block + [""]
OUT.write_text("\n".join(out).rstrip("\n") + "\n")
print(f"Wrote {OUT}: {len(nodes)} nodes")
