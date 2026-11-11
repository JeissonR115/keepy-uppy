extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _run_test() -> void:
	var tile_set := load("res://assets/sprites/arena/arena_tileset.tres") as TileSet
	var balloon_scene := load("res://src/models/balloon/balloon_placeholder.tscn") as PackedScene
	var balloon := balloon_scene.instantiate() as RigidBody2D
	if not _expect(tile_set.get_physics_layers_count() == 3, "Arena TileSet must define solid, one-way, and trampoline physics layers."):
		return
	if not _expect(tile_set.get_physics_layer_collision_layer(0) == 1 and tile_set.get_physics_layer_collision_layer(1) == 4 and tile_set.get_physics_layer_collision_layer(2) == 2, "Arena TileSet physics layers do not match the solid, one-way, and trampoline collision bits."):
		return
	if not _expect(balloon.get_collision_mask_value(1) and balloon.get_collision_mask_value(2) and not balloon.get_collision_mask_value(3), "Balloon collision mask must include solid/trampoline and exclude one-way platforms."):
		return
	var atlas := tile_set.get_source(0) as TileSetAtlasSource
	var solid := atlas.get_tile_data(Vector2i(1, 1), 0)
	var platform := atlas.get_tile_data(Vector2i(2, 1), 0)
	var trampoline_atlas := tile_set.get_source(1) as TileSetAtlasSource
	var trampoline := trampoline_atlas.get_tile_data(Vector2i.ZERO, 0)
	if not _expect(solid.get_collision_polygons_count(0) > 0, "Solid tile has no solid collision polygon."):
		return
	if not _expect(platform.is_collision_polygon_one_way(1, 0), "One-way platform tile is not one-way."):
		return
	if not _expect(trampoline.get_collision_polygons_count(2) > 0, "Trampoline tile has no dedicated trampoline collision polygon."):
		return
	for scene_path in [
		"res://src/scenes/levels/arena_classic.tscn",
		"res://src/scenes/levels/sky_towers.tscn",
	]:
		var map := (load(scene_path) as PackedScene).instantiate()
		if not _expect(map.get_node("ScoringFloorTiles").is_in_group("scoring_ground"), "%s has no scoring surface group." % scene_path):
			return
		if not _expect(map.get_node("OneWayPlatforms").is_in_group("one_way_platform"), "%s has no one-way platform group." % scene_path):
			return
		if not _expect(map.get_node("TrampolineTiles").is_in_group("trampoline"), "%s has no trampoline group." % scene_path):
			return
		if not _expect(map.get_node("ClimbableWallTiles").is_in_group("climbable_wall"), "%s has no climbable wall group." % scene_path):
			return
		if not _expect(map.get_node("TrampolineTiles").get_used_cells().size() > 0 and map.get_node("ClimbableWallTiles").get_used_cells().size() > 0, "%s has empty trampoline or climbable wall tiles." % scene_path):
			return
		map.free()
	balloon.free()
	print("Scoring, one-way, trampoline, and climbable TileSet roles load correctly in both arenas.")
	quit()
