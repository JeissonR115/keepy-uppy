class_name MenuKeyboardNavigator
extends Node

signal moved(direction: int)
signal confirmed
signal cancelled

var enabled: bool = false
var movement_enabled: bool = true
var confirm_enabled: bool = true
var cancel_enabled: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if not enabled or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var prefix := PlayerActionCatalog.PLAYER_ONE_PREFIX
	if movement_enabled and _matches_action(key_event, prefix, PlayerActionCatalog.ACTION_UP, KEY_W):
		moved.emit(-1)
	elif movement_enabled and _matches_action(key_event, prefix, PlayerActionCatalog.ACTION_DOWN, KEY_S):
		moved.emit(1)
	elif confirm_enabled and _matches_action(key_event, prefix, PlayerActionCatalog.ACTION_JUMP, KEY_F):
		confirmed.emit()
	elif cancel_enabled and _matches_action(key_event, prefix, PlayerActionCatalog.ACTION_DASH, KEY_G):
		cancelled.emit()
	else:
		return
	get_viewport().set_input_as_handled()


func _matches_action(event: InputEventKey, prefix: String, suffix: String, fallback_key: int) -> bool:
	return (
		event.is_action_pressed(PlayerActionCatalog.action_name(prefix, suffix))
		or event.physical_keycode == fallback_key
		or event.keycode == fallback_key
	)
