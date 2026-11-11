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
	current_scene = main_scene
	await process_frame
	var audio_manager: Node = root.get_node("AudioManager")
	var manager: MatchManager = main_scene.get_node("Arena/MatchManager")
	var player_1: CharacterBody2D = manager.player_1
	var player_2: CharacterBody2D = manager.player_2
	var player_count_menu: PlayerCountMenu = main_scene.get_node("PlayerCountMenu")
	var pause_menu: PauseMenu = main_scene.get_node("Arena/Scoreboard/PauseMenu")

	player_count_menu._select_player_count(2)
	player_count_menu._select_level("classic")
	if not _expect(
		audio_manager._last_paths.has("match_start"),
		"Starting a match after arena selection did not trigger match_start."
	):
		return
	await create_timer(0.2).timeout
	var audio_children := audio_manager.get_child_count()
	manager._restart_point()
	if not _expect(
		audio_manager.get_child_count() == audio_children,
		"Restarting a point incorrectly triggered match_start."
	):
		return
	manager.restart_match()
	if not _expect(
		audio_manager.get_child_count() == audio_children + 1,
		"Restarting the match did not trigger match_start."
	):
		return

	await create_timer(0.2).timeout
	manager.target_score = 1
	manager.sets_to_win = 10
	manager.round_intermission = 0.01
	manager.last_valid_toucher = player_1
	manager.round_faulting_player = null
	manager.match_state = manager.MatchState.ROUND_OVER
	await manager._finish_round()
	if not _expect(
		audio_manager._last_paths.has("laugh_p1")
		and audio_manager._last_paths.has("set_new_p1"),
		"Player 1 point and set wins did not trigger their sounds."
	):
		return

	manager.last_valid_toucher = player_2
	manager.round_faulting_player = null
	manager.match_state = manager.MatchState.ROUND_OVER
	await manager._finish_round()
	if not _expect(
		audio_manager._last_paths.has("laugh_p2")
		and audio_manager._last_paths.has("set_new_p2"),
		"Player 2 point and set wins did not trigger their sounds."
	):
		return

	var menu_sounds := audio_manager.get_child_count()
	player_count_menu.open_menu()
	player_count_menu._select_player_count(2)
	if not _expect(
		audio_manager.get_child_count() == menu_sounds + 1
		and audio_manager._last_paths.has("menu_select"),
		"Selecting a player-count menu option did not play its local sound."
	):
		return

	player_count_menu._select_level("classic")
	await create_timer(0.2).timeout
	menu_sounds = audio_manager.get_child_count()
	pause_menu._on_pause_option_pressed(2)
	if not _expect(
		audio_manager.get_child_count() == menu_sounds + 1,
		"Confirming a pause-menu option did not play menu_select."
	):
		return

	await create_timer(0.2).timeout
	main_scene.queue_free()
	await process_frame
	print("Match, point, set, and confirmed menu sound assignments verified for both players.")
	quit()
