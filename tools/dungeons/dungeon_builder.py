"""Shared builder for the dungeon scenes in scenes/dungeons/.

A dungeon script (gen_station.py, gen_westeraam.py) describes its rooms,
props, labels and lights as data and calls build(). Rooms are boxes with a
floor, a ceiling and walls with door gaps; north and south walls cover the
corners, west and east walls fit in between. A side set to None has no wall:
the neighbouring room builds it. +x is east, -z is north (deeper in).
"""
import math
import pathlib
import random

FLOOR = (0.42, 0.42, 0.4)
CEILING = (0.17, 0.17, 0.19)
STEEL = (0.45, 0.45, 0.48)


def f(v):
    s = f"{v:.4f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def vec(*v):
    return "Vector3(" + ", ".join(f(c) for c in v) + ")"


def col(c):
    """A colour (r, g, b), or (r, g, b, a) for see-through glass."""
    return f"Color({f(c[0])}, {f(c[1])}, {f(c[2])}, {f(c[3]) if len(c) > 3 else 1})"


def wall_segments(a0, a1, doors):
    """Pieces of a wall from a0 to a1 along its axis, leaving the doors open."""
    cuts = sorted((door[0] - door[1] / 2, door[0] + door[1] / 2) for door in doors)
    pieces, start = [], a0
    for lo, hi in cuts:
        if lo > start:
            pieces.append((start, lo))
        start = max(start, hi)
    if a1 > start:
        pieces.append((start, a1))
    return [(lo, hi) for lo, hi in pieces if hi - lo > 0.05]


