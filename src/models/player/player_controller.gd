class_name PlayerController
extends CharacterBody2D

signal player_bumped(player: CharacterBody2D, opponent: CharacterBody2D, while_dashing: bool)

enum MovementState { NORMAL, DASH, CLIMB }

const TOUCH_PIXEL_LIFETIME := 2.0
const TOUCH_PIXEL_HALF_SIZE := 2.0
const STEP_DISTANCE := 14.0
const PLATFORM_DROP_DURATION := 0.28
const PLATFORM_COLLISION_LAYER_INDEX := 3
const MovementConstants = preload("res://src/models/player/player_movement_constants.gd")

@export_enum("player_1", "player_2") var input_prefix: String = "player_1"
@export var bot_enabled: bool = false
@export var dash_rescue_half_extents: Vector2 = Vector2(22.0, 10.0)
var arena_speed_multiplier: float = 1.0

var idle_color: Color
var run_color: Color
var rise_color: Color
var fall_color: Color
var dash_color: Color
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var platform_drop_timer: float = 0.0
var var_jump_timer: float = 0.0
var var_jump_speed: float = 0.0
var ceiling_contact_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var run_animation_time: float = 0.0
var step_distance: float = 0.0
var wall_slide_timer: float = 0.0
var climb_stamina: float = MovementConstants.CLIMB_MAX_STAMINA
var tired_blink_timer: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var dash_velocity: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.RIGHT
var movement_state: MovementState = MovementState.NORMAL
var dash_freeze_timer: float = 0.0
var dash_refill_cooldown_timer: float = 0.0
var dash_available: bool = true
var dash_ultra_triggered: bool = false
var ducking: bool = false
var force_move_x: float = 0.0
var force_move_timer: float = 0.0
var is_dashing: bool = false
var dash_rescue_hit: bool = false
var normal_collision_height: float = 0.0

@onready var visual: Polygon2D = $Visual
@onready var priority_indicator: Polygon2D = $PriorityIndicator
@onready var player_collision_shape: CollisionShape2D = $CollisionShape2D
@onready var input_reader: PlayerInputReader = $InputReader
@onready var cpu_controller: CPUController = $CPUController
@onready var audio_manager: Node = get_node("/root/AudioManager")
@onready var match_manager: MatchManager = get_parent().get_node("MatchManager")
@onready var balloon: BalloonController = get_parent().get_node("Balloon")
@onready var dash_rescue_area: Area2D = $DashRescueArea
@onready var dash_rescue_shape: CollisionShape2D = $DashRescueArea/CollisionShape2D
@onready var cape_anchor_a: Marker2D = $CapeAnchors/AnchorA
@onready var cape_anchor_b: Marker2D = $CapeAnchors/AnchorB
@onready var cape: PlayerCape = $Cape


func _ready() -> void:
	input_reader.configure(input_prefix)
	idle_color = PlayerActionCatalog.player_color(input_prefix)
	if input_prefix == PlayerActionCatalog.PLAYER_ONE_PREFIX:
		run_color = Color(0.470588, 0.890196, 0.945098)
		rise_color = Color(0.772549, 0.960784, 0.980392)
		fall_color = Color(0.172549, 0.537255, 0.607843)
	else:
		run_color = Color(1.0, 0.780392, 0.466667)
		rise_color = Color(1.0, 0.898039, 0.729412)
		fall_color = Color(0.690196, 0.286275, 0.270588)
	dash_color = Color.WHITE
	visual.color = idle_color
	var capsule := player_collision_shape.shape.duplicate() as CapsuleShape2D
	player_collision_shape.shape = capsule
	normal_collision_height = capsule.height
	var rescue_rectangle := dash_rescue_shape.shape as RectangleShape2D
	rescue_rectangle.size = dash_rescue_half_extents * 2.0
	dash_rescue_area.monitoring = false
	dash_rescue_area.body_entered.connect(_on_dash_rescue_area_body_entered)


