class_name PlayerJumpTechniques
extends RefCounted

static func update_variable_jump(
	player: CharacterBody2D,
	delta: float,
	jump_held: bool,
	jump_cut_multiplier: float
) -> void:
	var jump_timer: float = player.get("var_jump_timer")
	if jump_timer <= 0.0:
		return
	if not jump_held:
		var released_velocity := player.velocity
		if released_velocity.y < 0.0:
			released_velocity.y *= jump_cut_multiplier
			player.velocity = released_velocity
		player.set("var_jump_timer", 0.0)
		return
	var velocity := player.velocity
	velocity.y = minf(velocity.y, float(player.get("var_jump_speed")))
	player.velocity = velocity
	player.set("var_jump_timer", maxf(jump_timer - delta, 0.0))
