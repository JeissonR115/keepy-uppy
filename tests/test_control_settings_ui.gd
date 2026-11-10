extends SceneTree

const TEST_SETTINGS_PATH := "/tmp/keepy-controls-ui-test.cfg"
const ACTIONS: Array[String] = [
	"player_1_left",
	"player_1_right",
	"player_1_up",
	"player_1_down",
	"player_1_jump",
	"player_1_dash",
	"player_1_accelerate",
	"player_2_left",
	"player_2_right",
	"player_2_up",
	"player_2_down",
	"player_2_jump",
	"player_2_dash",
	"player_2_accelerate",
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

	var screen: Control = main_scene.get_node("Arena/Scoreboard/ControlSettings")
	var controls_button: Button = main_scene.get_node("Arena/Scoreboard/HUD/ControlsButton")
	controls_button.emit_signal("pressed")
	await process_frame
	if not _expect(screen.visible and paused, "Controls button did not open the screen and pause gameplay."):
		return
	for action_name: String in ACTIONS:
		var action_button := screen.call("get_action_button", action_name) as Button
		if not _expect(action_button != null, "Action row is missing: %s" % action_name):
			return
		if not _expect(not action_button.text.is_empty(), "Current binding is not displayed: %s" % action_name):
			return
		screen.call("_begin_capture", action_name)
		screen.call("_unhandled_key_input", _key_event(KEY_Z))
		if not _expect(
			String(screen.get("captured_action")).is_empty() and _has_key(action_name, KEY_Z),
			"Selected action did not receive its new key: %s" % action_name
		):
			return
		if not _expect(not action_button.text.is_empty(), "Updated key is not displayed: %s" % action_name):
			return
		settings_manager.call("restore_default_bindings")
		screen.call("_refresh_action_buttons")

	screen.call("_begin_capture", "player_1_left")
	screen.call("_unhandled_key_input", _key_event(KEY_D))
	var status_label := screen.get("status_label") as Label
	if not _expect(
		String(screen.get("captured_action")) == "player_1_left"
		and _has_key("player_1_left", KEY_A)
		and status_label.text.contains("already assigned"),
		"Duplicate key changed the binding, ended capture, or failed to explain the conflict."
	):
		return
	screen.call("_unhandled_key_input", _key_event(KEY_ESCAPE))
	if not _expect(
		String(screen.get("captured_action")).is_empty()
		and _has_key("player_1_left", KEY_A),
		"Escape did not cancel capture while preserving the previous key."
	):
		return
	screen.call("_begin_capture", "player_1_left")
	(screen.get("cancel_button") as Button).emit_signal("pressed")
	if not _expect(
		String(screen.get("captured_action")).is_empty() and _has_key("player_1_left", KEY_A),
		"Cancel button did not preserve the previous binding."
	):
		return

	var custom_event := _key_event(KEY_Z)
	var set_result: Dictionary = settings_manager.call("try_set_binding", "player_1_left", custom_event)
	if not _expect(set_result.valid, "Could not prepare a custom key for the reset check."):
		return

	screen.call("_restore_defaults")
	if not _expect(_has_key("player_1_left", KEY_A), "Restore defaults did not restore P1's key."):
		return
	screen.call("close")
	await process_frame
	if not _expect(not screen.visible and not paused, "Closing controls did not resume gameplay."):
		return

	print("Fourteen control rows, rebinding, conflict rejection, cancellation, reset, and pause/resume verified.")
	_remove_test_file()
	quit()


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


func _remove_test_file() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)