class Dungeon:
    def __init__(self):
        self.subs = []
        self.nodes = []
        self._materials = {}
        self._meshes = {}
        self._shapes = {}

    def material(self, c):
        if c not in self._materials:
            mid = f"Mat_{len(self._materials) + 1}"
            self._materials[c] = mid
            lines = [f'[sub_resource type="StandardMaterial3D" id="{mid}"]']
            if len(c) > 3:
                lines.append("transparency = 1")
            self.subs.append(lines + [f"albedo_color = {col(c)}", "roughness = 0.9"])
        return self._materials[c]

    def box_mesh(self, size, c):
        key = (tuple(round(v, 3) for v in size), c)
        if key not in self._meshes:
            mid = f"Box_{len(self._meshes) + 1}"
            self._meshes[key] = mid
            self.subs.append([f'[sub_resource type="BoxMesh" id="{mid}"]', f'material = SubResource("{self.material(c)}")', f"size = {vec(*size)}"])
        return self._meshes[key]

    def box_shape(self, size):
        key = tuple(round(v, 3) for v in size)
        if key not in self._shapes:
            sid = f"Shape_{len(self._shapes) + 1}"
            self._shapes[key] = sid
            self.subs.append([f'[sub_resource type="BoxShape3D" id="{sid}"]', f"size = {vec(*size)}"])
        return self._shapes[key]

    def solid(self, parent, name, pos, size, c):
        self.nodes.append([f'[node name="{name}" type="StaticBody3D" parent="{parent}"]', f"position = {vec(*pos)}"])
        self.nodes.append([f'[node name="CollisionShape3D" type="CollisionShape3D" parent="{parent}/{name}"]',
                           f'shape = SubResource("{self.box_shape(size)}")'])
        self.nodes.append([f'[node name="Mesh" type="MeshInstance3D" parent="{parent}/{name}"]', f'mesh = SubResource("{self.box_mesh(size, c)}")'])

    def visual(self, parent, name, pos, size, c):
        self.nodes.append([f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]', f"position = {vec(*pos)}",
                           f'mesh = SubResource("{self.box_mesh(size, c)}")'])

    def lintel(self, room, side, n, centre, width, height, colour, along_x, top=None):
        """The wall above a door: 3.2 m high doors, 4.5 m for wide openings.
        An opening wider than 8 m is where a whole room joins; give it a top
        (the neighbour's height) when that room is lower, to close the wall above it."""
        if top is None:
            if width > 8:
                return
            top = 3.2 if width <= 4 else 4.5
        if top >= height:
            return
        size = (width, height - top, 1) if along_x else (1, height - top, width)
        self.solid("Structure", f"{room}Lintel{side}{n}", (centre[0], (top + height) / 2, centre[1]), size, colour)

    def build_rooms(self, rooms, props):
        """rooms: name -> ((x0, x1, z0, z1), wall colour, height, doors per side);
        a door is (centre, width) or (centre, width, top of the opening).
        props: (name, x, z, size, colour, solid)."""
        self.nodes.append(['[node name="Structure" type="Node3D" parent="." groups=["navigation_source"]]'])
        for name, ((x0, x1, z0, z1), wall_color, height, sides) in rooms.items():
            self.solid("Structure", f"{name}Floor", ((x0 + x1) / 2, -0.5, (z0 + z1) / 2), (x1 - x0, 1, z1 - z0), FLOOR)
            self.solid("Structure", f"{name}Ceiling", ((x0 + x1) / 2, height + 0.5, (z0 + z1) / 2), (x1 - x0, 1, z1 - z0), CEILING)
            for side, doors in sides.items():
                if doors is None:
                    continue
                if side in ("N", "S"):
                    z = z0 if side == "N" else z1
                    a0 = x0 - 0.5 if sides["W"] is not None else x0 + 0.5
                    a1 = x1 + 0.5 if sides["E"] is not None else x1 - 0.5
                    for n, (lo, hi) in enumerate(wall_segments(a0, a1, doors)):
                        self.solid("Structure", f"{name}Wall{side}{n}", ((lo + hi) / 2, height / 2, z), (hi - lo, height, 1), wall_color)
                    for n, door in enumerate(doors):
                        self.lintel(name, side, n, (door[0], z), door[1], height, wall_color, True, *door[2:])
                else:
                    x = x0 if side == "W" else x1
                    for n, (lo, hi) in enumerate(wall_segments(z0 + 0.5, z1 - 0.5, doors)):
                        self.solid("Structure", f"{name}Wall{side}{n}", (x, height / 2, (lo + hi) / 2), (1, height, hi - lo), wall_color)
                    for n, door in enumerate(doors):
                        self.lintel(name, side, n, (x, door[0]), door[1], height, wall_color, False, *door[2:])
        for name, x, z, size, c, is_solid in props:
            pos = (x, size[1] / 2 + (0.01 if not is_solid else 0), z)
            (self.solid if is_solid else self.visual)("Structure", name, pos, size, c)

    def build_track(self, rail_x, rail_z):
        self.nodes.append(['[node name="Track" type="Node3D" parent="."]'])
        length = rail_z[1] - rail_z[0]
        centre = (rail_z[0] + rail_z[1]) / 2
        self.visual("Track", "Bed", (rail_x, 0.02, centre), (3.0, 0.04, length), (0.3, 0.27, 0.24))
        for name, dx in (("RailLeft", -0.72), ("RailRight", 0.72)):
            self.visual("Track", name, (rail_x + dx, 0.1, centre), (0.12, 0.14, length), STEEL)

    def build_labels_and_lights(self, labels, lights):
        """labels: (name, x, y, z, yaw, text, colour). lights: (name, x, y, z, colour, energy, range)."""
        for name, x, y, z, yaw, text, c in labels:
            self.nodes.append([f'[node name="{name}" type="Label3D" parent="."]', f"position = {vec(x, y, z)}", f"rotation = {vec(0, yaw, 0)}",
                               "pixel_size = 0.01", f"modulate = {col(c)}", "outline_modulate = Color(0, 0, 0, 1)", f'text = "{text}"',
                               "font_size = 64", "outline_size = 12"])
        for name, x, y, z, c, energy, rng in lights:
            self.nodes.append([f'[node name="{name}" type="OmniLight3D" parent="."]', f"position = {vec(x, y, z)}", f"light_color = {col(c)}",
                               f"light_energy = {f(energy)}", f"omni_range = {f(rng)}"])

    def write(self, out_path, world, ext, extra):
        """world: root name, location name and id, ambient colour, navigation id
        and AABB, and the exit (door z, marker z, entrance z, Elst spawn, door
        colour). ext: extra ext_resources (type, path, id). extra: lines added
        after the navigation region (enemies, chests, bosses)."""
        out = ['[gd_scene format=3]', '',
               '[ext_resource type="Script" path="res://scenes/world/game_world.gd" id="1_world"]',
               '[ext_resource type="PackedScene" path="res://scenes/player/Player.tscn" id="2_player"]',
               '[ext_resource type="PackedScene" path="res://scenes/world/props/DungeonEntrance.tscn" id="3_door"]',
               '[ext_resource type="Script" path="res://scripts/quests/quest_marker.gd" id="4_marker"]',
               '[ext_resource type="Script" path="res://scenes/world/runtime_navigation_region.gd" id="20_nav"]']
        for kind, path, rid in ext:
            out.append(f'[ext_resource type="{kind}" path="{path}" id="{rid}"]')
        out += ['', '[sub_resource type="Environment" id="Environment_dungeon"]', 'background_mode = 1',
                'background_color = Color(0.03, 0.03, 0.04, 1)', 'ambient_light_source = 2',
                f'ambient_light_color = {col(world["ambient"])}', 'ambient_light_energy = 0.3', '',
                f'[sub_resource type="NavigationMesh" id="{world["nav_id"]}"]', 'geometry_parsed_geometry_type = 1',
                'geometry_collision_mask = 1', 'geometry_source_geometry_mode = 1',
                'geometry_source_group_name = &"navigation_source"', 'cell_size = 0.5', 'cell_height = 0.25',
                'agent_height = 1.75', 'agent_radius = 0.5', 'agent_max_climb = 0.5', 'agent_max_slope = 40.0',
                f'filter_baking_aabb = AABB({", ".join(f(v) for v in world["nav_aabb"])})', '']
        for block in self.subs:
            out += block + [""]
        out += [f'[node name="{world["root"]}" type="Node3D"]', 'script = ExtResource("1_world")', f'location_name = "{world["location_name"]}"',
                f'location_id = &"{world["location_id"]}"', 'default_spawn = &"Entrance"', "autosave_on_enter = true", "",
                '[node name="WorldEnvironment" type="WorldEnvironment" parent="."]', 'environment = SubResource("Environment_dungeon")', ""]
        for block in self.nodes:
            out += block + [""]
        door_z, marker_z, entrance_z, spawn, door_color = world["exit"]
        out += ['[node name="ExitDoor" parent="." instance=ExtResource("3_door")]', f"position = Vector3(0, 0, {f(door_z)})",
                'target_scene = "res://scenes/world/Elst.tscn"', f'target_spawn = &"{spawn}"', 'prompt = "Terug naar Elst"',
                f"door_color = {col(door_color)}", "",
                '[node name="MarkerExit" type="Marker3D" parent="."]', f"position = Vector3(0, 0, {f(marker_z)})", 'script = ExtResource("4_marker")',
                "ids = Array[StringName]([&\"klaas\"])", "",
                '[node name="Entrance" type="Marker3D" parent="." groups=["spawn_points"]]', f"position = Vector3(0, 0, {f(entrance_z)})", "",
                '[node name="Player" parent="." instance=ExtResource("2_player")]', f"position = Vector3(0, 0, {f(entrance_z)})", "",
                '[node name="Navigation" type="NavigationRegion3D" parent="."]', f'navigation_mesh = SubResource("{world["nav_id"]}")',
                'script = ExtResource("20_nav")', ""]
        out += extra
        pathlib.Path(out_path).write_text("\n".join(out).rstrip("\n") + "\n")


