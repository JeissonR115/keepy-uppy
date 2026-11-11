extends SceneTree

const SETTINGS_MANAGER := preload("res://src/managers/control_settings_manager.gd")
const TEST_SETTINGS_PATH := "/tmp/keepy-controls-test.cfg"


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
	var manager: Node = SETTINGS_MANAGER.new()
	manager.settings_path = TEST_SETTINGS_PATH
	if not _expect(not manager.load_or_restore_settings(), "Missing settings were reported as valid."):
		return
	if not _expect(_has_key("player_1_left", KEY_A), "Missing settings did not restore P1 defaults."):
		return
	if not _expect(_has_key("player_1_grab", KEY_R), "Missing settings did not restore P1 Grab."):
		return
	if not _expect(_has_key("player_2_grab", KEY_4), "Missing settings did not restore P2 Grab."):
		return

	var custom_key := _key_event(KEY_Z)
	var set_result: Dictionary = manager.try_set_binding("player_1_left", custom_key)
	if not _expect(set_result.valid, "A valid binding was not saved: %s" % set_result.reason):
		return
	var reloaded_manager: Node = SETTINGS_MANAGER.new()
	reloaded_manager.settings_path = TEST_SETTINGS_PATH
	if not _expect(reloaded_manager.load_or_restore_settings(), "A complete saved map was rejected."):
		return
	if not _expect(_has_key("player_1_left", KEY_Z), "A valid binding did not survive reload."):
		return
	var legacy_config := ConfigFile.new()
	if not _expect(legacy_config.load(TEST_SETTINGS_PATH) == OK, "Could not load bindings for the legacy settings check."):
		return
	legacy_config.set_value("bindings", "player_1_accelerate", KEY_H)
	legacy_config.set_value("bindings", "player_2_accelerate", KEY_3)
	if not _expect(legacy_config.save(TEST_SETTINGS_PATH) == OK, "Could not write legacy accelerate bindings."):
		return
	if not _expect(reloaded_manager.load_or_restore_settings(), "Legacy saved boost keys prevented current controls from loading."):
		return
	if not _expect(not InputMap.has_action("player_1_accelerate") and not InputMap.has_action("player_2_accelerate"), "Legacy boost keys recreated removed Input Map actions."):
		return

	var config := ConfigFile.new()
	config.set_value("settings", "version", 1)
	config.set_value("bindings", "player_1_left", KEY_Z)
	if not _expect(config.save(TEST_SETTINGS_PATH) == OK, "Could not write the partial test configuration."):
		return
	if not _expect(not manager.load_or_restore_settings(), "An incomplete settings map was accepted."):
		return
	if not _expect(_has_key("player_1_left", KEY_A), "Incomplete settings did not restore defaults."):
		return
	if not _expect(_has_key("player_1_grab", KEY_R), "Recovery did not restore P1 Grab."):
		return
	if not _expect(_has_key("player_2_grab", KEY_4), "Recovery did not restore P2 Grab."):
		return

	config = ConfigFile.new()
	config.set_value("settings", "version", 1)
	config.set_value("bindings", "player_1_left", "not a physical key")
	if not _expect(config.save(TEST_SETTINGS_PATH) == OK, "Could not write the malformed test configuration."):
		return
	if not _expect(not manager.load_or_restore_settings(), "Malformed settings were accepted."):
		return
	if not _expect(_has_key("player_1_jump", KEY_F), "Malformed settings did not restore defaults."):
		return

	manager.restore_default_bindings()
	config = ConfigFile.new()
	if not _expect(config.load(TEST_SETTINGS_PATH) == OK, "Default settings were not rewritten."):
		return
	config.set_value("bindings", "player_1_right", KEY_A)
	config.save(TEST_SETTINGS_PATH)
	if not _expect(not manager.load_or_restore_settings(), "Duplicate saved bindings were accepted."):
		return
	if not _expect(_has_key("player_1_right", KEY_D), "Duplicate saved bindings did not restore defaults."):
		return

	manager.restore_default_bindings()
	config = ConfigFile.new()
	config.load(TEST_SETTINGS_PATH)
	config.set_value("bindings", "player_1_jump", KEY_F1)
	config.save(TEST_SETTINGS_PATH)
	if not _expect(not manager.load_or_restore_settings(), "A prohibited saved key was accepted."):
		return
	if not _expect(_has_key("player_1_jump", KEY_F), "Prohibited saved settings did not restore defaults."):
		return

	manager.free()
	reloaded_manager.free()
	_remove_test_file()
	print("Control settings save/load, round-trip, and full default recovery verified.")
	quit()


func _has_key(action_name: String, expected_key: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == expected_key:
			return true
	return false


func _key_event(key: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	return event


func _remove_test_file() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)
