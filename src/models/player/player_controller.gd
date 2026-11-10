class_name PlayerController
extends CharacterBody2D

signal player_bumped(player: CharacterBody2D, opponent: CharacterBody2D, while_dashing: bool)

const BOT_HORIZONTAL_DEADZONE := 10.0
const BOT_JUMP_ALIGNMENT_DISTANCE := 26.0
const BOT_JUMP_TRIGGER_HEIGHT := 20.0
const BOT_DASH_RANGE := 56.0
const BOT_OPPONENT_THREAT_DISTANCE := 56.0
const TOUCH_PIXEL_LIFETIME := 2.0
const TOUCH_PIXEL_HALF_SIZE := 2.0

@export_enum("player_1", "player_2") var input_prefix: String = "player_1"
@export var bot_enabled: bool = false
@export var max_run_speed: float = 140.0
@export var ground_acceleration: float = 1000.0
@export var ground_deceleration: float = 1200.0
@export_range(0.0, 1.0) var air_control: float = 0.65
@export var gravity: float = 900.0
@export var jump_velocity: float = -340.0
@export_range(0.0, 1.0) var jump_cut_multiplier: float = 0.4
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var dash_speed: float = 360.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.45
@export var dash_rescue_half_extents: Vector2 = Vector2(22.0, 10.0)
@export var accelerate_speed_multiplier: float = 1.35
@export var accelerate_duration: float = 0.8
@export var accelerate_cooldown: float = 4.0
@export var accelerate_max_speed: float = 210.0

var idle_color: Color
var run_color: Color
var rise_color: Color
var fall_color: Color
var dash_color: Color
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var accelerate_timer: float = 0.0
var accelerate_cooldown_timer: float = 0.0
var run_animation_time: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var facing_direction: Vector2 = Vector2.RIGHT
var is_dashing: bool = false
var dash_rescue_hit: bool = false

@onready var visual: Polygon2D = $Visual
@onready var priority_indicator: Polygon2D = $PriorityIndicator
@onready var input_reader: PlayerInputReader = $InputReader
@onready var match_manager: MatchManager = get_parent().get_node("MatchManager")
@onready var balloon: BalloonController = get_parent().get_node("Balloon")
@onready var dash_rescue_area: Area2D = $DashRescueArea
@onready var dash_rescue_shape: CollisionShape2D = $DashRescueArea/CollisionShape2D
@onready var dash_trail: Line2D = $DashTrail


func _ready() -> void:
	input_reader.configure(input_prefix)
	if input_prefix == PlayerActionCatalog.PLAYER_ONE_PREFIX:
		idle_color = PlayerActionCatalog.player_color(input_prefix)
		run_color = Color(0.470588, 0.890196, 0.945098)
		rise_color = Color(0.772549, 0.960784, 0.980392)
		fall_color = Color(0.172549, 0.537255, 0.607843)
	else:
		idle_color = PlayerActionCatalog.player_color(input_prefix)
		run_color = Color(1.0, 0.780392, 0.466667)
		rise_color = Color(1.0, 0.898039, 0.729412)
		fall_color = Color(0.690196, 0.286275, 0.270588)
	dash_color = Color(1.0, 1.0, 1.0)
	visual.color = idle_color
	var rescue_rectangle := dash_rescue_shape.shape as RectangleShape2D
	rescue_rectangle.size = dash_rescue_half_extents * 2.0
	dash_rescue_area.monitoring = false
	dash_trail.visible = false
	dash_rescue_area.body_entered.connect(_on_dash_rescue_area_body_entered)


