extends Node

signal settings_recovered(reason: String)

const SETTINGS_VERSION := 1
const SETTINGS_PATH := "user://controls.cfg"
const SETTINGS_SECTION := "settings"
const BINDINGS_SECTION := "bindings"

const CONFIGURABLE_ACTIONS: Array[String] = [
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

const DEFAULT_PHYSICAL_KEYS: Dictionary = {
	"player_1_left": KEY_A,
	"player_1_right": KEY_D,
	"player_1_up": KEY_W,
	"player_1_down": KEY_S,
	"player_1_jump": KEY_F,
	"player_1_dash": KEY_G,
	"player_1_accelerate": KEY_H,
	"player_2_left": KEY_LEFT,
	"player_2_right": KEY_RIGHT,
	"player_2_up": KEY_UP,
	"player_2_down": KEY_DOWN,
	"player_2_jump": KEY_1,
	"player_2_dash": KEY_2,
	"player_2_accelerate": KEY_3,
}

const RESERVED_KEYS: Array[int] = [
	KEY_ESCAPE,
	KEY_F1,
	KEY_F2,
	KEY_F3,
	KEY_F4,
	KEY_F5,
	KEY_F6,
	KEY_F7,
	KEY_F8,
	KEY_F9,
	KEY_F10,
	KEY_F11,
	KEY_F12,
	KEY_SHIFT,
	KEY_CTRL,
	KEY_ALT,
	KEY_META,
]

var settings_path: String = SETTINGS_PATH
var current_bindings: Dictionary = {}


func _enter_tree() -> void:
	load_or_restore_settings()


func validate_binding(
	action_name: String,
	event: InputEvent,
	candidate_bindings: Dictionary = {}
) -> Dictionary:
	if not CONFIGURABLE_ACTIONS.has(action_name) or not InputMap.has_action(action_name):
		return _invalid("Unknown control action.")
	if not event is InputEventKey:
		return _invalid("Only keyboard keys can be assigned.")

	var key_event := event as InputEventKey
	var physical_key := int(key_event.physical_keycode)
	if physical_key == 0:
		return _invalid("This key has no physical keyboard code.")
	if RESERVED_KEYS.has(physical_key):
		return _invalid("This key is reserved and cannot be assigned.")
	if key_event.shift_pressed or key_event.ctrl_pressed or key_event.alt_pressed or key_event.meta_pressed:
		return _invalid("Modified shortcuts cannot be assigned.")

	for other_action: String in CONFIGURABLE_ACTIONS:
		if other_action == action_name or not InputMap.has_action(other_action):
			continue
		var current_key := _get_physical_key(other_action)
		if candidate_bindings.has(other_action):
			var other_event: Variant = candidate_bindings[other_action]
			if other_event is InputEventKey:
				current_key = int(other_event.physical_keycode)
		if current_key == physical_key:
			return {
				"valid": false,
				"reason": "This key is already assigned to %s." % other_action,
				"conflicting_action": other_action,
			}

	return {"valid": true, "reason": "", "conflicting_action": ""}


func try_set_binding(action_name: String, event: InputEvent) -> Dictionary:
	var result := validate_binding(action_name, event)
	if not result.valid:
		return result

	var previous_event := _get_binding_event(action_name)
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, event.duplicate())
	current_bindings[action_name] = event.duplicate()
	var save_error := _save_bindings()
	if save_error != OK:
		_restore_binding(action_name, previous_event)
		return _invalid("Could not save the control settings.")
	return result


func load_or_restore_settings() -> bool:
	var config := ConfigFile.new()
	var load_error := config.load(settings_path)
	if load_error != OK:
		_restore_default_bindings("Settings were missing or unreadable; defaults were restored.")
		return false
	if not config.has_section_key(SETTINGS_SECTION, "version"):
		_restore_default_bindings("Settings version is missing; defaults were restored.")
		return false
	if int(config.get_value(SETTINGS_SECTION, "version", -1)) != SETTINGS_VERSION:
		_restore_default_bindings("Settings version is unsupported; defaults were restored.")
		return false

	var candidate_bindings: Dictionary = {}
	for action_name: String in CONFIGURABLE_ACTIONS:
		if not config.has_section_key(BINDINGS_SECTION, action_name):
			_restore_default_bindings("Settings were incomplete; defaults were restored.")
			return false
		var stored_key: Variant = config.get_value(BINDINGS_SECTION, action_name)
		if typeof(stored_key) != TYPE_INT or int(stored_key) <= 0:
			_restore_default_bindings("Settings contained an invalid key; defaults were restored.")
			return false
		candidate_bindings[action_name] = _event_for_physical_key(int(stored_key))

	for action_name: String in CONFIGURABLE_ACTIONS:
		var result := validate_binding(
			action_name,
			candidate_bindings[action_name],
			candidate_bindings
		)
		if not result.valid:
			_restore_default_bindings(
				"Settings contained a prohibited or duplicate key; defaults were restored."
			)
			return false

	_apply_bindings(candidate_bindings)
	return true


func restore_default_bindings() -> Dictionary:
	var previous_bindings := _read_current_bindings()
	var defaults := _build_default_bindings()
	_apply_bindings(defaults)
	var save_error := _save_bindings()
	if save_error != OK:
		_apply_bindings(previous_bindings)
		return _invalid("Could not save the default control settings.")
	return {"valid": true, "reason": "Default controls restored.", "conflicting_action": ""}


func get_binding_event(action_name: String) -> InputEventKey:
	var event := _get_binding_event(action_name)
	return event as InputEventKey


func _restore_default_bindings(reason: String) -> void:
	_apply_bindings(_build_default_bindings())
	settings_recovered.emit(reason)
	if _save_bindings() != OK:
		settings_recovered.emit("Defaults are active but could not be saved.")


func _build_default_bindings() -> Dictionary:
	var defaults: Dictionary = {}
	for action_name: String in CONFIGURABLE_ACTIONS:
		defaults[action_name] = _event_for_physical_key(DEFAULT_PHYSICAL_KEYS[action_name])
	return defaults


func _read_current_bindings() -> Dictionary:
	var bindings: Dictionary = {}
	for action_name: String in CONFIGURABLE_ACTIONS:
		bindings[action_name] = _get_binding_event(action_name)
	return bindings


func _apply_bindings(bindings: Dictionary) -> void:
	for action_name: String in CONFIGURABLE_ACTIONS:
		if not bindings.has(action_name) or not InputMap.has_action(action_name):
			continue
		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, bindings[action_name].duplicate())
	current_bindings = bindings.duplicate(true)


func _save_bindings() -> Error:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, "version", SETTINGS_VERSION)
	for action_name: String in CONFIGURABLE_ACTIONS:
		var event := _get_binding_event(action_name)
		if event == null:
			return ERR_INVALID_DATA
		config.set_value(BINDINGS_SECTION, action_name, int(event.physical_keycode))
	return config.save(settings_path)


func _get_binding_event(action_name: String) -> InputEvent:
	if not InputMap.has_action(action_name):
		return null
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			return event.duplicate()
	return null


func _event_for_physical_key(physical_key: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical_key
	return event


func _restore_binding(action_name: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action_name)
	if event != null:
		InputMap.action_add_event(action_name, event)
	current_bindings[action_name] = event


func _get_physical_key(action_name: String) -> int:
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode != 0:
			return int(event.physical_keycode)
	return 0


func _invalid(reason: String) -> Dictionary:
	return {"valid": false, "reason": reason, "conflicting_action": ""}
