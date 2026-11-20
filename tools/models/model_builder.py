"""Shared helpers to write low-poly model scenes (.tscn) from Python.

A model is a tree of joints (Node3D) and parts (MeshInstance3D) made of
Godot primitives in flat colours: boxes, prisms, cones and cylinders. Parts
can be placed between two points ("bones"), and a membrane (MembraneMesh)
can be stretched between marker nodes, for wings that bend with the joints.

    m = Model("AmberModel", script="res://scenes/bosses/amber_model.gd")
    body = m.joint(".", "Body", (0, 3, 0))
    m.box(body, "Torso", (0, 0, 0), (3, 2.6, 6), AMBER)
    m.write("scenes/bosses/AmberModel.tscn")
"""
import math
import pathlib


def f(v):
    s = f"{v:.4f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def vec(*v):
    return "Vector3(" + ", ".join(f(c) for c in v) + ")"


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def scale(a, s):
    return tuple(x * s for x in a)


def length(a):
    return math.sqrt(sum(x * x for x in a))


def align_z(v):
    """Euler rotation (YXZ) that turns local +Z towards v."""
    n = length(v)
    return (-math.asin(max(-1.0, min(1.0, v[1] / n))), math.atan2(v[0], v[2]), 0.0)


def align_y(v):
    """Euler rotation (YXZ) that turns local +Y towards v."""
    n = length(v)
    pitch = math.acos(max(-1.0, min(1.0, v[1] / n)))
    yaw = math.atan2(v[0], v[2]) if abs(v[0]) + abs(v[2]) > 1e-6 else 0.0
    return (pitch, yaw, 0.0)


