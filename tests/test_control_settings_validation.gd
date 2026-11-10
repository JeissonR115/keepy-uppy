extends SceneTree

const SETTINGS_MANAGER := preload("res://src/managers/control_settings_manager.gd")


func _initialize() -> void:
	var manager: Node = SETTINGS_MANAGER.new()
	var original_left := InputMap.action_get_events("player_1_left")[0].duplicate()
	var duplicate_key := _key_event(KEY_A)
	var duplicate_result: Dictionary = manager.validate_binding("player_1_right", duplicate_key)
	assert(not duplicate_result.valid, "A key assigned to another action was accepted.")
	assert(
		duplicate_result.conflicting_action == "player_1_left",
		"Duplicate rejection did not identify the existing action."
	)
	manager.try_set_binding("player_1_right", duplicate_key)
	assert(
		InputMap.action_get_events("player_1_left")[0].physical_keycode == original_left.physical_keycode,
		"A rejected binding changed another action's live binding."
	)
	assert(
		InputMap.action_get_events("player_1_right")[0].physical_keycode == KEY_D,
		"A rejected binding changed the selected action's live binding."
	)

	for reserved_key: int in [KEY_ESCAPE, KEY_F1, KEY_F12, KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
		var result: Dictionary = manager.validate_binding("player_1_right", _key_event(reserved_key))
		assert(not result.valid, "A reserved key was accepted: %s" % reserved_key)

	var modified_event := _key_event(KEY_Q)
	modified_event.ctrl_pressed = true
	assert(
		not manager.validate_binding("player_1_right", modified_event).valid,
		"A modified shortcut was accepted."
	)

	var free_event := _key_event(KEY_Z)
	assert(manager.validate_binding("player_1_right", free_event).valid, "An unused key was rejected.")
	assert(not manager.validate_binding("missing_action", free_event).valid, "An unknown action was accepted.")
	manager.free()
	print("Reserved, modified, duplicate, and available key validation verified.")
	quit()


func _key_event(key: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	return event
