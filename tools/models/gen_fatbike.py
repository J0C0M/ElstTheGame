"""Builds scenes/enemies/models/Fatbike.tscn: a low-poly fatbike.

Run from the project root: python3 tools/models/gen_fatbike.py

The bike is about 1.8 m long with wheels of 0.84 m; the fatbike-kindje rides
a scaled-up copy. Tubes are boxes between two points. Parts named Frame* and
Accent* get their colours from fatbike.gd.
"""
import math
import pathlib

OUT = pathlib.Path("scenes/enemies/models/Fatbike.tscn")
WHEEL_Z = 0.68
WHEEL_R = 0.42


def f(v):
    s = f"{v:.4f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def vec(*v):
    return "Vector3(" + ", ".join(f(c) for c in v) + ")"


subs = {}
nodes = []


def mesh(kind, **props):
    key = (kind, tuple(sorted(props.items())))
    if key not in subs:
        sid = f"{kind}_{len(subs) + 1}"
        lines = [f'[sub_resource type="{kind}" id="{sid}"]']
        for name, value in props.items():
            lines.append(f"{name} = {value}")
        subs[key] = (sid, lines)
    return subs[key][0]


def part(name, parent, mesh_id, pos, rot=(0, 0, 0)):
    lines = [f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]', f"position = {vec(*pos)}"]
    if any(rot):
        lines.append(f"rotation = {vec(*rot)}")
    lines.append(f'mesh = SubResource("{mesh_id}")')
    nodes.append(lines)


def tube(name, a, b, thickness, material="", parent="."):
    """A box from point a to point b (x, y, z) in the bike's side plane."""
    dy, dz = b[1] - a[1], b[2] - a[2]
    length = math.hypot(dy, dz)
    centre = tuple((a[i] + b[i]) / 2 for i in range(3))
    props = {"size": vec(thickness, thickness, length)}
    if material:
        props["material"] = f'SubResource("{material}")'
    part(name, parent, mesh("BoxMesh", **props), centre, (math.atan2(-dy, dz), 0, 0))


def main():
    nodes.append(['[node name="Fatbike" type="Node3D"]', 'script = ExtResource("1_script")'])
    tyre = mesh("CylinderMesh", material='SubResource("Mat_tyre")', top_radius=f(WHEEL_R), bottom_radius=f(WHEEL_R), height="0.3", radial_segments="12")
    rim = mesh("CylinderMesh", top_radius="0.27", bottom_radius="0.27", height="0.32", radial_segments="12")
    hub = mesh("CylinderMesh", material='SubResource("Mat_metal")', top_radius="0.06", bottom_radius="0.06", height="0.36", radial_segments="6")
    for name, z in (("WheelFront", -WHEEL_Z), ("WheelBack", WHEEL_Z)):
        nodes.append([f'[node name="{name}" type="Node3D" parent="."]', f"position = {vec(0, WHEEL_R, z)}"])
        for part_name, mesh_id in (("Tyre", tyre), ("AccentRim", rim), ("Hub", hub)):
            part(part_name, name, mesh_id, (0, 0, 0), (0, 0, math.pi / 2))
    bottom_bracket = (0, 0.36, 0.05)
    head_low, head_high = (0, 0.78, -0.48), (0, 0.98, -0.53)
    seat_top = (0, 0.88, 0.2)
    rear_hub, front_hub = (0, WHEEL_R, WHEEL_Z), (0, WHEEL_R, -WHEEL_Z)
    tube("FrameDownTube", bottom_bracket, head_low, 0.11)
    tube("FrameTopTube", seat_top, head_high, 0.09)
    tube("FrameSeatTube", bottom_bracket, seat_top, 0.09)
    tube("FrameHeadTube", head_low, head_high, 0.12)
    for side, x in (("Left", -0.12), ("Right", 0.12)):
        tube(f"FrameChainStay{side}", (x, 0.36, 0.05), (x, WHEEL_R, WHEEL_Z), 0.06)
        tube(f"FrameSeatStay{side}", (x, 0.86, 0.18), (x, WHEEL_R, WHEEL_Z), 0.05)
        tube(f"FrameFork{side}", (x * 1.4, 0.8, -0.5), (x * 1.4, WHEEL_R, -WHEEL_Z), 0.06)
    fender = mesh("BoxMesh", size=vec(0.36, 0.04, 0.55))
    part("FrameFenderFront", ".", fender, (0, 0.9, -0.7), (0.25, 0, 0))
    part("FrameFenderBack", ".", fender, (0, 0.9, 0.72), (-0.25, 0, 0))
    battery = mesh("BoxMesh", size=vec(0.16, 0.16, 0.42))
    part("AccentBattery", ".", battery, (0, 0.66, -0.2), (math.atan2(-0.42, -0.53), 0, 0))
    part("AccentSeat", ".", mesh("BoxMesh", size=vec(0.22, 0.08, 0.34)), (0, 0.95, 0.24))
    part("AccentStem", ".", mesh("BoxMesh", size=vec(0.06, 0.24, 0.06)), (0, 1.08, -0.55))
    part("AccentHandlebar", ".", mesh("BoxMesh", size=vec(0.72, 0.05, 0.05)), (0, 1.2, -0.55))
    grip = mesh("BoxMesh", material='SubResource("Mat_tyre")', size=vec(0.12, 0.07, 0.07))
    part("GripLeft", ".", grip, (-0.38, 1.2, -0.55))
    part("GripRight", ".", grip, (0.38, 1.2, -0.55))
    part("Headlight", ".", mesh("BoxMesh", material='SubResource("Mat_light")', size=vec(0.14, 0.09, 0.06)), (0, 0.98, -0.6))
    part("AccentCrank", ".", mesh("BoxMesh", size=vec(0.3, 0.05, 0.05)), (0, 0.36, 0.05))
    pedal = mesh("BoxMesh", size=vec(0.1, 0.03, 0.12))
    part("AccentPedalLeft", ".", pedal, (-0.18, 0.3, 0.12))
    part("AccentPedalRight", ".", pedal, (0.18, 0.42, -0.02))
    part("AccentExhaust", ".", mesh("CylinderMesh", top_radius="0.06", bottom_radius="0.075", height="0.7", radial_segments="8"),
         (0.2, 0.5, 0.85), (math.pi / 2 - 0.15, 0, 0))
    out = ['[gd_scene format=3]', '',
           '[ext_resource type="Script" path="res://scenes/enemies/models/fatbike.gd" id="1_script"]', '',
           '[sub_resource type="StandardMaterial3D" id="Mat_tyre"]', "albedo_color = Color(0.06, 0.06, 0.07, 1)", "roughness = 0.9", '',
           '[sub_resource type="StandardMaterial3D" id="Mat_metal"]', "albedo_color = Color(0.6, 0.6, 0.62, 1)", "metallic = 0.7", "roughness = 0.3", '',
           '[sub_resource type="StandardMaterial3D" id="Mat_light"]', "albedo_color = Color(1, 1, 0.9, 1)", "emission_enabled = true",
           "emission = Color(1, 1, 0.85, 1)", "emission_energy_multiplier = 2.0", '']
    for sid, lines in subs.values():
        out += lines + [""]
    for block in nodes:
        out += block + [""]
    OUT.write_text("\n".join(out).rstrip("\n") + "\n")
    print("wrote", OUT, "with", len(nodes), "nodes")


if __name__ == "__main__":
    main()
