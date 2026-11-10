extends CharacterBody2D

signal player_bumped(player: CharacterBody2D, opponent: CharacterBody2D, while_dashing: bool)

@export_enum("player_1", "player_2") var input_prefix: String = "player_1"
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
@onready var input_reader: Node = $InputReader
@onready var dash_rescue_area: Area2D = $DashRescueArea
@onready var dash_rescue_shape: CollisionShape2D = $DashRescueArea/CollisionShape2D
@onready var dash_trail: Line2D = $DashTrail


func _ready() -> void:
	input_reader.call("configure", input_prefix)
	if input_prefix == "player_1":
		idle_color = Color(0.290196, 0.764706, 0.843137)
		run_color = Color(0.470588, 0.890196, 0.945098)
		rise_color = Color(0.772549, 0.960784, 0.980392)
		fall_color = Color(0.172549, 0.537255, 0.607843)
	else:
		idle_color = Color(1.0, 0.584314, 0.427451)
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
	var horizontal_input: float = float(input_reader.call("get_axis", "left", "right"))

	if not is_zero_approx(horizontal_input):
		facing_direction = Vector2.RIGHT if horizontal_input > 0.0 else Vector2.LEFT

	var grounded := is_on_floor()
	is_dashing = dash_timer > 0.0
	var finish_dash_after_move := false
	if not is_dashing and dash_cooldown_timer <= 0.0 and bool(input_reader.call("is_just_pressed", "dash")):
		var dash_input := Vector2(
			horizontal_input,
			float(input_reader.call("get_axis", "up", "down"))
		)
		dash_direction = dash_input.normalized() if not dash_input.is_zero_approx() else facing_direction
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		is_dashing = true
		_begin_dash()
	if bool(input_reader.call("is_just_pressed", "accelerate")):
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

	if bool(input_reader.call("is_just_pressed", "jump")):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	var jumped := jump_buffer_timer > 0.0 and (grounded or coyote_timer > 0.0)
	if jumped:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
	elif bool(input_reader.call("is_just_released", "jump")) and velocity.y < 0.0:
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


func set_priority_indicator(active: bool) -> void:
	priority_indicator.visible = active


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
