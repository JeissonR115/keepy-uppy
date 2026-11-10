extends Node

var input_prefix: String = "player_1"


func configure(prefix: String) -> void:
	input_prefix = prefix


func get_axis(negative_action: String, positive_action: String) -> float:
	return Input.get_axis(
		"%s_%s" % [input_prefix, negative_action],
		"%s_%s" % [input_prefix, positive_action]
	)


func is_just_pressed(action_suffix: String) -> bool:
	return Input.is_action_just_pressed("%s_%s" % [input_prefix, action_suffix])


func is_just_released(action_suffix: String) -> bool:
	return Input.is_action_just_released("%s_%s" % [input_prefix, action_suffix])
