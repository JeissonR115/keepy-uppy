class_name PlayerDashTechniques
extends RefCounted

static func handle_contacts(player: CharacterBody2D, tuning: Script) -> void:
	var dash_direction: Vector2 = player.get("dash_direction")
	var dash_velocity: Vector2 = player.get("dash_velocity")
	var dash_ultra_triggered: bool = player.get("dash_ultra_triggered")
	var jump_buffer_timer: float = player.get("jump_buffer_timer")
	var ducking: bool = player.get("ducking")
	var facing_direction: Vector2 = player.get("facing_direction")
	var velocity := player.velocity
	if dash_direction.y > 0.0 and player.is_on_floor():
		if not is_zero_approx(dash_direction.x) and not dash_ultra_triggered:
			dash_velocity.x *= tuning.ULTRA_MULT
			dash_velocity.y = 0.0
			dash_ultra_triggered = true
			player.call("_set_ducking", true)
			velocity = dash_velocity
		elif is_zero_approx(dash_direction.x):
			player.call("_set_ducking", true)
		player.set("dash_velocity", dash_velocity)
		player.set("dash_ultra_triggered", dash_ultra_triggered)
		player.velocity = velocity

	if jump_buffer_timer <= 0.0:
		return
	if dash_direction.is_equal_approx(Vector2.UP):
		var wall_direction: float = player.call("_wall_direction_within", tuning.WALL_CHECK_DIST)
		if wall_direction != 0.0:
			player.velocity = Vector2(
				tuning.SUPER_WALL_JUMP_H * wall_direction,
				tuning.SUPER_WALL_JUMP_SPEED
			)
			player.set("var_jump_timer", tuning.SUPER_WALL_JUMP_VAR_TIME)
			player.set("var_jump_speed", tuning.SUPER_WALL_JUMP_SPEED)
			player.set("force_move_x", wall_direction)
			player.set("force_move_timer", tuning.SUPER_WALL_JUMP_FORCE_TIME)
			player.call("_set_ducking", false)
			player.set("jump_buffer_timer", 0.0)
			player.call("_end_dash", false)
			_play_jump(player)
			return

	if not player.is_on_floor():
		return
	if ducking:
		velocity.x = tuning.SUPER_JUMP_H * signf(facing_direction.x)
		velocity.x *= tuning.DUCK_SUPER_X_MULT
		velocity.y = tuning.JUMP_SPEED * tuning.DUCK_SUPER_Y_MULT
		player.velocity = velocity
		player.call("_set_ducking", false)
		player.set("jump_buffer_timer", 0.0)
		player.call("_end_dash", false)
		_play_jump(player)
	elif is_zero_approx(dash_direction.y):
		player.velocity = Vector2(
			tuning.SUPER_JUMP_H * signf(facing_direction.x),
			tuning.JUMP_SPEED
		)
		player.set("jump_buffer_timer", 0.0)
		player.call("_end_dash", false)
		_play_jump(player)

static func try_corner_correction(
	player: CharacterBody2D,
	dash_direction: Vector2,
	delta: float,
	previous_velocity: Vector2,
	correction_distance: float
) -> bool:
	if player.get_slide_collision_count() == 0:
		return false
	var perpendicular := Vector2(-dash_direction.y, dash_direction.x)
	var forward_step := dash_direction * minf(previous_velocity.length() * delta, 1.0)
	for offset in range(1, int(correction_distance) + 1):
		for direction in [-1.0, 1.0]:
			var correction: Vector2 = perpendicular * offset * direction
			if player.test_move(player.global_transform, correction):
				continue
			var candidate_transform := player.global_transform
			candidate_transform.origin += correction
			if player.test_move(candidate_transform, forward_step):
				continue
			player.global_transform = candidate_transform
			player.velocity = previous_velocity
			return true
	return false

static func wall_direction_within(player: CharacterBody2D, distance: float) -> float:
	for direction in [-1.0, 1.0]:
		if player.test_move(player.global_transform, Vector2(direction * distance, 0.0)):
			return -direction
	return 0.0

static func begin_dash(player: CharacterBody2D, tuning: Script) -> void:
	player.get("presentation").reset_footsteps()
	player.set("dash_timer", tuning.DASH_TIME)
	var dash_direction: Vector2 = player.get("dash_direction")
	player.set("dash_velocity", dash_direction * tuning.DASH_SPEED)
	var audio_manager: Node = player.get("audio_manager")
	audio_manager.call("play_local_action", "dash", player.global_position, player.is_multiplayer_authority())
	player.set("is_dashing", true)
	player.set("dash_rescue_hit", false)
	var rescue_area: Area2D = player.get("dash_rescue_area")
	rescue_area.position = Vector2.ZERO
	rescue_area.rotation = dash_direction.angle()
	rescue_area.monitoring = true

static func end_dash(
	player: CharacterBody2D,
	tuning: Script,
	apply_exit_velocity: bool = true
) -> void:
	if apply_exit_velocity:
		var dash_direction: Vector2 = player.get("dash_direction")
		var velocity: Vector2 = dash_direction * tuning.END_DASH_SPEED
		if velocity.y < 0.0:
			velocity.y *= tuning.END_DASH_UP_MULT
		player.velocity = velocity
	player.set("dash_timer", 0.0)
	player.set("is_dashing", false)
	player.set("movement_state", 0)
	var rescue_area: Area2D = player.get("dash_rescue_area")
	rescue_area.monitoring = false

static func set_ducking(
	player: CharacterBody2D,
	tuning: Script,
	active: bool
) -> void:
	if bool(player.get("ducking")) == active:
		return
	player.set("ducking", active)
	var collision_shape: CollisionShape2D = player.get("player_collision_shape")
	var capsule := collision_shape.shape as CapsuleShape2D
	var normal_height: float = player.get("normal_collision_height")
	if active:
		capsule.height = normal_height - tuning.DUCK_COLLISION_HEIGHT_REDUCTION
		collision_shape.position.y = tuning.DUCK_COLLISION_HEIGHT_REDUCTION * 0.5
	else:
		capsule.height = normal_height
		collision_shape.position.y = 0.0

static func handle_rescue_body(player: CharacterBody2D, body: Node2D) -> void:
	if bool(player.get("dash_rescue_hit")) or not bool(player.get("is_dashing")):
		return
	if body is RigidBody2D and body.has_method("apply_dash_rescue"):
		var dash_direction: Vector2 = player.get("dash_direction")
		player.set("dash_rescue_hit", body.apply_dash_rescue(player, dash_direction))

static func report_player_collisions(player: CharacterBody2D) -> void:
	for index in player.get_slide_collision_count():
		var collider := player.get_slide_collision(index).get_collider()
		if collider is CharacterBody2D and collider.is_in_group("players"):
			player.emit_signal("player_bumped", player, collider, bool(player.get("is_dashing")))

static func _play_jump(player: CharacterBody2D) -> void:
	var audio_manager: Node = player.get("audio_manager")
	audio_manager.call(
		"play_local_action", "jump", player.global_position, player.is_multiplayer_authority(), 0.15
	)
