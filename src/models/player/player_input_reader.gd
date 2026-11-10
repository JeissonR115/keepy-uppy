class_name PlayerInputReader
extends Node

var input_prefix: String = PlayerActionCatalog.PLAYER_ONE_PREFIX


func configure(prefix: String) -> void:
	input_prefix = prefix


func get_axis(negative_action: String, positive_action: String) -> float:
	return Input.get_axis(
		PlayerActionCatalog.action_name(input_prefix, negative_action),
		PlayerActionCatalog.action_name(input_prefix, positive_action)
	)


func is_just_pressed(action_suffix: String) -> bool:
	return Input.is_action_just_pressed(PlayerActionCatalog.action_name(input_prefix, action_suffix))


func is_pressed(action_suffix: String) -> bool:
	return Input.is_action_pressed(PlayerActionCatalog.action_name(input_prefix, action_suffix))


func is_just_released(action_suffix: String) -> bool:
	return Input.is_action_just_released(PlayerActionCatalog.action_name(input_prefix, action_suffix))
