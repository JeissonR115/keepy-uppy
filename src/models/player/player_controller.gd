class_name PlayerController
extends CharacterBody2D

signal player_bumped(player: CharacterBody2D, opponent: CharacterBody2D, while_dashing: bool)

enum MovementState { NORMAL, DASH, CLIMB }

const TOUCH_PIXEL_SCENE := preload("res://src/scenes/ui/components/touch_pixel.tscn")
const PLATFORM_DROP_DURATION := 0.28
const PLATFORM_COLLISION_LAYER_INDEX := 3
const MovementConstants = preload("res://src/models/player/player_movement_constants.gd")
const PresentationController = preload("res://src/models/player/player_presentation_controller.gd")
const DashTechniques = preload("res://src/models/player/player_dash_techniques.gd")
const ClimbTechniques = preload("res://src/models/player/player_climb_techniques.gd")
const SurfaceTechniques = preload("res://src/models/player/player_surface_techniques.gd")
const JumpTechniques = preload("res://src/models/player/player_jump_techniques.gd")

@export_enum("player_1", "player_2") var input_prefix: String = "player_1"
@export var bot_enabled: bool = false
@export var dash_rescue_half_extents: Vector2 = Vector2(22.0, 10.0)
@export var visual_profile: Resource
var arena_speed_multiplier: float = 1.0

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var platform_drop_timer: float = 0.0
var var_jump_timer: float = 0.0
var var_jump_speed: float = 0.0
var ceiling_contact_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var wall_slide_timer: float = 0.0
var climb_stamina: float = MovementConstants.CLIMB_MAX_STAMINA
var dash_direction: Vector2 = Vector2.RIGHT
var dash_velocity: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.RIGHT
var movement_state: MovementState = MovementState.NORMAL
var dash_freeze_timer: float = 0.0
var dash_refill_cooldown_timer: float = 0.0
var dash_available: bool = true
var dash_ultra_triggered: bool = false
var dash_started_grounded: bool = false
var ducking: bool = false
var force_move_x: float = 0.0
var force_move_timer: float = 0.0
var is_dashing: bool = false
var dash_rescue_hit: bool = false
var normal_collision_height: float = 0.0

@onready var visual: AnimatedSprite2D = $Visual
@onready var action_effect: AnimatedSprite2D = $ActionEffect
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
var presentation = PresentationController.new()

var idle_color: Color:
	get:
		return presentation.idle_color

