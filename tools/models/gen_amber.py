"""Builds scenes/bosses/AmberModel.tscn: Amber de Draak, about 12 m long.

Run from the project root: python3 tools/models/gen_amber.py

Boxes in amber and orange: a body with spikes, a long neck, a head with
horns, glowing eyes, a jaw that opens and a throat that glows before her
fire breath, wings with skin, a tail in three parts and four legs. The
joints (Neck, Head, Jaw, Tail, Tail2, Tail3, WingL, WingR and the legs) are
moved by amber_model.gd. She faces -Z.
"""
import pathlib

OUT = pathlib.Path("scenes/bosses/AmberModel.tscn")

SCALE = (0.92, 0.55, 0.15)
DARK = (0.45, 0.2, 0.07)
BELLY = (0.88, 0.76, 0.45)
HORN = (0.25, 0.17, 0.11)
WING = (0.78, 0.32, 0.1)
EYE = (1.0, 0.9, 0.3)
THROAT = (1.0, 0.5, 0.1)


def f(v):
    s = f"{v:.3f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def vec(*v):
    return "Vector3(" + ", ".join(f(c) for c in v) + ")"


subs = []
materials = {}
meshes = {}
nodes = []


def material(c, glow):
    key = (c, glow)
    if key not in materials:
        mid = f"Mat_{len(materials) + 1}"
        materials[key] = mid
        lines = [f'[sub_resource type="StandardMaterial3D" id="{mid}"]', f"albedo_color = Color({f(c[0])}, {f(c[1])}, {f(c[2])}, 1)"]
        if glow:
            lines.append("shading_mode = 0")
        subs.append(lines)
    return materials[key]


def box_mesh(size, c, glow):
    key = (size, c, glow)
    if key not in meshes:
        mid = f"Mesh_{len(meshes) + 1}"
        meshes[key] = mid
        subs.append([f'[sub_resource type="BoxMesh" id="{mid}"]', f'material = SubResource("{material(c, glow)}")', f"size = {vec(*size)}"])
    return meshes[key]


def joint(parent, name, pos, rot=None):
    lines = [f'[node name="{name}" type="Node3D" parent="{parent}"]', f"position = {vec(*pos)}"]
    if rot:
        lines.append(f"rotation = {vec(*rot)}")
    nodes.append(lines)
    return name if parent == "." else f"{parent}/{name}"


def box(parent, name, pos, size, c, rot=None, glow=False, hidden=False):
    lines = [f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]']
    if hidden:
        lines.append("visible = false")
    lines.append(f"position = {vec(*pos)}")
    if rot:
        lines.append(f"rotation = {vec(*rot)}")
    lines.append(f'mesh = SubResource("{box_mesh(size, c, glow)}")')
    nodes.append(lines)


nodes.append(['[node name="AmberModel" type="Node3D"]', 'script = ExtResource("1_model")'])
body = joint(".", "Body", (0, 3.0, 0))
box(body, "Torso", (0, 0, 0), (3.2, 2.6, 6.0), SCALE)
box(body, "Belly", (0, -1.2, 0), (2.6, 0.6, 5.0), BELLY)
for n, z in enumerate((-2.2, -1.1, 0, 1.1, 2.2)):
    box(body, f"Spike{n}", (0, 1.55, z), (0.4, 0.7 - abs(z) * 0.08, 0.6), DARK, rot=(0.4, 0, 0))
neck = joint(body, "Neck", (0, 0.9, -2.8), rot=(0.45, 0, 0))
box(neck, "NeckMesh", (0, 0, -1.4), (1.3, 1.3, 3.0), SCALE)
box(neck, "NeckBelly", (0, -0.6, -1.4), (1.0, 0.2, 2.8), BELLY)
head = joint(neck, "Head", (0, 0, -2.8))
box(head, "HeadMesh", (0, 0.1, -0.8), (1.7, 1.3, 2.0), SCALE)
box(head, "Snout", (0, -0.05, -2.2), (1.2, 0.8, 1.3), SCALE)
box(head, "Brow", (0, 0.72, -1.3), (1.8, 0.25, 0.6), DARK)
for side in (-1, 1):
    box(head, f"Horn{'L' if side < 0 else 'R'}", (side * 0.55, 1.0, 0.0), (0.25, 1.2, 0.25), HORN, rot=(-0.7, 0, side * -0.3))
    box(head, f"Eye{'L' if side < 0 else 'R'}", (side * 0.6, 0.42, -1.55), (0.35, 0.2, 0.08), EYE, glow=True)
    box(head, f"Nostril{'L' if side < 0 else 'R'}", (side * 0.3, 0.2, -2.86), (0.15, 0.1, 0.05), HORN)
jaw = joint(head, "Jaw", (0, -0.45, -0.6))
box(jaw, "JawMesh", (0, -0.1, -1.0), (1.1, 0.3, 1.9), DARK)
box(jaw, "Teeth", (0, 0.1, -1.7), (1.0, 0.15, 0.3), (0.95, 0.92, 0.85))
box(head, "MouthGlow", (0, -0.35, -1.6), (0.9, 0.35, 1.4), THROAT, glow=True, hidden=True)
tail = joint(body, "Tail", (0, 0.2, 3.0))
box(tail, "Tail1", (0, 0, 1.2), (1.1, 1.0, 2.4), SCALE)
tail2 = joint(tail, "Tail2", (0, 0, 2.4))
box(tail2, "Tail2Mesh", (0, 0, 1.2), (0.8, 0.7, 2.4), SCALE)
tail3 = joint(tail2, "Tail3", (0, 0, 2.4))
box(tail3, "Tail3Mesh", (0, 0, 1.1), (0.5, 0.45, 2.2), SCALE)
box(tail3, "TailSpike", (0, 0.3, 2.0), (0.3, 0.8, 0.5), DARK, rot=(0.6, 0, 0))
for side in (-1, 1):
    wing = joint(body, "WingL" if side < 0 else "WingR", (side * 1.5, 1.0, -0.6))
    box(wing, "Bone", (side * 2.4, 0, 0), (4.8, 0.3, 0.35), DARK)
    box(wing, "Skin", (side * 2.3, -0.05, 1.5), (4.4, 0.08, 3.0), WING)
    box(wing, "Claw", (side * 4.9, 0, 0), (0.4, 0.4, 0.4), HORN)
for name, x, z in (("LegFL", -1.3, -1.8), ("LegFR", 1.3, -1.8), ("LegBL", -1.3, 1.8), ("LegBR", 1.3, 1.8)):
    leg = joint(body, name, (x, -0.9, z))
    box(leg, "LegMesh", (0, -1.0, 0), (0.85, 2.2, 0.95), SCALE)
    box(leg, "Foot", (0, -2.0, -0.3), (1.0, 0.35, 1.4), DARK)

out = ['[gd_scene format=3]', '', '[ext_resource type="Script" path="res://scenes/bosses/amber_model.gd" id="1_model"]', '']
for block in subs:
    out += block + [""]
for block in nodes:
    out += block + [""]
OUT.write_text("\n".join(out).rstrip("\n") + "\n")
print(f"Wrote {OUT}: {len(nodes)} nodes")
