class_name PlayerClimbTechniques
extends RefCounted

const NORMAL_MOVEMENT_STATE := 0

static func climbable_wall_direction_within(
	player: CharacterBody2D,
	distance: float
) -> float:
	for direction in [-1.0, 1.0]:
		var collision := KinematicCollision2D.new()
		if player.test_move(
			player.global_transform, Vector2(direction * distance, 0.0), collision
		) and collision.get_collider() is Node and collision.get_collider().is_in_group("climbable_wall"):
			return -direction
	return 0.0

static func update_climb_state(
	player: CharacterBody2D,
	tuning: Script,
	vertical_input: float,
	delta: float
) -> void:
	var stamina: float = player.get("climb_stamina")
	var velocity := player.velocity
	velocity.x = 0.0
	if vertical_input < 0.0:
		velocity.y = tuning.CLIMB_UP_SPEED
		stamina = maxf(stamina - tuning.CLIMB_UP_COST * delta, 0.0)
	elif vertical_input > 0.0:
		velocity.y = tuning.CLIMB_DOWN_SPEED
	else:
		velocity.y = 0.0
		stamina = maxf(stamina - tuning.CLIMB_STILL_COST * delta, 0.0)
	player.velocity = velocity
	player.set("climb_stamina", stamina)

static func wall_slide_speed(tuning: Script, wall_slide_timer: float) -> float:
	return lerpf(
		tuning.WALL_SLIDE_START,
		tuning.MAX_FALL,
		clampf(wall_slide_timer / tuning.WALL_SLIDE_TIME, 0.0, 1.0)
	)

static func perform_wall_jump(
	player: CharacterBody2D,
	tuning: Script,
	wall_jump_direction: float,
	from_climb: bool
) -> void:
	if from_climb:
		player.set(
			"climb_stamina",
			maxf(float(player.get("climb_stamina")) - tuning.CLIMB_JUMP_COST, 0.0)
		)
	player.set("movement_state", NORMAL_MOVEMENT_STATE)
	player.velocity = Vector2(
		tuning.WALL_JUMP_H * wall_jump_direction,
		tuning.JUMP_SPEED
	)
	player.set("var_jump_timer", tuning.VAR_JUMP_TIME)
	player.set("var_jump_speed", tuning.JUMP_SPEED)
	player.set("force_move_x", wall_jump_direction)
	player.set("force_move_timer", tuning.WALL_JUMP_FORCE_TIME)
	player.set("jump_buffer_timer", 0.0)
	player.set("coyote_timer", 0.0)
	player.call("_set_ducking", false)
	var audio_manager: Node = player.get("audio_manager")
	audio_manager.call(
		"play_local_action", "jump", player.global_position, player.is_multiplayer_authority()
	)
