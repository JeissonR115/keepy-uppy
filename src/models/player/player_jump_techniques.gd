class_name PlayerJumpTechniques
extends RefCounted

static func update_variable_jump(
	player: CharacterBody2D,
	delta: float,
	jump_held: bool
) -> void:
	var jump_timer: float = player.get("var_jump_timer")
	if jump_timer <= 0.0:
		return
	if not jump_held:
		player.set("var_jump_timer", 0.0)
		return
	var velocity := player.velocity
	velocity.y = minf(velocity.y, float(player.get("var_jump_speed")))
	player.velocity = velocity
	player.set("var_jump_timer", maxf(jump_timer - delta, 0.0))