def _room_at(rooms, x, z, skip=None, margin=0.6):
    for name, ((x0, x1, z0, z1), *_rest) in rooms.items():
        if name != skip and x0 - margin <= x <= x1 + margin and z0 - margin <= z <= z1 + margin:
            return name
    return None


def entry_points(rooms, start):
    """For each room, the doorway the player first comes in through, found by
    walking through the doors from the room that holds [start] (x, z). A side
    without a wall (None) counts as one wide doorway in its middle."""
    first = _room_at(rooms, *start, margin=0)
    entry = {first: start}
    queue = [first]
    while queue:
        name = queue.pop(0)
        (x0, x1, z0, z1), _colour, _height, sides = rooms[name]
        points = []
        for side, doors in sides.items():
            centres = [(x0 + x1) / 2 if side in ("N", "S") else (z0 + z1) / 2] if doors is None else [door[0] for door in doors]
            for c in centres:
                points.append({"N": (c, z0), "S": (c, z1), "W": (x0, c), "E": (x1, c)}[side])
        for point in points:
            other = _room_at(rooms, *point, skip=name)
            if other is not None and other not in entry:
                entry[other] = point
                queue.append(other)
    return entry


def aim_enemies(enemies, rooms, start, toward_share, seed):
    """Turns the enemies at the start, so not all of them look the same way:
    about [toward_share] of them face the doorway the player comes in through
    (a little off), the others look a random way. Enemies are tuples that end
    in x, z, yaw; the same seed gives the same result every run."""
    rng = random.Random(seed)
    entry = entry_points(rooms, start)
    aimed = []
    for enemy in enemies:
        x, z = enemy[-3], enemy[-2]
        target = entry.get(_room_at(rooms, x, z))
        toward = rng.random() < toward_share
        jitter = rng.uniform(-0.45, 0.45)
        if toward and target is not None:
            yaw = math.atan2(-(target[0] - x), -(target[1] - z)) + jitter
        else:
            yaw = rng.uniform(-math.pi, math.pi)
        aimed.append(tuple(enemy[:-1]) + (round(yaw, 3),))
    return aimed
