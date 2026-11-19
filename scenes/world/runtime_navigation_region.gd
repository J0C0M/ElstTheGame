extends NavigationRegion3D
## Navigation mesh for enemies, baked on a background thread from the static
## colliders in the navigation_source group when the world loads. Baking at
## runtime keeps it in step with the blockout while the world still changes.


func _ready() -> void:
	# Deferred, so every prop has built its collider before the bake starts.
	bake_navigation_mesh.call_deferred(true)