func _ready() -> void:
	input_reader.configure(input_prefix)
	presentation.configure(
		visual, action_effect, cape_anchor_a, cape_anchor_b, cape,
		PlayerActionCatalog.player_color(input_prefix), visual_profile, self
	)
	player_bumped.connect(presentation.on_player_bumped)
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
	dash_started_grounded = false
	wall_slide_timer = 0.0
	climb_stamina = MovementConstants.CLIMB_MAX_STAMINA
	presentation.reset_visuals()
	cpu_controller.reset()
	_set_ducking(false)
	force_move_x = 0.0
	force_move_timer = 0.0
	is_dashing = false
	dash_rescue_hit = false
	presentation.reset_footsteps()
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
	var horizontal_input := input_reader.horizontal_intent(bot_enabled, bot_active, cpu_controller.horizontal_intent)

	if not is_zero_approx(horizontal_input):
		facing_direction = Vector2.RIGHT if horizontal_input > 0.0 else Vector2.LEFT

	if movement_state == MovementState.DASH and dash_freeze_timer > 0.0:
		var current_dash_input := input_reader.dash_direction(horizontal_input, bot_enabled, bot_active, cpu_controller.dash_direction)
		if not current_dash_input.is_zero_approx():
			dash_direction = current_dash_input.normalized()
		dash_freeze_timer = maxf(dash_freeze_timer - delta, 0.0)
		velocity = Vector2.ZERO
		if dash_freeze_timer > 0.0:
			_update_cosmetic_motion(delta, true)
			_update_presentation_state(horizontal_input, grounded, delta)
			return
		DashTechniques.begin_dash(self, MovementConstants)

	if (
		movement_state != MovementState.DASH
		and dash_available
		and dash_cooldown_timer <= 0.0
		and input_reader.dash_requested(bot_enabled, bot_active, cpu_controller.dash_requested)
	):
		var requested_direction := input_reader.dash_direction(horizontal_input, bot_enabled, bot_active, cpu_controller.dash_direction)
		dash_direction = requested_direction.normalized() if not requested_direction.is_zero_approx() else facing_direction
		dash_available = false
		dash_refill_cooldown_timer = MovementConstants.DASH_REFILL_COOLDOWN
		dash_cooldown_timer = MovementConstants.DASH_COOLDOWN
		dash_freeze_timer = MovementConstants.DASH_FREEZE
		dash_ultra_triggered = false
		dash_started_grounded = grounded
		movement_state = MovementState.DASH
		is_dashing = false
		velocity = Vector2.ZERO
		_update_cosmetic_motion(delta, true)
		_update_presentation_state(horizontal_input, grounded, delta)
		return

	force_move_timer = maxf(force_move_timer - delta, 0.0)
	if force_move_timer > 0.0:
		horizontal_input = force_move_x

	if grounded:
		coyote_timer = MovementConstants.COYOTE_TIME
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if input_reader.jump_requested(bot_enabled, bot_active, grounded, cpu_controller.jump_requested):
		var down_held := (
			not bot_enabled and input_reader.is_pressed(PlayerActionCatalog.ACTION_DOWN)
		)
		if grounded and down_held and SurfaceTechniques.is_on_one_way_platform(self):
			SurfaceTechniques.begin_platform_drop(
				self, PLATFORM_COLLISION_LAYER_INDEX, PLATFORM_DROP_DURATION
			)
			grounded = false
			jump_buffer_timer = 0.0
		else:
			jump_buffer_timer = MovementConstants.JUMP_BUFFER
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	var wall_jump_direction := _wall_direction_within(MovementConstants.WALL_CHECK_DIST)
	var climb_wall_direction := ClimbTechniques.climbable_wall_direction_within(
		self, MovementConstants.CLIMB_CHECK_DIST
	)
	var grab_held := not bot_enabled and input_reader.is_pressed(PlayerActionCatalog.ACTION_GRAB)
	var wall_jump_started := false
	if movement_state == MovementState.CLIMB:
		if jump_buffer_timer > 0.0 and wall_jump_direction != 0.0:
			ClimbTechniques.perform_wall_jump(self, MovementConstants, wall_jump_direction, true)
			wall_jump_started = true
		elif not grab_held or climb_wall_direction == 0.0 or climb_stamina <= 0.0:
			movement_state = MovementState.NORMAL
		else:
			ClimbTechniques.update_climb_state(
				self, MovementConstants, input_reader.vertical_intent(), delta
			)
	elif movement_state == MovementState.NORMAL:
		if grab_held and climb_wall_direction != 0.0 and climb_stamina > 0.0:
			movement_state = MovementState.CLIMB
			ClimbTechniques.update_climb_state(
				self, MovementConstants, input_reader.vertical_intent(), delta
			)
		elif jump_buffer_timer > 0.0 and wall_jump_direction != 0.0:
			ClimbTechniques.perform_wall_jump(self, MovementConstants, wall_jump_direction, false)
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
		velocity.y = ClimbTechniques.wall_slide_speed(MovementConstants, wall_slide_timer)

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
				and input_reader.jump_held(bot_enabled, bot_active, var_jump_timer)
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
		SurfaceTechniques.handle_trampoline_contacts(self, MovementConstants)
	if movement_state == MovementState.DASH:
		DashTechniques.try_corner_correction(
			self, dash_direction, delta, dash_velocity_before_move,
			MovementConstants.DASH_CORNER_CORRECTION
		)
		DashTechniques.handle_contacts(self, MovementConstants)
	else:
		SurfaceTechniques.update_ceiling_contact(self, MovementConstants, delta, upward_speed)
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

	DashTechniques.report_player_collisions(self)
	_update_presentation_state(horizontal_input, is_on_floor(), delta, jumped)
	if movement_state == MovementState.DASH and dash_timer <= 0.0:
		_end_dash()
	_update_cosmetic_motion(delta, movement_state == MovementState.DASH and dash_freeze_timer > 0.0)

func _wall_direction_within(distance: float) -> float: return DashTechniques.wall_direction_within(self, distance)

func _climbable_wall_direction_within(distance: float) -> float:
	return ClimbTechniques.climbable_wall_direction_within(self, distance)

func _perform_wall_jump(wall_jump_direction: float, from_climb: bool) -> void: ClimbTechniques.perform_wall_jump(self, MovementConstants, wall_jump_direction, from_climb)

func _update_variable_jump(delta: float, bot_active: bool) -> void:
	JumpTechniques.update_variable_jump(
		self, delta, input_reader.jump_held(bot_enabled, bot_active, var_jump_timer),
		MovementConstants.JUMP_CUT_MULTIPLIER
	)

func set_priority_indicator(active: bool) -> void: priority_indicator.visible = active

func show_touch_pixel(world_position: Vector2) -> void:
	PresentationController.add_touch_pixel(self, world_position)

func _update_cosmetic_motion(delta: float, frozen: bool) -> void:
	presentation.update_cosmetic_motion(
		delta, frozen, facing_direction, ducking, velocity, dash_available,
		is_dashing, dash_direction, dash_timer,
		movement_state == MovementState.DASH
	)

func _update_presentation_state(horizontal_input: float, grounded: bool, delta: float, jumped: bool = false) -> void:
	presentation.update_visual_state(
		horizontal_input, grounded, delta,
		movement_state == MovementState.CLIMB, climb_stamina,
		movement_state == MovementState.DASH, velocity,
		wall_slide_timer, facing_direction, jumped
	)

func get_cape_color() -> Color: return presentation.get_cape_color(dash_available)

func _end_dash(apply_exit_velocity: bool = true) -> void: DashTechniques.end_dash(self, MovementConstants, apply_exit_velocity)

func _set_ducking(active: bool) -> void: DashTechniques.set_ducking(self, MovementConstants, active)

func _on_dash_rescue_area_body_entered(body: Node2D) -> void:
	DashTechniques.handle_rescue_body(self, body)

func _update_footsteps(delta: float) -> void:
	presentation.update_footsteps(
		is_on_floor(),
		movement_state == MovementState.NORMAL,
		ducking,
		velocity,
		delta,
		global_position,
		audio_manager
	)
