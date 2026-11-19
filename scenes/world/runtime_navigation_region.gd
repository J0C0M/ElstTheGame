extends NavigationRegion3D
## Navigation mesh for enemies, baked on a background thread from the static
## colliders in the navigation_source group. Baking at runtime keeps it in
## step with the blockout while the world still changes. The mesh resource is
## shared by every load of the world, so it is baked once per run; later
## loads pick up the baked mesh straight away.


func _ready() -> void:
	if navigation_mesh.get_polygon_count() > 0 or NavigationServer3D.is_baking_navigation_mesh(navigation_mesh):
		return
	# Deferred, so every prop has built its collider before the bake starts.
	bake_navigation_mesh.call_deferred(true)
