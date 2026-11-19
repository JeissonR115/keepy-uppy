extends SceneTree

const CPU_LEVEL_GEOMETRY_EXPORTER := preload("res://src/managers/cpu_level_geometry_exporter.gd")


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _run_test() -> void:
	var catalog := load("res://src/resources/arena_catalog.tres") as ArenaCatalog
	var arenas := catalog.get_valid_arenas()
	if not _expect(arenas.size() == 4, "Geometry test expects every current catalog arena."):
		return
	for arena: ArenaData in arenas:
		var geometry: Dictionary = CPU_LEVEL_GEOMETRY_EXPORTER.export_arena(arena)
		if not _expect(
			geometry.get("schema_version") == 1
			and geometry.get("level") == arena.id,
			"Geometry exporter omitted the schema version or arena id for %s." % arena.id
		):
			return
		var bounds: Dictionary = geometry.get("bounds", {})
		var safe_bounds: Dictionary = geometry.get("safe_bounds", {})
		var spawns: Dictionary = geometry.get("spawns", {})
		var constants: Dictionary = geometry.get("movement_constants", {})
		var auxiliary_bounds: Array = geometry.get("auxiliary_bounds", [])
		var collisions: Array = geometry.get("collisions", [])
		var platforms: Array = geometry.get("platforms", [])
		if not _expect(
			bounds.get("size", {}).get("x") == arena.playable_bounds.size.x
			and bounds.get("size", {}).get("y") == arena.playable_bounds.size.y
			and safe_bounds.get("position", {}).get("x")
			== arena.playable_bounds.position.x + arena.safe_margin.x
			and safe_bounds.get("size", {}).get("y")
			== arena.playable_bounds.size.y - arena.safe_margin.y * 2.0
			and spawns.get("player_1") == _vector_json(arena.player_1_spawn)
			and spawns.get("player_2") == _vector_json(arena.player_2_spawn)
			and auxiliary_bounds.size() == 3,
			"Geometry exporter omitted bounds, spawns, or generated safe boundaries for %s."
			% arena.id
		):
			return
		if not _expect(
			not collisions.is_empty()
			and constants.get("GRAVITY") == PlayerMovementConstants.GRAVITY
			and constants.get("JUMP_SPEED") == PlayerMovementConstants.JUMP_SPEED
			and constants.get("DASH_SPEED") == PlayerMovementConstants.DASH_SPEED
			and constants.get("DASH_COOLDOWN") == PlayerMovementConstants.DASH_COOLDOWN
			and constants.get("COYOTE_TIME") == PlayerMovementConstants.COYOTE_TIME
			and constants.get("CLIMB_MAX_STAMINA") == PlayerMovementConstants.CLIMB_MAX_STAMINA,
			"Geometry exporter omitted collision data or live movement constants for %s."
			% arena.id
		):
			return
		if arena.id in ["classic", "sky-towers", "hazard-arena"]:
			if not _expect(not platforms.is_empty(), "One-way platforms missing from %s." % arena.id):
				return
			for platform: Dictionary in platforms:
				if not _expect(
					platform.get("one_way") == true
					and platform.get("points", []).size() >= 3
					and platform.get("one_way_margin", 0.0) > 0.0,
					"One-way platform geometry is incomplete in %s." % arena.id
				):
					return
			if arena.id == "classic":
				var documented_collision_found := false
				for collision: Dictionary in collisions:
					if collision.get("source") != "LeftBoundary/CollisionShape2D":
						continue
					var shape: Dictionary = collision.get("shape", {})
					var transform: Dictionary = collision.get("transform", {})
					documented_collision_found = (
						shape.get("type") == "rectangle"
						and shape.get("size") == {"x": 16.0, "y": 180.0}
						and transform.get("origin") == {"x": 0.0, "y": 90.0}
						and collision.get("collision_layer") == 1
						and collision.get("collision_mask") == 0
						and collision.get("one_way") == false
					)
					break
				if not _expect(
					documented_collision_found,
					"Documented classic collision does not match the export."
				):
					return
				var documented_platform_found := false
				for platform: Dictionary in platforms:
					var cell: Dictionary = platform.get("cell", {})
					if cell.get("x") != 8 or cell.get("y") != 14:
						continue
					documented_platform_found = (
						platform.get("source") == "OneWayPlatforms"
						and platform.get("cell_position") == {"x": 68.0, "y": 116.0}
						and platform.get("physics_layer") == 1
						and platform.get("collision_layer") == 4
						and platform.get("collision_mask") == 0
						and platform.get("one_way") == true
						and platform.get("one_way_margin") == 2.0
						and platform.get("points")
						== [
							{"x": -4.0, "y": -4.0},
							{"x": 4.0, "y": -4.0},
							{"x": 4.0, "y": 4.0},
							{"x": -4.0, "y": 4.0},
						]
					)
					break
				if not _expect(
					documented_platform_found,
					"Documented classic one-way platform does not match the export."
				):
					return
	print("Geometry, one-way platforms, bounds, spawns, and movement constants verified for all arenas.")
	quit()


func _vector_json(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}