func reset_for_round(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	accelerate_timer = 0.0
	accelerate_cooldown_timer = 0.0
	is_dashing = false
	dash_rescue_hit = false
	dash_rescue_area.monitoring = false
	dash_trail.visible = false


func _physics_process(delta: float) -> void:
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	accelerate_timer = maxf(accelerate_timer - delta, 0.0)
	accelerate_cooldown_timer = maxf(accelerate_cooldown_timer - delta, 0.0)
	var grounded := is_on_floor()
	var bot_turn_active := (
		bot_enabled
		and match_manager.match_state == MatchManager.MatchState.ACTIVE
		and match_manager.expected_balloon_player == self
	)
	var horizontal_input := _horizontal_input(bot_turn_active)

	if not is_zero_approx(horizontal_input):
		facing_direction = Vector2.RIGHT if horizontal_input > 0.0 else Vector2.LEFT

	is_dashing = dash_timer > 0.0
	var finish_dash_after_move := false
	if not is_dashing and dash_cooldown_timer <= 0.0 and _dash_requested(bot_turn_active):
		var dash_vertical_input := -1.0
		if bot_enabled and _bot_should_challenge_opponent() and not is_zero_approx(horizontal_input):
			dash_vertical_input = 0.0
		var dash_input := Vector2(
			horizontal_input,
			input_reader.get_axis(PlayerActionCatalog.ACTION_UP, PlayerActionCatalog.ACTION_DOWN)
			if not bot_enabled
			else dash_vertical_input
		)
		dash_direction = dash_input.normalized() if not dash_input.is_zero_approx() else facing_direction
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		is_dashing = true
		_begin_dash()
	if not bot_enabled and input_reader.is_just_pressed(PlayerActionCatalog.ACTION_ACCELERATE):
		try_activate_accelerate()

	if is_dashing:
		velocity = dash_direction * dash_speed
		dash_timer = maxf(dash_timer - delta, 0.0)
		finish_dash_after_move = dash_timer <= 0.0
	else:
		var movement_control := 1.0 if grounded else air_control
		var horizontal_rate := ground_acceleration if not is_zero_approx(horizontal_input) else ground_deceleration
		var target_run_speed := max_run_speed
		if accelerate_timer > 0.0:
			target_run_speed = minf(max_run_speed * accelerate_speed_multiplier, accelerate_max_speed)
		velocity.x = move_toward(
			velocity.x,
			horizontal_input * target_run_speed,
			horizontal_rate * movement_control * delta
		)
		if accelerate_timer > 0.0:
			velocity.x = clampf(velocity.x, -accelerate_max_speed, accelerate_max_speed)

	if grounded:
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if _jump_requested(bot_turn_active, grounded):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	var jumped := jump_buffer_timer > 0.0 and (grounded or coyote_timer > 0.0)
	if jumped:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
	elif not bot_enabled and input_reader.is_just_released(PlayerActionCatalog.ACTION_JUMP) and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	if not is_dashing:
		if grounded and not jumped:
			velocity.y = 0.0
		else:
			velocity.y += gravity * delta

	move_and_slide()
	_report_player_collisions()
	_update_visual_state(horizontal_input, is_on_floor(), delta)
	if finish_dash_after_move:
		_end_dash()


func _horizontal_input(bot_turn_active: bool) -> float:
	if not bot_enabled:
		return input_reader.get_axis(
			PlayerActionCatalog.ACTION_LEFT, PlayerActionCatalog.ACTION_RIGHT
		)
	if not bot_turn_active:
		return 0.0
	var target_x := balloon.global_position.x
	if _bot_should_challenge_opponent():
		target_x = match_manager.player_1.global_position.x
	var horizontal_distance := target_x - global_position.x
	if absf(horizontal_distance) <= BOT_HORIZONTAL_DEADZONE:
		return 0.0
	return signf(horizontal_distance)


func _dash_requested(bot_turn_active: bool) -> bool:
	if not bot_enabled:
		return input_reader.is_just_pressed(PlayerActionCatalog.ACTION_DASH)
	if not bot_turn_active:
		return false
	if _bot_should_challenge_opponent():
		return (
			absf(match_manager.player_1.global_position.x - global_position.x) <= BOT_DASH_RANGE
			and absf(match_manager.player_1.global_position.y - global_position.y) <= BOT_DASH_RANGE
		)
	return (
		absf(balloon.global_position.x - global_position.x) <= BOT_DASH_RANGE
		and balloon.global_position.y < global_position.y - BOT_JUMP_TRIGGER_HEIGHT
	)


func _jump_requested(bot_turn_active: bool, grounded: bool) -> bool:
	if not bot_enabled:
		return input_reader.is_just_pressed(PlayerActionCatalog.ACTION_JUMP)
	return (
		bot_turn_active
		and grounded
		and not _bot_should_challenge_opponent()
		and absf(balloon.global_position.x - global_position.x) <= BOT_JUMP_ALIGNMENT_DISTANCE
		and balloon.global_position.y < global_position.y - BOT_JUMP_TRIGGER_HEIGHT
	)


func _bot_should_challenge_opponent() -> bool:
	return (
		bot_enabled
		and match_manager.player_1.global_position.distance_to(balloon.global_position)
		<= BOT_OPPONENT_THREAT_DISTANCE
	)


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


func try_activate_accelerate() -> bool:
	if accelerate_cooldown_timer > 0.0:
		return false
	accelerate_timer = accelerate_duration
	accelerate_cooldown_timer = accelerate_cooldown
	return true


func _update_visual_state(horizontal_input: float, grounded: bool, delta: float) -> void:
	if is_dashing:
		visual.color = dash_color
		visual.scale = Vector2(1.15, 0.85)
		visual.rotation = dash_direction.angle()
	elif not grounded:
		visual.rotation = 0.0
		if velocity.y < 0.0:
			visual.color = rise_color
			visual.scale = Vector2(0.92, 1.08)
		else:
			visual.color = fall_color
			visual.scale = Vector2(1.08, 0.92)
	elif not is_zero_approx(horizontal_input):
		run_animation_time += delta
		var squash := sin(run_animation_time * 14.0) * 0.05
		visual.color = run_color
		visual.scale = Vector2(1.0 + squash, 1.0 - squash)
		visual.rotation = 0.0
	else:
		visual.color = idle_color
		visual.scale = Vector2.ONE
		visual.rotation = 0.0


func _begin_dash() -> void:
	dash_rescue_hit = false
	dash_rescue_area.position = Vector2.ZERO
	dash_rescue_area.rotation = dash_direction.angle()
	dash_rescue_area.monitoring = true
	dash_trail.points = PackedVector2Array([-dash_direction * 32.0, Vector2.ZERO])
	dash_trail.visible = true


func _end_dash() -> void:
	is_dashing = false
	dash_rescue_area.monitoring = false
	dash_trail.visible = false


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
