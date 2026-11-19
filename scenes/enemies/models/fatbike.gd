class_name Fatbike
extends Node3D
## A low-poly fatbike for fatbikers and the fatbike-kindje. Parts named Frame*
## take [member frame_color] and parts named Accent* take [member accent_color],
## so every rider can have a bike in his own colours. The wheels sit in the
## WheelFront and WheelBack pivots and spin around their local x axis.

@export var frame_color: Color = Color(0.78, 0.1, 0.1)
@export var accent_color: Color = Color(0.07, 0.07, 0.08)


func _ready() -> void:
	var frame: StandardMaterial3D = _material(frame_color)
	var accent: StandardMaterial3D = _material(accent_color)
	for part: Node in find_children("*", "MeshInstance3D", true, false):
		if part.name.begins_with("Frame"):
			(part as MeshInstance3D).material_override = frame
		elif part.name.begins_with("Accent"):
			(part as MeshInstance3D).material_override = accent


func _material(colour: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.5
	return material
