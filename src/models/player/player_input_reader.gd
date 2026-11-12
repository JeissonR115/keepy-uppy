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


func vertical_intent() -> float:
	return get_axis(PlayerActionCatalog.ACTION_UP, PlayerActionCatalog.ACTION_DOWN)


func is_just_pressed(action_suffix: String) -> bool:
	return Input.is_action_just_pressed(PlayerActionCatalog.action_name(input_prefix, action_suffix))


func is_pressed(action_suffix: String) -> bool:
	return Input.is_action_pressed(PlayerActionCatalog.action_name(input_prefix, action_suffix))


func is_just_released(action_suffix: String) -> bool:
	return Input.is_action_just_released(PlayerActionCatalog.action_name(input_prefix, action_suffix))


func horizontal_intent(bot_enabled: bool, bot_active: bool, cpu_intent: float) -> float:
	if not bot_enabled:
		return get_axis(PlayerActionCatalog.ACTION_LEFT, PlayerActionCatalog.ACTION_RIGHT)
	return cpu_intent if bot_active else 0.0


func dash_direction(
	horizontal_input: float,
	bot_enabled: bool,
	bot_active: bool,
	cpu_direction: Vector2
) -> Vector2:
	if bot_enabled:
		return cpu_direction if bot_active else Vector2.ZERO
	return Vector2(
		horizontal_input,
		get_axis(PlayerActionCatalog.ACTION_UP, PlayerActionCatalog.ACTION_DOWN)
	)


func dash_requested(bot_enabled: bool, bot_active: bool, cpu_requested: bool) -> bool:
	return bot_active and cpu_requested if bot_enabled else is_just_pressed(PlayerActionCatalog.ACTION_DASH)


func jump_requested(
	bot_enabled: bool,
	bot_active: bool,
	grounded: bool,
	cpu_requested: bool
) -> bool:
	return bot_active and grounded and cpu_requested if bot_enabled else is_just_pressed(PlayerActionCatalog.ACTION_JUMP)


func jump_held(bot_enabled: bool, bot_active: bool, variable_jump_timer: float) -> bool:
	return bot_active and variable_jump_timer > 0.0 if bot_enabled else is_pressed(PlayerActionCatalog.ACTION_JUMP)
