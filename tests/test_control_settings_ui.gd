extends SceneTree

const TEST_SETTINGS_PATH := "/tmp/keepy-controls-keyboard-ui-test.cfg"
const ACTIONS: Array[String] = [
	"player_1_left", "player_1_right", "player_1_up", "player_1_down",
	"player_1_jump", "player_1_dash", "player_1_accelerate", "player_1_grab",
	"player_2_left", "player_2_right", "player_2_up", "player_2_down",
	"player_2_jump", "player_2_dash", "player_2_accelerate", "player_2_grab",
]


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
	settings_manager.settings_path = TEST_SETTINGS_PATH
	root.add_child(main_scene)
	await process_frame

	var scoreboard: CanvasLayer = main_scene.get_node("Arena/Scoreboard")
	var pause_menu: PauseMenu = scoreboard.get_node("PauseMenu")
	var screen: Control = scoreboard.get_node("ControlSettings")
	var player_count_menu: PlayerCountMenu = main_scene.get_node("PlayerCountMenu")
	if not _expect(
		player_count_menu.visible and not pause_menu.visible and not screen.visible and paused,
		"Player selection was not the only menu shown at startup."
	):
		return
	await _press_menu_key(player_count_menu.keyboard_navigator, KEY_S)
	await _press_menu_key(player_count_menu.keyboard_navigator, KEY_S)
	await _press_menu_key(player_count_menu.keyboard_navigator, KEY_F)
	if not _expect(
		screen.visible and not player_count_menu.visible and not pause_menu.visible and paused,
		"Keyboard Controls did not replace player selection as the only open menu."
	):
		return
	await _press_action("player_1_dash")
	if not _expect(
		player_count_menu.visible and not screen.visible and not pause_menu.visible and paused,
		"Closing Keyboard Controls did not return to the player-selection menu."
	):
		return
	scoreboard.call("_input", _escape_event())
	if not _expect(
		pause_menu.visible and not player_count_menu.visible and not screen.visible and paused,
		"Opening pause did not replace player selection as the only open menu."
	):
		return
	scoreboard.call("_input", _escape_event())
	if not _expect(
		player_count_menu.visible and not pause_menu.visible and not screen.visible and paused,
		"Closing pause did not restore the player-selection menu exclusively."
	):
		return
	player_count_menu._select_player_count(2)
	player_count_menu._select_level("classic")
	if not _expect(not paused and not player_count_menu.visible, "Selecting a mode did not start gameplay."):
		return
	scoreboard.call("_input", _escape_event())
	await _press_action("player_1_down")
	await _press_action("player_1_down")
	await _press_action("player_1_jump")
	if not _expect(
		screen.visible and not player_count_menu.visible and not pause_menu.visible
		and paused and pause_menu.current_screen == pause_menu.MenuScreen.CONTROLS
		and String(screen.get("captured_action")).is_empty(),
		"Player 1 could not open the controls submenu while keeping gameplay paused."
	):
		return

	var focus_order: Array = screen.get("focus_order")
	if not _expect(focus_order.size() == 19, "Not all control rows and settings actions are keyboard reachable."):
		return
	await _press_action("player_1_right")
	var player_2_left_button := screen.call("get_action_button", "player_2_left") as Button
	if not _expect(
		screen.get("focused_index") == 8 and player_2_left_button.has_focus(),
		"Right did not move from Player 1 Left to Player 2 Left in the same row."
	):
		return
	await _press_action("player_1_left")
	var player_1_left_button := screen.call("get_action_button", "player_1_left") as Button
	if not _expect(
		screen.get("focused_index") == 0 and player_1_left_button.has_focus(),
		"Left did not return to Player 1 Left in the same row."
	):
		return
	await _press_action("player_1_down")
	await _press_action("player_1_right")
	var player_2_right_button := screen.call("get_action_button", "player_2_right") as Button
	if not _expect(
		screen.get("focused_index") == 9 and player_2_right_button.has_focus(),
		"Horizontal navigation did not switch to Player 2's matching action row."
	):
		return
	await _press_action("player_1_left")
	await _press_action("player_1_up")
	if not _expect(
		screen.get("focused_index") == 0 and player_1_left_button.has_focus(),
		"Could not return to the first Player 1 action row after horizontal navigation."
	):
		return
	for index in range(ACTIONS.size()):
		var action_name := ACTIONS[index]
		var action_button := screen.call("get_action_button", action_name) as Button
		if not _expect(
			screen.get("focused_index") == index and action_button.has_focus() and not action_button.text.is_empty(),
			"Keyboard focus or displayed binding is missing for %s." % action_name
		):
			return
		await _press_action("player_1_jump")
		if not _expect(
			String(screen.get("captured_action")) == action_name,
			"Jump did not begin key capture for the focused row: %s." % action_name
		):
			return
		screen.call("_unhandled_key_input", _key_event(KEY_Z))
		if not _expect(
			String(screen.get("captured_action")).is_empty()
			and _has_key(action_name, KEY_Z)
			and not action_button.text.is_empty(),
			"Focused action did not rebind and update its label: %s." % action_name
		):
			return
		settings_manager.call("restore_default_bindings")
		screen.call("_refresh_action_buttons")
		if index < ACTIONS.size() - 1:
			await _press_action("player_1_down")

	# The Cancel Capture, Restore Defaults, and Back controls follow all sixteen rows.
	await _press_action("player_1_down")
	if not _expect(
		screen.get("focused_index") == 16 and (focus_order[16] as Button).has_focus(),
		"Cancel Capture is not reachable through Player 1 navigation."
	):
		return
	await _press_action("player_1_down")
	if not _expect(
		screen.get("focused_index") == 17 and (focus_order[17] as Button).has_focus(),
		"Restore Defaults is not reachable through Player 1 navigation."
	):
		return
	var custom_event := _key_event(KEY_Z)
	if not _expect(
		settings_manager.call("try_set_binding", "player_1_left", custom_event).valid,
		"Could not prepare a custom binding for the restore-defaults check."
	):
		return
	await _press_action("player_1_jump")
	if not _expect(_has_key("player_1_left", KEY_A), "Keyboard activation did not restore default bindings."):
		return
	await _press_action("player_1_down")
	if not _expect(
		screen.get("focused_index") == 18 and (focus_order[18] as Button).has_focus(),
		"Back to Pause is not reachable through Player 1 navigation."
	):
		return
	await _press_action("player_1_dash")
	if not _expect(
		pause_menu.visible and pause_menu.current_screen == pause_menu.MenuScreen.PAUSE and paused,
		"Dash did not return from controls to the still-paused menu."
	):
		return

	await _press_action("player_1_up")
	await _press_action("player_1_up")
	await _press_action("player_1_jump")
	if not _expect(not paused, "Player 1 could not resume after leaving control settings."):
		return

	# Reopen controls to cover conflict feedback and both capture-cancel routes.
	scoreboard.call("_input", _escape_event())
	await _press_action("player_1_down")
	await _press_action("player_1_down")
	await _press_action("player_1_jump")
	screen.call("_begin_capture", "player_1_left")
	screen.call("_unhandled_key_input", _key_event(KEY_D))
	var status_label := screen.get("status_label") as Label
	if not _expect(
		String(screen.get("captured_action")) == "player_1_left"
		and _has_key("player_1_left", KEY_A)
		and status_label.text.contains("already assigned"),
		"Duplicate key changed the current binding or failed to explain the conflict."
	):
		return
	await _press_action("player_1_dash")
	if not _expect(
		String(screen.get("captured_action")).is_empty() and _has_key("player_1_left", KEY_A),
		"Player 1 Dash did not cancel capture without changing the existing key."
	):
		return
	screen.call("_begin_capture", "player_1_left")
	scoreboard.call("_input", _escape_event())
	if not _expect(
		String(screen.get("captured_action")).is_empty() and _has_key("player_1_left", KEY_A),
		"Escape did not cancel key capture while preserving the current binding."
	):
		return
	scoreboard.call("_input", _escape_event())
	await process_frame
	scoreboard.call("_input", _escape_event())
	await process_frame
	if not _expect(not screen.visible and not paused, "Escape did not close the menu flow and resume gameplay."):
		return

	print("Keyboard navigation across sixteen rows and three actions, rebinding, conflict rejection, capture cancel, reset, pause return, and resume verified.")
	_remove_test_file()
	quit()


func _press_action(action_name: String) -> void:
	Input.action_press(action_name)
	await process_frame
	Input.action_release(action_name)
	await process_frame


func _press_menu_key(navigator: MenuKeyboardNavigator, key: Key) -> void:
	var event := _key_event(key)
	navigator._input(event)
	await process_frame


func _has_key(action_name: String, expected_key: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == expected_key:
			return true
	return false


func _key_event(key: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	return event


func _escape_event() -> InputEventKey:
	return _key_event(KEY_ESCAPE)


func _remove_test_file() -> void:
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(TEST_SETTINGS_PATH)