class Model:
    def __init__(self, root, script=None, root_type="Node3D", extra_ext=()):
        self.subs = []
        self.materials = {}
        self.meshes = {}
        self.nodes = []
        self.ext = []
        if script:
            self.ext.append(("Script", script, "1_script"))
        self.ext += list(extra_ext)
        lines = [f'[node name="{root}" type="{root_type}"]']
        if script:
            lines.append('script = ExtResource("1_script")')
        self.nodes.append(lines)
        self.root_lines = lines

    # Materials and meshes are shared between parts of the same look.
    def material(self, c, glow=0.0, metal=False, double=False):
        key = (c, glow, metal, double)
        if key not in self.materials:
            mid = f"Mat_{len(self.materials) + 1}"
            self.materials[key] = mid
            lines = [f'[sub_resource type="StandardMaterial3D" id="{mid}"]', f"albedo_color = Color({f(c[0])}, {f(c[1])}, {f(c[2])}, 1)"]
            if metal:
                lines += ["metallic = 0.6", "roughness = 0.35"]
            if glow:
                lines += ["emission_enabled = true", f"emission = Color({f(c[0])}, {f(c[1])}, {f(c[2])}, 1)", f"emission_energy_multiplier = {f(glow)}"]
            if double:
                lines.append("cull_mode = 2")
            self.subs.append(lines)
        return self.materials[key]

    def mesh(self, kind, props, c, glow=0.0, metal=False):
        key = (kind, tuple(sorted(props.items())), c, glow, metal)
        if key not in self.meshes:
            mid = f"Mesh_{len(self.meshes) + 1}"
            self.meshes[key] = mid
            lines = [f'[sub_resource type="{kind}" id="{mid}"]', f'material = SubResource("{self.material(c, glow, metal)}")']
            for name, value in props.items():
                lines.append(f"{name} = {vec(*value) if isinstance(value, tuple) else f(value) if isinstance(value, float) else value}")
            self.subs.append(lines)
        return self.meshes[key]

    def joint(self, parent, name, pos=(0, 0, 0), rot=None):
        lines = [f'[node name="{name}" type="Node3D" parent="{parent}"]']
        if any(pos):
            lines.append(f"position = {vec(*pos)}")
        if rot and any(rot):
            lines.append(f"rotation = {vec(*rot)}")
        self.nodes.append(lines)
        return name if parent == "." else f"{parent}/{name}"

    def marker(self, parent, name, pos):
        return self.joint(parent, name, pos)

    def part(self, parent, name, mesh_id, pos, rot=None, hidden=False):
        lines = [f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]']
        if hidden:
            lines.append("visible = false")
        lines.append(f"position = {vec(*pos)}")
        if rot and any(rot):
            lines.append(f"rotation = {vec(*rot)}")
        lines.append(f'mesh = SubResource("{mesh_id}")')
        self.nodes.append(lines)
        return name if parent == "." else f"{parent}/{name}"

    def box(self, parent, name, pos, size, c, rot=None, glow=0.0, metal=False, hidden=False):
        return self.part(parent, name, self.mesh("BoxMesh", {"size": tuple(size)}, c, glow, metal), pos, rot, hidden)

    def prism(self, parent, name, pos, size, c, rot=None, glow=0.0, hidden=False):
        """A wedge: a triangle in X-Y (point up), size[2] deep along Z."""
        return self.part(parent, name, self.mesh("PrismMesh", {"size": tuple(size)}, c, glow), pos, rot, hidden)

    def cone(self, parent, name, base, tip, radius, c, sides=5, top=0.0, glow=0.0):
        """A cone or tapered cylinder from point base to point tip."""
        v = sub(tip, base)
        props = {"top_radius": float(top), "bottom_radius": float(radius), "height": float(length(v)),
                 "radial_segments": sides, "rings": 0}
        return self.part(parent, name, self.mesh("CylinderMesh", props, c, glow), add(base, scale(v, 0.5)), align_y(v))

    def bone(self, parent, name, a, b, width, height, c, glow=0.0):
        """A box from point a to point b, width x height thick."""
        v = sub(b, a)
        return self.box(parent, name, add(a, scale(v, 0.5)), (width, height, length(v)), c, rot=align_z(v), glow=glow)

    def label(self, parent, name, pos, text, color, size=48, pixel=0.006, rot=None):
        lines = [f'[node name="{name}" type="Label3D" parent="{parent}"]', f"position = {vec(*pos)}"]
        if rot:
            lines.append(f"rotation = {vec(*rot)}")
        lines += [f"pixel_size = {f(pixel)}", f"modulate = Color({f(color[0])}, {f(color[1])}, {f(color[2])}, 1)", f'text = "{text}"',
                  f"font_size = {size}", "outline_size = 0"]
        self.nodes.append(lines)

    def membrane(self, parent, name, markers, triangles, c):
        """A MembraneMesh stretched between marker nodes (paths from the
        membrane node) as a list of triangles (indices into markers)."""
        if not any(e[1] == "res://scripts/characters/membrane_mesh.gd" for e in self.ext):
            self.ext.append(("Script", "res://scripts/characters/membrane_mesh.gd", "2_membrane"))
        paths = ", ".join(f'NodePath("{p}")' for p in markers)
        tris = ", ".join(str(i) for t in triangles for i in t)
        self.nodes.append([f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]', 'script = ExtResource("2_membrane")',
                           f"points = Array[NodePath]([{paths}])", f"triangles = PackedInt32Array({tris})",
                           f'material_override = SubResource("{self.material(c, double=True)}")'])
        return name if parent == "." else f"{parent}/{name}"

    def write(self, out):
        lines = ["[gd_scene format=3]", ""]
        for kind, path, rid in self.ext:
            lines.append(f'[ext_resource type="{kind}" path="{path}" id="{rid}"]')
        lines.append("")
        for block in self.subs:
            lines += block + [""]
        for block in self.nodes:
            lines += block + [""]
        pathlib.Path(out).write_text("\n".join(lines).rstrip("\n") + "\n")
        print(f"Wrote {out}: {len(self.nodes)} nodes")
