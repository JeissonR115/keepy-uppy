class_name PlayerSurfaceTechniques
extends RefCounted

static func handle_trampoline_contacts(player: CharacterBody2D, tuning: Script) -> void:
	if not player.is_on_floor() or player.velocity.y < 0.0:
		return
	for index in player.get_slide_collision_count():
		var collision := player.get_slide_collision(index)
		var collider := collision.get_collider()
		if collider is Node and collider.is_in_group("trampoline") and collision.get_normal().y < -0.5:
			var velocity := player.velocity
			velocity.y = -tuning.TRAMPOLINE_BOUNCE_SPEED
			player.velocity = velocity
			player.set("var_jump_timer", 0.0)
			return

static func is_on_one_way_platform(player: CharacterBody2D) -> bool:
	for index in player.get_slide_collision_count():
		var collider := player.get_slide_collision(index).get_collider()
		if collider is Node and collider.is_in_group("one_way_platform"):
			return true
	return false

static func begin_platform_drop(
	player: CharacterBody2D,
	platform_layer_index: int,
	duration: float
) -> void:
	player.set("platform_drop_timer", duration)
	player.set_collision_mask_value(platform_layer_index, false)
	var velocity := player.velocity
	velocity.y = maxf(velocity.y, 60.0)
	player.velocity = velocity

static func update_ceiling_contact(
	player: CharacterBody2D,
	tuning: Script,
	delta: float,
	upward_speed: float
) -> void:
	if not player.is_on_ceiling() or upward_speed >= 0.0:
		player.set("ceiling_contact_timer", 0.0)
		return
	if try_ceiling_corner_correction(player, tuning, upward_speed):
		player.set("ceiling_contact_timer", 0.0)
		return
	var contact_timer := float(player.get("ceiling_contact_timer")) + delta
	player.set("ceiling_contact_timer", contact_timer)
	if contact_timer >= tuning.CEILING_JUMP_GRACE:
		player.set("var_jump_timer", 0.0)
		var velocity := player.velocity
		velocity.y = maxf(velocity.y, 0.0)
		player.velocity = velocity

static func try_ceiling_corner_correction(
	player: CharacterBody2D,
	tuning: Script,
	upward_speed: float
) -> bool:
	for offset in range(1, int(tuning.CEILING_CORNER_CORRECTION) + 1):
		for direction in [-1.0, 1.0]:
			var horizontal_offset := Vector2(direction * offset, 0.0)
			if player.test_move(player.global_transform, horizontal_offset + Vector2.UP):
				continue
			player.global_position += horizontal_offset
			var velocity := player.velocity
			velocity.y = upward_speed
			player.velocity = velocity
			return true
	return false
