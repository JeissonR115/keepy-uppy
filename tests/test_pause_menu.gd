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
	_remove_test_file()
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	main_scene.get_node("ControlSettingsManager").settings_path = "/tmp/keepy-pause-controls.cfg"
	root.add_child(main_scene)
	await process_frame

	var arena: Node = main_scene.get_node("Arena")
	var manager: Node = arena.get_node("MatchManager")
	var player_1: CharacterBody2D = arena.get_node("Player1")
	var settings_manager: Node = main_scene.get_node("ControlSettingsManager")
	var scoreboard: CanvasLayer = arena.get_node("Scoreboard")
	var pause_menu: PauseMenu = scoreboard.get_node("PauseMenu")
	var controls: Control = scoreboard.get_node("ControlSettings")
	var player_count_menu: PlayerCountMenu = main_scene.get_node("PlayerCountMenu")
	if not _expect(
		player_count_menu.visible and paused,
		"Player-count selection was not the only menu open when the game started."
	):
		return
	if not _expect(
		pause_menu.get_node("PausePanel/Content/Options") is VBoxContainer,
		"Pause options are not laid out in a single vertical column."
	):
		return
	manager.player_1_score = 2
	var match_round_before: int = int(manager.round_number)
	var remapped_down := _key_event(KEY_K)
	if not _expect(
		settings_manager.try_set_binding("player_1_down", remapped_down).valid,
		"Could not prepare a remapped Player 1 menu key."
	):
		return

	scoreboard.call("_input", _escape_event())
	if not _expect(
		paused and pause_menu.visible and pause_menu.current_screen == pause_menu.MenuScreen.PAUSE,
		"Escape did not open the pause menu and pause gameplay."
	):
		return
	if not _expect(
		pause_menu.layer > scoreboard.layer,
		"Pause menu is not rendered above the HUD."
	):
		return
	if not _expect(
		not player_count_menu.visible and not player_count_menu.keyboard_navigator.enabled,
		"Pause did not replace and suspend the player-count menu."
	):
		return
	scoreboard.call("_input", _escape_event())
	if not _expect(
		player_count_menu.visible and not pause_menu.visible and paused,
		"Closing pause did not restore the startup player-count menu."
	):
		return
	player_count_menu._select_player_count(2)
	if not _expect(not paused, "Selecting a mode did not resume gameplay."):
		return
	scoreboard.call("_input", _escape_event())
	if not _expect(
		pause_menu.visible and not player_count_menu.visible and paused,
		"Pause did not open exclusively during gameplay."
	):
		return
	remapped_down.pressed = true
	Input.parse_input_event(remapped_down)
	await process_frame
	remapped_down.pressed = false
	Input.parse_input_event(remapped_down)
	await process_frame
	if not _expect(
		pause_menu.selected_index == 1,
		"The remapped Player 1 Down action did not select Restart."
	):
		return
	settings_manager.restore_default_bindings()
	Input.action_press("player_1_left")
	await process_frame
	Input.action_release("player_1_left")
	Input.action_press("player_1_right")
	await process_frame
	Input.action_release("player_1_right")
	if not _expect(
		pause_menu.selected_index == 1,
		"Left or Right changed the selection in the single-column pause menu."
	):
		return
	Input.action_press("player_1_up")
	await process_frame
	Input.action_release("player_1_up")
	if not _expect(pause_menu.selected_index == 0, "Up did not select Resume in the single-column menu."):
		return
	Input.action_press("player_1_down")
	await process_frame
	Input.action_release("player_1_down")
	Input.action_press("player_1_down")
	await process_frame
	Input.action_release("player_1_down")
	if not _expect(
		pause_menu.selected_index == 2,
		"Down did not navigate through the single-column pause options."
	):
		return
	Input.action_press("player_1_left")
	await process_frame
	Input.action_release("player_1_left")
	if not _expect(
		pause_menu.selected_index == 2,
		"Left changed the selection in the single-column pause menu."
	):
		return
	Input.action_press("player_1_up")
	await process_frame
	Input.action_release("player_1_up")
	if not _expect(pause_menu.selected_index == 1, "Up did not select Restart."):
		return
	Input.action_press("player_1_jump")
	await process_frame
	Input.action_release("player_1_jump")
	if not _expect(
		pause_menu.current_screen == pause_menu.MenuScreen.RESTART_CONFIRMATION
		and pause_menu.selected_index == 1
		and pause_menu.get_confirmation_button("NO, GO BACK").has_focus(),
		"Restart confirmation did not open with No selected by default."
	):
		return
	Input.action_press("player_1_dash")
	await process_frame
	Input.action_release("player_1_dash")
	if not _expect(
		pause_menu.current_screen == pause_menu.MenuScreen.PAUSE
		and paused and manager.player_1_score == 2,
		"Cancelling restart changed the match state or left the pause menu."
	):
		return

	Input.action_press("player_1_left")
	await process_frame
	Input.action_release("player_1_left")
	Input.action_press("player_1_down")
	await process_frame
	Input.action_release("player_1_down")
	Input.action_press("player_1_jump")
	await process_frame
	Input.action_release("player_1_jump")
	if not _expect(
		controls.visible and paused and String(controls.get("captured_action")).is_empty(),
		"Controls option did not open while keeping gameplay paused without capturing the confirm key."
	):
		return
	var player_position_before := player_1.global_position
	Input.action_press("player_1_right")
	await physics_frame
	Input.action_release("player_1_right")
	if not _expect(
		player_1.global_position == player_position_before,
		"Player movement continued while a pause submenu was open."
	):
		return
	controls.call("close")
	await process_frame
	if not _expect(
		pause_menu.visible and pause_menu.current_screen == pause_menu.MenuScreen.PAUSE and paused,
		"Returning from controls did not restore the paused menu."
	):
		return
	scoreboard.call("_input", _escape_event())
	await process_frame
	if not _expect(not paused and not pause_menu.visible, "Escape did not resume gameplay from the pause menu."):
		return
	if not _expect(manager.round_number == match_round_before, "Pause/resume changed the current match round."):
		return

	print("Escape pause/resume, Player 1 navigation, safe restart cancellation, controls entry, and gameplay isolation verified.")
	_remove_test_file()
	quit()


func _escape_event() -> InputEventKey:
	return _key_event(KEY_ESCAPE, true)


func _key_event(key: Key, is_pressed: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = is_pressed
	return event


func _remove_test_file() -> void:
	var settings_path := "/tmp/keepy-pause-controls.cfg"
	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_path)
