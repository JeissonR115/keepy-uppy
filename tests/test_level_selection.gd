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
	var arena: Node = main_scene.get_node("Arena")
	var level_manager: Node = arena.get_node("LevelManager")
	var menu: PlayerCountMenu = main_scene.get_node("PlayerCountMenu")
	var catalog: Resource = level_manager.get("catalog").duplicate(true)
	var entries: Array = catalog.get("arenas")
	var additional_arena: Resource = entries[1].duplicate(true)
	additional_arena.set("id", "wide-test")
	additional_arena.set("display_name", "Wide Test")
	additional_arena.set("description", "A larger test arena.")
	additional_arena.set("size_classification", 2)
	additional_arena.set("playable_bounds", Rect2(0, 0, 480, 270))
	additional_arena.set("player_1_spawn", Vector2(80, 220))
	additional_arena.set("player_2_spawn", Vector2(400, 220))
	additional_arena.set("preview_texture", null)
	entries[1] = additional_arena
	catalog.set("arenas", entries)
	level_manager.set("catalog", catalog)

	menu.call("_select_player_count", 2)
	var level_buttons: Array = menu.get("level_buttons")
	if not _expect(level_buttons.size() == 3, "Arena selection did not build entries from the catalog plus Back."):
		return
	if not _expect(level_buttons[0].text.contains("Classic Court"), "Classic arena was not listed by metadata."):
		return
	if not _expect(menu.get_node("LevelPanel/Content/SelectionRow/ArenaDetails/DetailsContent/ArenaPreview").texture != null, "Classic arena preview texture did not load."):
		return
	menu.set("selected_index", 1)
	menu.call("_refresh_selection")
	if not _expect(menu.get_node("LevelPanel/Content/SelectionRow/ArenaDetails/DetailsContent/ArenaName").text == "Wide Test", "Arena details did not follow the selected catalog entry."):
		return
	if not _expect(menu.get_node("LevelPanel/Content/SelectionRow/ArenaDetails/DetailsContent/ArenaMetadata").text.contains("480×270"), "Arena dimensions were not displayed."):
		return
	if not _expect(menu.get_node("LevelPanel/Content/SelectionRow/ArenaDetails/DetailsContent/PreviewFallback").visible, "Missing preview did not show its fallback."):
		return
	menu.call("_move_selection", 1)
	if not _expect(menu.get("selected_index") == 2, "Keyboard navigation did not reach the Back option."):
		return
	menu.call("_cancel_level_selection")
	if not _expect(not menu.get("showing_levels") and menu.get_node("Panel").visible, "Cancelling arena selection did not return to player count."):
		return
	menu.call("_select_player_count", 2)
	menu.set("selected_index", 1)
	menu.call("_confirm_selection")
	if not _expect(level_manager.get_selected_arena().get("id") == "wide-test", "Confirm did not load the selected catalog arena."):
		return
	if not _expect(arena.get_node("MapRoot/SkyTowersGeometry/OneWayPlatforms").get_used_cells().size() == 15, "The second arena scene did not load its TileMap geometry."):
		return
	if not _expect(arena.get_node("Camera2D").limit_right == 480 and arena.get_node("Camera2D").limit_bottom == 270, "The selected arena bounds were not applied to the camera."):
		return
	var match_manager: MatchManager = arena.get_node("MatchManager")
	match_manager.round_intermission = 0.0
	if not _expect(match_manager.player_1.global_position == Vector2(80, 220) and match_manager.player_2.global_position == Vector2(400, 220), "Selected arena spawns were not applied before restarting the match."):
		return
	if not _expect(not match_manager.coin_toss_result.is_empty(), "Confirm did not restart the match after loading the selected arena."):
		return
	if not _expect(not menu.visible and not paused, "Confirm did not close menus and resume gameplay."):
		return
	var player_1: PlayerController = arena.get_node("Player1")
	player_1.global_position = Vector2(12, 220)
	player_1.velocity = Vector2(-160, 0)
	for _frame in range(15):
		await physics_frame
	if not _expect(player_1.global_position.x >= 9.0, "Player escaped the second arena's left boundary."):
		return
	var balloon: BalloonController = arena.get_node("Balloon")
	balloon.reset_round(Vector2(470, 100))
	balloon.gravity_scale = 0.0
	balloon.linear_velocity = Vector2(220, 0)
	for _frame in range(20):
		await physics_frame
	if not _expect(balloon.global_position.x < 480.0, "Balloon escaped the second arena's right boundary."):
		return
	balloon.reset_round(Vector2(240, 220))
	balloon.gravity_scale = 0.0
	balloon.linear_velocity = Vector2(0, 60)
	for _frame in range(35):
		await physics_frame
	if not _expect(match_manager.player_1_score + match_manager.player_2_score == 1 and match_manager.round_number == 2, "Sky Towers scoring floor did not award exactly one point."):
		return
	print("Catalog-driven arena list, metadata fallback, navigation, cancellation, and load confirmation verified.")
	quit()
