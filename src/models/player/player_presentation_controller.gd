class_name PlayerPresentationController
extends RefCounted

const MovementConstants = preload("res://src/models/player/player_movement_constants.gd")
const TOUCH_PIXEL_SCENE = preload("res://src/scenes/ui/components/touch_pixel.tscn")
const STEP_DISTANCE := 14.0

var visual: Polygon2D
var cape_anchor_a: Marker2D
var cape_anchor_b: Marker2D
var cape: PlayerCape
var idle_color: Color
var run_color: Color
var rise_color: Color
var fall_color: Color
var dash_color: Color = Color.WHITE
var run_animation_time: float = 0.0
var tired_blink_timer: float = 0.0
var step_distance: float = 0.0

func configure(
	player_visual: Polygon2D,
	anchor_a: Marker2D,
	anchor_b: Marker2D,
	player_cape: PlayerCape,
	identity_color: Color,
	movement_colors: Dictionary
) -> void:
	visual = player_visual
	cape_anchor_a = anchor_a
	cape_anchor_b = anchor_b
	cape = player_cape
	idle_color = identity_color
	run_color = movement_colors.run
	rise_color = movement_colors.rise
	fall_color = movement_colors.fall
	visual.color = idle_color

func update_cape(
	delta: float,
	frozen: bool,
	facing_direction: Vector2,
	ducking: bool,
	velocity: Vector2,
	dash_available: bool,
	is_dashing: bool,
	dash_direction: Vector2,
	dash_timer: float
) -> void:
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
		get_cape_color(dash_available),
		frozen,
		dash_direction if is_dashing else Vector2.ZERO,
		(1.0 - dash_timer / MovementConstants.DASH_TIME) if is_dashing else 0.0
	)

func get_cape_color(dash_available: bool) -> Color:
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

func update_visual_state(
	horizontal_input: float,
	grounded: bool,
	delta: float,
	climbing: bool,
	climb_stamina: float,
	is_dashing: bool,
	ducking: bool,
	velocity: Vector2,
	dash_direction: Vector2,
	wall_slide_timer: float,
	facing_direction: Vector2
) -> void:
	if climbing and climb_stamina < MovementConstants.CLIMB_TIRED_THRESHOLD:
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
	elif climbing:
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

func reset_footsteps() -> void:
	step_distance = 0.0

func update_footsteps(
	grounded: bool,
	normal_movement: bool,
	ducking: bool,
	velocity: Vector2,
	delta: float,
	world_position: Vector2,
	audio_manager: Node
) -> void:
	if grounded and normal_movement and not ducking and absf(velocity.x) > 10.0:
		step_distance += absf(velocity.x) * delta
		if step_distance >= STEP_DISTANCE:
			step_distance = 0.0
			audio_manager.call(
				"play_at",
				"footstep",
				world_position,
				clampf(absf(velocity.x) / MovementConstants.MAX_RUN, 0.0, 1.0)
			)
	else:
		step_distance = 0.0

static func add_touch_pixel(parent: Node2D, world_position: Vector2) -> void:
	var pixel := TOUCH_PIXEL_SCENE.instantiate() as Polygon2D
	pixel.position = parent.to_local(world_position)
	parent.add_child(pixel)
