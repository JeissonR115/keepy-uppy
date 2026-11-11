extends SceneTree

const SETTINGS_PATH := "/tmp/keepy-restart-controls.cfg"


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _run_test() -> void:
	_remove_test_file()
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	var settings_manager: Node = main_scene.get_node("ControlSettingsManager")
	settings_manager.settings_path = SETTINGS_PATH
	var arena: Node = main_scene.get_node("Arena")
	var manager: Node = arena.get_node("MatchManager")
	manager.coin_toss_override = 0
	root.add_child(main_scene)
	await process_frame

	var custom_key := InputEventKey.new()
	custom_key.physical_keycode = KEY_Z
	var binding_result: Dictionary = settings_manager.try_set_binding("player_1_left", custom_key)
	if not _expect(binding_result.valid, "Could not create a saved binding for the restart check."):
		return
	manager.player_1_score = 3
	manager.player_2_score = 1
	manager.player_1_sets = 2
	manager.player_2_sets = 1
	manager.round_number = 27
	manager.match_state = manager.MatchState.COMPLETE
	manager.match_winner = manager.player_1

	var scoreboard: CanvasLayer = arena.get_node("Scoreboard")
	var pause_menu: PauseMenu = scoreboard.get_node("PauseMenu")
	var player_count_menu: PlayerCountMenu = main_scene.get_node("PlayerCountMenu")
	if not _expect(
		player_count_menu.visible and paused,
		"Player-count selection did not open automatically when the game started."
	):
		return
	player_count_menu._select_player_count(2)
	player_count_menu._select_level("classic")
	manager.player_1_score = 3
	manager.player_2_score = 1
	manager.player_1_sets = 2
	manager.player_2_sets = 1
	manager.round_number = 27
	manager.match_state = manager.MatchState.COMPLETE
	manager.match_winner = manager.player_1
	scoreboard.call("_input", _escape_event())
	Input.action_press("player_1_down")
	await process_frame
	Input.action_release("player_1_down")
	Input.action_press("player_1_jump")
	await process_frame
	Input.action_release("player_1_jump")
	if not _expect(
		pause_menu.current_screen == pause_menu.MenuScreen.RESTART_CONFIRMATION
		and pause_menu.selected_index == 1,
		"Restart confirmation did not default to No."
	):
		return
	Input.action_press("player_1_left")
	await process_frame
	Input.action_release("player_1_left")
	Input.action_press("player_1_jump")
	await process_frame
	Input.action_release("player_1_jump")
	if not _expect(
		player_count_menu.visible and paused
		and manager.match_state == manager.MatchState.COMPLETE
		and manager.player_1_score == 3 and manager.player_2_score == 1
		and manager.player_1_sets == 2 and manager.player_2_sets == 1
		and manager.round_number == 27,
		"Confirmed restart did not open player selection before resetting the match."
	):
		return
	_press_key(player_count_menu.keyboard_navigator, KEY_D)
	if not _expect(
		player_count_menu.selected_index == 1,
		"Horizontal navigation did not select the two-player option (visible=%s, enabled=%s, index=%d)." % [
			player_count_menu.visible,
			player_count_menu.keyboard_navigator.enabled,
			player_count_menu.selected_index,
		]
	):
		return
	_press_key(player_count_menu.keyboard_navigator, KEY_A)
	if not _expect(
		player_count_menu.selected_index == 0,
		"Horizontal navigation did not return to the one-player option."
	):
		return
	_press_key(player_count_menu.keyboard_navigator, KEY_F)
	if not _expect(
		player_count_menu.visible and player_count_menu.showing_levels and paused,
		"Confirming a player count did not open level selection."
	):
		return
	_press_key(player_count_menu.keyboard_navigator, KEY_F)
	if not _expect(
		not player_count_menu.visible
		and manager.match_state == manager.MatchState.ACTIVE
		and manager.player_1_score == 0 and manager.player_2_score == 0
		and manager.player_1_sets == 0 and manager.player_2_sets == 0
		and manager.round_number == 1 and manager.match_winner == null,
		"Selecting a game mode did not reset the match to a fresh opening state."
	):
		return
	var saved_binding: InputEventKey = settings_manager.get_binding_event("player_1_left")
	var saved_config := ConfigFile.new()
	if not _expect(
		saved_binding.physical_keycode == KEY_Z
		and saved_config.load(SETTINGS_PATH) == OK
		and int(saved_config.get_value("bindings", "player_1_left", 0)) == KEY_Z,
		"Restart changed the active or persisted control binding."
	):
		return
	if not _expect(not paused and not pause_menu.visible, "Confirmed restart left the menu or game paused."):
		return

	print("Restart confirmation, player-count selection, horizontal navigation, full match reset, and saved-control retention verified.")
	_remove_test_file()
	quit()


func _escape_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	return event


func _press_key(navigator: MenuKeyboardNavigator, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	navigator._input(event)
	await process_frame


func _remove_test_file() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(SETTINGS_PATH)