func reset_for_round(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	movement_state = MovementState.NORMAL
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	platform_drop_timer = 0.0
	set_collision_mask_value(PLATFORM_COLLISION_LAYER_INDEX, true)
	var_jump_timer = 0.0
	var_jump_speed = 0.0
	ceiling_contact_timer = 0.0
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	dash_freeze_timer = 0.0
	dash_refill_cooldown_timer = 0.0
	dash_available = true
	dash_ultra_triggered = false
	wall_slide_timer = 0.0
	climb_stamina = MovementConstants.CLIMB_MAX_STAMINA
	tired_blink_timer = 0.0
	visual.modulate.a = 1.0
	cape.reset_simulation()
	cpu_controller.reset()
	_set_ducking(false)
	force_move_x = 0.0
	force_move_timer = 0.0
	is_dashing = false
	dash_rescue_hit = false
	step_distance = 0.0
	dash_rescue_area.monitoring = false


func _physics_process(delta: float) -> void:
	if (
		multiplayer.has_multiplayer_peer()
		and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer
		and not is_multiplayer_authority()
	):
		_update_footsteps(delta)
		return

	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	dash_refill_cooldown_timer = maxf(dash_refill_cooldown_timer - delta, 0.0)
	if platform_drop_timer > 0.0:
		platform_drop_timer = maxf(platform_drop_timer - delta, 0.0)
		if is_zero_approx(platform_drop_timer):
			set_collision_mask_value(PLATFORM_COLLISION_LAYER_INDEX, true)
	var grounded := is_on_floor() and platform_drop_timer <= 0.0
	var cpu_state := cpu_controller.update_decision(delta)
	var bot_active := cpu_state != CPUController.State.INACTIVE
	var horizontal_input := _horizontal_input(bot_active)

	if not is_zero_approx(horizontal_input):
		facing_direction = Vector2.RIGHT if horizontal_input > 0.0 else Vector2.LEFT

	if movement_state == MovementState.DASH and dash_freeze_timer > 0.0:
		var current_dash_input := _dash_input(horizontal_input, bot_active)
		if not current_dash_input.is_zero_approx():
			dash_direction = current_dash_input.normalized()
		dash_freeze_timer = maxf(dash_freeze_timer - delta, 0.0)
		velocity = Vector2.ZERO
		if dash_freeze_timer > 0.0:
			_update_cape(delta, true)
			_update_visual_state(horizontal_input, grounded, delta)
			return
		_begin_dash()

	if (
		movement_state != MovementState.DASH
		and dash_available
		and dash_cooldown_timer <= 0.0
		and _dash_requested(bot_active)
	):
		var requested_direction := _dash_input(horizontal_input, bot_active)
		dash_direction = requested_direction.normalized() if not requested_direction.is_zero_approx() else facing_direction
		dash_available = false
		dash_refill_cooldown_timer = MovementConstants.DASH_REFILL_COOLDOWN
		dash_cooldown_timer = MovementConstants.DASH_COOLDOWN
		dash_freeze_timer = MovementConstants.DASH_FREEZE
		dash_ultra_triggered = false
		movement_state = MovementState.DASH
		is_dashing = false
		velocity = Vector2.ZERO
		_update_cape(delta, true)
		_update_visual_state(horizontal_input, grounded, delta)
		return

	force_move_timer = maxf(force_move_timer - delta, 0.0)
	if force_move_timer > 0.0:
		horizontal_input = force_move_x

	if grounded:
		coyote_timer = MovementConstants.COYOTE_TIME
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if _jump_requested(bot_active, grounded):
		var down_held := (
			not bot_enabled and input_reader.is_pressed(PlayerActionCatalog.ACTION_DOWN)
		)
		if grounded and down_held and _is_on_one_way_platform():
			_begin_platform_drop()
			grounded = false
			jump_buffer_timer = 0.0
		else:
			jump_buffer_timer = MovementConstants.JUMP_BUFFER
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	var wall_jump_direction := _wall_direction_within(MovementConstants.WALL_CHECK_DIST)
	var climb_wall_direction := _climbable_wall_direction_within(
		MovementConstants.CLIMB_CHECK_DIST
	)
	var grab_held := not bot_enabled and input_reader.is_pressed(PlayerActionCatalog.ACTION_GRAB)
	var wall_jump_started := false
	if movement_state == MovementState.CLIMB:
		if jump_buffer_timer > 0.0 and wall_jump_direction != 0.0:
			_perform_wall_jump(wall_jump_direction, true)
			wall_jump_started = true
		elif not grab_held or climb_wall_direction == 0.0 or climb_stamina <= 0.0:
			movement_state = MovementState.NORMAL
		else:
			_update_climb_state(delta)
	elif movement_state == MovementState.NORMAL:
		if grab_held and climb_wall_direction != 0.0 and climb_stamina > 0.0:
			movement_state = MovementState.CLIMB
			_update_climb_state(delta)
		elif jump_buffer_timer > 0.0 and wall_jump_direction != 0.0:
			_perform_wall_jump(wall_jump_direction, false)
			wall_jump_started = true

	if force_move_timer > 0.0:
		horizontal_input = force_move_x

	var jumped := (
		movement_state == MovementState.NORMAL
		and jump_buffer_timer > 0.0
		and (grounded or coyote_timer > 0.0)
	)
	if jumped:
		_set_ducking(false)
		velocity.x += MovementConstants.JUMP_H_BOOST * horizontal_input
		velocity.y = MovementConstants.JUMP_SPEED
		var_jump_timer = MovementConstants.VAR_JUMP_TIME
		var_jump_speed = velocity.y
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		audio_manager.call(
			"play_local_action", "jump", global_position, is_multiplayer_authority()
		)

	var wall_slide_active := (
		movement_state == MovementState.NORMAL
		and not grounded
		and velocity.y > 0.0
		and wall_jump_direction != 0.0
		and signf(horizontal_input) == -wall_jump_direction
	)
	if wall_slide_active:
		var wall_slide_limit := lerpf(
			MovementConstants.WALL_SLIDE_START,
			MovementConstants.MAX_FALL,
			clampf(wall_slide_timer / MovementConstants.WALL_SLIDE_TIME, 0.0, 1.0)
		)
		velocity.y = wall_slide_limit

	if movement_state == MovementState.DASH:
		var dash_progress := 1.0 - dash_timer / MovementConstants.DASH_TIME
		var speed_pulse := 1.0 + MovementConstants.DASH_SPEED_PULSE * sin(PI * dash_progress)
		var current_dash_speed := MovementConstants.DASH_SPEED * speed_pulse
		if dash_ultra_triggered and is_zero_approx(dash_velocity.y):
			dash_velocity = Vector2(
				signf(dash_velocity.x) * current_dash_speed * MovementConstants.ULTRA_MULT,
				0.0
			)
		else:
			dash_velocity = dash_direction * current_dash_speed
		velocity = dash_velocity
		dash_timer = maxf(dash_timer - delta, 0.0)
	elif movement_state == MovementState.CLIMB:
		velocity.x = 0.0
	elif wall_jump_started:
		pass
	else:
		var movement_control := 1.0 if grounded else MovementConstants.AIR_MULT
		var target_run_speed := MovementConstants.MAX_RUN * arena_speed_multiplier
		var target_horizontal_speed := horizontal_input * target_run_speed
		var is_preserving_excess_speed := (
			not is_zero_approx(horizontal_input)
			and absf(velocity.x) > target_run_speed
			and signf(velocity.x) == horizontal_input
		)
		var horizontal_rate := (
			MovementConstants.RUN_REDUCE
			if is_preserving_excess_speed
			else MovementConstants.RUN_ACCEL
		)
		velocity.x = move_toward(
			velocity.x, target_horizontal_speed, horizontal_rate * movement_control * delta
		)

	if movement_state != MovementState.DASH and movement_state != MovementState.CLIMB:
		if grounded and not jumped:
			velocity.y = 0.0
		elif wall_slide_active:
			pass
		elif not jumped:
			var gravity_multiplier := 1.0
			if (
				absf(velocity.y) <= MovementConstants.HALF_GRAV_THRESHOLD
				and _jump_held(bot_active)
			):
				gravity_multiplier = 0.5
			if (
				not bot_enabled
				and input_reader.is_pressed(PlayerActionCatalog.ACTION_DOWN)
				and velocity.y >= MovementConstants.MAX_FALL
			):
				velocity.y = move_toward(
					velocity.y,
					MovementConstants.FAST_MAX_FALL,
					MovementConstants.FAST_MAX_ACCEL * delta
				)
			else:
				velocity.y = move_toward(
					velocity.y,
					MovementConstants.MAX_FALL,
					MovementConstants.GRAVITY * gravity_multiplier * delta
				)
		if not grounded or jumped:
			_update_variable_jump(delta, bot_active)

	var upward_speed := velocity.y
	var dash_velocity_before_move := velocity
	move_and_slide()
	if movement_state != MovementState.DASH:
		_handle_trampoline_contacts()
	if movement_state == MovementState.DASH:
		_try_dash_corner_correction(delta, dash_velocity_before_move)
		_handle_dash_contacts()
	else:
		_update_ceiling_contact(delta, upward_speed)
	_update_footsteps(delta)

	if movement_state != MovementState.DASH and is_on_floor():
		climb_stamina = MovementConstants.CLIMB_MAX_STAMINA
		if not dash_available and dash_refill_cooldown_timer <= 0.0:
			dash_available = true
		wall_slide_timer = 0.0
	elif wall_slide_active:
		wall_slide_timer = minf(wall_slide_timer + delta, MovementConstants.WALL_SLIDE_TIME)
	else:
		wall_slide_timer = 0.0

	_report_player_collisions()
	_update_visual_state(horizontal_input, is_on_floor(), delta)
	if movement_state == MovementState.DASH and dash_timer <= 0.0:
		_end_dash()
	_update_cape(delta, movement_state == MovementState.DASH and dash_freeze_timer > 0.0)


func _dash_input(horizontal_input: float, bot_active: bool) -> Vector2:
	if bot_enabled:
		return cpu_controller.dash_direction if bot_active else Vector2.ZERO
	var vertical_input := input_reader.get_axis(
		PlayerActionCatalog.ACTION_UP, PlayerActionCatalog.ACTION_DOWN
	)
	return Vector2(horizontal_input, vertical_input)


func _handle_dash_contacts() -> void:
	if dash_direction.y > 0.0 and is_on_floor():
		if not is_zero_approx(dash_direction.x) and not dash_ultra_triggered:
			dash_velocity.x *= MovementConstants.ULTRA_MULT
			dash_velocity.y = 0.0
			dash_ultra_triggered = true
			_set_ducking(true)
			velocity = dash_velocity
		elif is_zero_approx(dash_direction.x):
			_set_ducking(true)

	if jump_buffer_timer <= 0.0:
		return

	if dash_direction.is_equal_approx(Vector2.UP):
		var wall_direction := _wall_direction_within(MovementConstants.WALL_CHECK_DIST)
		if wall_direction != 0.0:
			velocity = Vector2(
				MovementConstants.SUPER_WALL_JUMP_H * wall_direction,
				MovementConstants.SUPER_WALL_JUMP_SPEED
			)
			var_jump_timer = MovementConstants.SUPER_WALL_JUMP_VAR_TIME
			var_jump_speed = MovementConstants.SUPER_WALL_JUMP_SPEED
			force_move_x = wall_direction
			force_move_timer = MovementConstants.SUPER_WALL_JUMP_FORCE_TIME
			_set_ducking(false)
			jump_buffer_timer = 0.0
			_end_dash(false)
			audio_manager.call(
				"play_local_action", "jump", global_position, is_multiplayer_authority(), 0.15
			)
			return

	if not is_on_floor():
		return

	if ducking:
		velocity.x = MovementConstants.SUPER_JUMP_H * signf(facing_direction.x)
		velocity.x *= MovementConstants.DUCK_SUPER_X_MULT
		velocity.y = MovementConstants.JUMP_SPEED * MovementConstants.DUCK_SUPER_Y_MULT
		_set_ducking(false)
		jump_buffer_timer = 0.0
		_end_dash(false)
		audio_manager.call(
			"play_local_action", "jump", global_position, is_multiplayer_authority(), 0.15
		)
	elif is_zero_approx(dash_direction.y):
		velocity = Vector2(
			MovementConstants.SUPER_JUMP_H * signf(facing_direction.x),
			MovementConstants.JUMP_SPEED
		)
		jump_buffer_timer = 0.0
		_end_dash(false)
		audio_manager.call(
			"play_local_action", "jump", global_position, is_multiplayer_authority(), 0.15
		)


func _wall_direction_within(distance: float) -> float:
	for direction in [-1.0, 1.0]:
		if test_move(global_transform, Vector2(direction * distance, 0.0)):
			return -direction
	return 0.0


func _climbable_wall_direction_within(distance: float) -> float:
	for direction in [-1.0, 1.0]:
		var collision := KinematicCollision2D.new()
		if test_move(
			global_transform, Vector2(direction * distance, 0.0), collision
		) and collision.get_collider() is Node and collision.get_collider().is_in_group("climbable_wall"):
			return -direction
	return 0.0


func _handle_trampoline_contacts() -> void:
	if not is_on_floor() or velocity.y < 0.0:
		return
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider is Node and collider.is_in_group("trampoline") and collision.get_normal().y < -0.5:
			velocity.y = -MovementConstants.TRAMPOLINE_BOUNCE_SPEED
			var_jump_timer = 0.0
			return


func _is_on_one_way_platform() -> bool:
	for index in get_slide_collision_count():
		var collider := get_slide_collision(index).get_collider()
		if collider is Node and collider.is_in_group("one_way_platform"):
			return true
	return false


func _begin_platform_drop() -> void:
	platform_drop_timer = PLATFORM_DROP_DURATION
	set_collision_mask_value(PLATFORM_COLLISION_LAYER_INDEX, false)
	velocity.y = maxf(velocity.y, 60.0)


func _update_climb_state(delta: float) -> void:
	var vertical_input := input_reader.get_axis(
		PlayerActionCatalog.ACTION_UP, PlayerActionCatalog.ACTION_DOWN
	)
	velocity.x = 0.0
	if vertical_input < 0.0:
		velocity.y = MovementConstants.CLIMB_UP_SPEED
		climb_stamina = maxf(
			climb_stamina - MovementConstants.CLIMB_UP_COST * delta,
			0.0
		)
	elif vertical_input > 0.0:
		velocity.y = MovementConstants.CLIMB_DOWN_SPEED
	else:
		velocity.y = 0.0
		climb_stamina = maxf(
			climb_stamina - MovementConstants.CLIMB_STILL_COST * delta,
			0.0
		)


func _update_cape(delta: float, frozen: bool = false) -> void:
	var facing_sign := -1.0 if facing_direction.x < 0.0 else 1.0
	var duck_offset := MovementConstants.CAPE_DUCK_OFFSET if ducking else 0.0
	cape_anchor_a.position = Vector2(
		MovementConstants.CAPE_ANCHOR_A.x * facing_sign,
		MovementConstants.CAPE_ANCHOR_A.y + duck_offset
	)
	cape_anchor_b.position = Vector2(
		MovementConstants.CAPE_ANCHOR_B.x * facing_sign,
		MovementConstants.CAPE_ANCHOR_B.y + duck_offset
	)
	cape.simulate(
		delta,
		cape_anchor_a.global_position,
		cape_anchor_b.global_position,
		velocity,
		get_cape_color(),
		frozen,
		dash_direction if is_dashing else Vector2.ZERO,
		(1.0 - dash_timer / MovementConstants.DASH_TIME) if is_dashing else 0.0
	)


func get_cape_color() -> Color:
	if dash_available:
		return Color.from_hsv(
			idle_color.h,
			maxf(idle_color.s, MovementConstants.CAPE_VIVID_SATURATION_MIN),
			MovementConstants.CAPE_VIVID_VALUE_MIN
		)
	return Color.from_hsv(
		idle_color.h,
		idle_color.s * MovementConstants.CAPE_DULL_SATURATION_MULT,
		idle_color.v * MovementConstants.CAPE_DULL_VALUE_MULT
	)


func _perform_wall_jump(wall_jump_direction: float, from_climb: bool) -> void:
	if from_climb:
		climb_stamina = maxf(
			climb_stamina - MovementConstants.CLIMB_JUMP_COST,
			0.0
		)
	movement_state = MovementState.NORMAL
	velocity = Vector2(
		MovementConstants.WALL_JUMP_H * wall_jump_direction,
		MovementConstants.JUMP_SPEED
	)
	var_jump_timer = MovementConstants.VAR_JUMP_TIME
	var_jump_speed = MovementConstants.JUMP_SPEED
	force_move_x = wall_jump_direction
	force_move_timer = MovementConstants.WALL_JUMP_FORCE_TIME
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	_set_ducking(false)
	audio_manager.call(
		"play_local_action", "jump", global_position, is_multiplayer_authority()
	)


func _try_dash_corner_correction(delta: float, previous_velocity: Vector2) -> bool:
	if get_slide_collision_count() == 0:
		return false
	var perpendicular := Vector2(-dash_direction.y, dash_direction.x)
	var forward_step := dash_direction * minf(previous_velocity.length() * delta, 1.0)
	for offset in range(1, int(MovementConstants.DASH_CORNER_CORRECTION) + 1):
		for direction in [-1.0, 1.0]:
			var correction: Vector2 = perpendicular * offset * direction
			if test_move(global_transform, correction):
				continue
			var candidate_transform := global_transform
			candidate_transform.origin += correction
			if test_move(candidate_transform, forward_step):
				continue
			global_transform = candidate_transform
			velocity = previous_velocity
			return true
	return false


func _horizontal_input(bot_active: bool) -> float:
	if not bot_enabled:
		return input_reader.get_axis(
			PlayerActionCatalog.ACTION_LEFT, PlayerActionCatalog.ACTION_RIGHT
		)
	if not bot_active:
		return 0.0
	return cpu_controller.horizontal_intent


func _dash_requested(bot_active: bool) -> bool:
	if not bot_enabled:
		return input_reader.is_just_pressed(PlayerActionCatalog.ACTION_DASH)
	return bot_active and cpu_controller.dash_requested


func _jump_requested(bot_active: bool, grounded: bool) -> bool:
	if not bot_enabled:
		return input_reader.is_just_pressed(PlayerActionCatalog.ACTION_JUMP)
	return bot_active and grounded and cpu_controller.jump_requested


func _jump_held(bot_active: bool) -> bool:
	if bot_enabled:
		return bot_active and var_jump_timer > 0.0
	return input_reader.is_pressed(PlayerActionCatalog.ACTION_JUMP)


func _update_variable_jump(delta: float, bot_active: bool) -> void:
	if var_jump_timer <= 0.0:
		return
	if not _jump_held(bot_active):
		var_jump_timer = 0.0
		return
	velocity.y = minf(velocity.y, var_jump_speed)
	var_jump_timer = maxf(var_jump_timer - delta, 0.0)


func _update_ceiling_contact(delta: float, upward_speed: float) -> void:
	if not is_on_ceiling() or upward_speed >= 0.0:
		ceiling_contact_timer = 0.0
		return
	if _try_ceiling_corner_correction(upward_speed):
		ceiling_contact_timer = 0.0
		return
	ceiling_contact_timer += delta
	if ceiling_contact_timer >= MovementConstants.CEILING_JUMP_GRACE:
		var_jump_timer = 0.0
		velocity.y = maxf(velocity.y, 0.0)


func _try_ceiling_corner_correction(upward_speed: float) -> bool:
	for offset in range(1, int(MovementConstants.CEILING_CORNER_CORRECTION) + 1):
		for direction in [-1.0, 1.0]:
			var horizontal_offset := Vector2(direction * offset, 0.0)
			if test_move(global_transform, horizontal_offset + Vector2.UP):
				continue
			global_position += horizontal_offset
			velocity.y = upward_speed
			return true
	return false


func set_priority_indicator(active: bool) -> void:
	priority_indicator.visible = active


func show_touch_pixel(world_position: Vector2) -> void:
	var pixel := Polygon2D.new()
	pixel.polygon = PackedVector2Array([
		Vector2(-TOUCH_PIXEL_HALF_SIZE, -TOUCH_PIXEL_HALF_SIZE),
		Vector2(TOUCH_PIXEL_HALF_SIZE, -TOUCH_PIXEL_HALF_SIZE),
		Vector2(TOUCH_PIXEL_HALF_SIZE, TOUCH_PIXEL_HALF_SIZE),
		Vector2(-TOUCH_PIXEL_HALF_SIZE, TOUCH_PIXEL_HALF_SIZE),
	])
	pixel.color = Color.WHITE
	pixel.position = to_local(world_position)
	pixel.z_index = 5
	add_child(pixel)
	var tween := create_tween()
	tween.tween_interval(TOUCH_PIXEL_LIFETIME * 0.65)
	tween.tween_property(pixel, "modulate:a", 0.0, TOUCH_PIXEL_LIFETIME * 0.35)
	tween.tween_callback(pixel.queue_free)


func _update_visual_state(horizontal_input: float, grounded: bool, delta: float) -> void:
	if movement_state == MovementState.CLIMB and climb_stamina < MovementConstants.CLIMB_TIRED_THRESHOLD:
		tired_blink_timer = fmod(
			tired_blink_timer + delta,
			MovementConstants.CLIMB_TIRED_BLINK_TIME
		)
		visual.modulate.a = (
			MovementConstants.CLIMB_TIRED_ALPHA
			if tired_blink_timer < MovementConstants.CLIMB_TIRED_BLINK_TIME * 0.5
			else 1.0
		)
	else:
		tired_blink_timer = 0.0
		visual.modulate.a = 1.0

	visual.scale = Vector2.ONE
	visual.rotation = 0.0
	if is_dashing:
		visual.color = dash_color
		visual.scale = Vector2(1.15, 0.85)
		visual.rotation = dash_direction.angle()
	elif ducking:
		visual.color = fall_color
		visual.scale = Vector2(1.0, 0.7)
	elif movement_state == MovementState.CLIMB:
		visual.color = run_color
		if velocity.y < 0.0:
			visual.rotation = -0.08
		elif velocity.y > 0.0:
			visual.rotation = 0.08
	elif wall_slide_timer > 0.0 and not grounded:
		visual.color = fall_color
		visual.rotation = -0.08 if facing_direction.x < 0.0 else 0.08
	elif not grounded:
		if velocity.y < 0.0:
			visual.color = rise_color
		else:
			visual.color = fall_color
			visual.scale = Vector2(1.08, 0.92)
	elif not is_zero_approx(horizontal_input):
		run_animation_time += delta
		var squash := sin(run_animation_time * 14.0) * 0.05
		visual.color = run_color
		visual.scale = Vector2(1.0 + squash * 0.5, 1.0 - squash * 0.5)
	else:
		visual.color = idle_color


func _begin_dash() -> void:
	step_distance = 0.0
	dash_timer = MovementConstants.DASH_TIME
	dash_velocity = dash_direction * MovementConstants.DASH_SPEED
	audio_manager.call(
		"play_local_action", "dash", global_position, is_multiplayer_authority()
	)
	is_dashing = true
	dash_rescue_hit = false
	dash_rescue_area.position = Vector2.ZERO
	dash_rescue_area.rotation = dash_direction.angle()
	dash_rescue_area.monitoring = true


func _end_dash(apply_exit_velocity: bool = true) -> void:
	if apply_exit_velocity:
		velocity = dash_direction * MovementConstants.END_DASH_SPEED
		if velocity.y < 0.0:
			velocity.y *= MovementConstants.END_DASH_UP_MULT
	dash_timer = 0.0
	is_dashing = false
	movement_state = MovementState.NORMAL
	dash_rescue_area.monitoring = false


func _set_ducking(active: bool) -> void:
	if ducking == active:
		return
	ducking = active
	var capsule := player_collision_shape.shape as CapsuleShape2D
	if active:
		capsule.height = normal_collision_height - MovementConstants.DUCK_COLLISION_HEIGHT_REDUCTION
		player_collision_shape.position.y = MovementConstants.DUCK_COLLISION_HEIGHT_REDUCTION * 0.5
	else:
		capsule.height = normal_collision_height
		player_collision_shape.position.y = 0.0


func _on_dash_rescue_area_body_entered(body: Node2D) -> void:
	if dash_rescue_hit or not is_dashing:
		return
	if body is RigidBody2D and body.has_method("apply_dash_rescue"):
		dash_rescue_hit = body.apply_dash_rescue(self, dash_direction)


func _report_player_collisions() -> void:
	for index in get_slide_collision_count():
		var collider := get_slide_collision(index).get_collider()
		if collider is CharacterBody2D and collider.is_in_group("players"):
			player_bumped.emit(self, collider, is_dashing)


func _update_footsteps(delta: float) -> void:
	if (
		is_on_floor()
		and movement_state == MovementState.NORMAL
		and not ducking
		and absf(velocity.x) > 10.0
	):
		step_distance += absf(velocity.x) * delta
		if step_distance >= STEP_DISTANCE:
			step_distance = 0.0
			audio_manager.call(
				"play_at",
				"footstep",
				global_position,
				clampf(absf(velocity.x) / MovementConstants.MAX_RUN, 0.0, 1.0)
			)
	else:
		step_distance = 0.0
