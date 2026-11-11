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
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	paused = false
	var arena: Node = main_scene.get_node("Arena")
	var level_manager: Node = arena.get_node("LevelManager")
	var map_root: Node2D = arena.get_node("MapRoot")
	var classic_map: Node2D = map_root.get_node("ClassicArenaGeometry")
	if not _expect(level_manager.get_selected_arena().get("id") == "classic", "Classic arena was not selected by default."):
		return
	if not _expect(map_root.get_child_count() == 1, "The persistent arena root does not contain exactly one map."):
		return
	var player_1: PlayerController = arena.get_node("Player1")
	var match_manager: MatchManager = arena.get_node("MatchManager")
	var balloon: BalloonController = arena.get_node("Balloon")
	var camera: Camera2D = arena.get_node("Camera2D")
	if not _expect(player_1.get_parent() == arena and player_1.get_node("../MatchManager") == match_manager, "Player and match-manager references changed after map loading."):
		return
	if not _expect(arena.get_node("Scoreboard") != null, "Scoreboard was lost when loading the map."):
		return
	if not _expect(match_manager.player_1_spawn_position == Vector2(72, 144) and match_manager.player_2_spawn_position == Vector2(248, 144), "Classic arena spawns were not applied."):
		return
	if not _expect(camera.limit_left == 0 and camera.limit_top == 0 and camera.limit_right == 320 and camera.limit_bottom == 180, "Classic arena camera limits do not match the world bounds."):
		return
	if not _expect(is_equal_approx(balloon.gravity_strength, 0.14) and is_equal_approx(balloon.max_horizontal_speed, 220.0) and is_equal_approx(player_1.arena_speed_multiplier, 1.0), "Neutral arena settings changed the default physics."):
		return

	var scoring_floor: TileMapLayer = classic_map.get_node("ScoringFloorTiles")
	var one_way_layer: TileMapLayer = classic_map.get_node("OneWayPlatforms")
	if not _expect(scoring_floor.is_in_group("scoring_ground"), "The scoring floor is not marked as scoring ground."):
		return
	if not _expect(not one_way_layer.is_in_group("scoring_ground"), "Transit platforms must not score points."):
		return
	if not _expect(one_way_layer.is_in_group("one_way_platform"), "Player drop-through detection cannot identify the one-way platform layer."):
		return
	var tileset := scoring_floor.tile_set
	if not _expect(tileset.tile_size == Vector2i(16, 16), "Arena TileSet cell size is not 16 × 16."):
		return
	var atlas := tileset.get_source(0) as TileSetAtlasSource
	var solid_tile := atlas.get_tile_data(Vector2i(1, 1), 0)
	var one_way_tile := atlas.get_tile_data(Vector2i(2, 1), 0)
	if not _expect(solid_tile.get_collision_polygons_count(0) == 1, "Solid atlas tile is missing its collision polygon."):
		return
	if not _expect(one_way_tile.is_collision_polygon_one_way(1, 0), "Platform atlas tile is not configured as one-way."):
		return
	if not _expect(one_way_tile.get_collision_polygon_one_way_margin(1, 0) == 2.0, "One-way platform margin was not configured."):
		return
	if not _expect(one_way_layer.get_used_cells().size() == 8, "Classic map does not contain the expected elevated platform tiles."):
		return

	match_manager.restart_match()
	match_manager.round_intermission = 0.0
	player_1.global_position = Vector2(88, 130)
	player_1.velocity = Vector2(0, -200)
	for _frame in range(8):
		await physics_frame
	if not _expect(player_1.global_position.y < 120.0, "Player did not pass upward through the one-way platform."):
		return
	for _frame in range(45):
		await physics_frame
	if not _expect(player_1.is_on_floor() and player_1.call("_is_on_one_way_platform"), "Player did not land on the one-way platform."):
		return
	player_1.call("_begin_platform_drop")
	for _frame in range(12):
		await physics_frame
	if not _expect(player_1.global_position.y > 120.0, "Player did not drop through the one-way platform."):
		return

	balloon.reset_round(Vector2(96, 110))
	balloon.gravity_scale = 0.0
	balloon.linear_velocity = Vector2(0, 40)
	for _frame in range(8):
		await physics_frame
	if not _expect(not balloon.ground_contact_reported, "A transit platform triggered scoring ground contact."):
		return
	if not _expect(match_manager.player_1_score + match_manager.player_2_score == 0, "A transit platform awarded a point."):
		return

	balloon.reset_round(Vector2(160, 150))
	balloon.gravity_scale = 0.0
	balloon.linear_velocity = Vector2(0, 60)
	for _frame in range(20):
		await physics_frame
	if not _expect(match_manager.player_1_score + match_manager.player_2_score == 1 and match_manager.round_number == 2, "Scoring floor contact did not resolve exactly one point."):
		return
	print("Catalog loading, map references, TileSet collisions, platform traversal, and scoring surfaces verified.")
	quit()
