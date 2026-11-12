class_name PlayerPresentationController
extends RefCounted

const MovementConstants = preload("res://src/models/player/player_movement_constants.gd")
const TOUCH_PIXEL_SCENE = preload("res://src/scenes/ui/components/touch_pixel.tscn")
const PLAYER_HAIR_SCENE = preload("res://src/models/player/player_hair.tscn")
const DASH_AFTERIMAGE_SCENE = preload("res://src/models/player/player_dash_afterimage.tscn")
const STEP_DISTANCE := 14.0
const PLAYER_TWO_TINT := Color(1.0, 0.84, 0.70, 1.0)

var visual: AnimatedSprite2D
var action_effect: AnimatedSprite2D
var profile: Resource
var player_hair: Node2D
var player_root: Node2D
var dash_afterimage_tint: Color = Color(0.62, 0.82, 1.0, 0.55)
var dash_afterimage_timer := 0.0
var dash_afterimages_spawned := 0
var dash_trail_rescue_hit := false
var active_afterimages: Array[Area2D] = []
var idle_color: Color
var tired_blink_timer: float = 0.0
var step_distance: float = 0.0
var current_body_animation := ""
var body_one_shot_active := false
var current_effect_animation := ""
var effect_one_shot_active := false
var effect_priority := 0
var was_climbing := false

func configure(
	player_visual: AnimatedSprite2D,
	player_action_effect: AnimatedSprite2D,
	identity_color: Color,
	player_profile: Resource,
	player_root: Node2D
) -> void:
	visual = player_visual
	action_effect = player_action_effect
	profile = player_profile
	self.player_root = player_root
	dash_afterimage_tint = profile.get("dash_afterimage_tint") as Color
	idle_color = identity_color
	visual.sprite_frames = profile.get("body_frames") as SpriteFrames
	action_effect.sprite_frames = profile.get("effect_frames") as SpriteFrames
	visual.modulate = profile.get("tint") as Color
	action_effect.modulate = profile.get("tint") as Color
	if bool(profile.get("hair_enabled")):
		player_hair = PLAYER_HAIR_SCENE.instantiate() as Node2D
		player_root.add_child(player_hair)
		player_hair.call(
			"configure", profile.get("hair_anchor_a"),
			profile.get("hair_anchor_b"), profile.get("hair_color")
		)
	visual.animation_finished.connect(_on_body_animation_finished)
	action_effect.animation_finished.connect(_on_effect_animation_finished)
	current_body_animation = "idle"
	visual.play("idle")
	action_effect.visible = false

func reset_visuals() -> void:
	clear_dash_afterimages()
	if player_hair != null:
		player_hair.call("reset_simulation")
	tired_blink_timer = 0.0
	was_climbing = false
	body_one_shot_active = false
	current_body_animation = "idle"
	visual.modulate.a = 1.0
	visual.play("idle")
	effect_one_shot_active = false
	effect_priority = 0
	current_effect_animation = ""
	action_effect.stop()
	action_effect.visible = false

func update_dash_afterimages(
	delta: float,
	dashing: bool,
	rescue_size: Vector2
) -> void:
	if not dashing or dash_afterimages_spawned >= MovementConstants.DASH_AFTERIMAGE_COUNT:
		return
	dash_afterimage_timer += delta
	while (
		dash_afterimage_timer >= MovementConstants.DASH_AFTERIMAGE_INTERVAL
		and dash_afterimages_spawned < MovementConstants.DASH_AFTERIMAGE_COUNT
	):
		dash_afterimage_timer -= MovementConstants.DASH_AFTERIMAGE_INTERVAL
		_spawn_dash_afterimage(rescue_size)

func clear_dash_afterimages() -> void:
	dash_afterimage_timer = 0.0
	dash_afterimages_spawned = 0
	dash_trail_rescue_hit = false
	for afterimage in active_afterimages:
		if is_instance_valid(afterimage):
			afterimage.queue_free()
	active_afterimages.clear()

func _spawn_dash_afterimage(rescue_size: Vector2) -> void:
	var afterimage := DASH_AFTERIMAGE_SCENE.instantiate() as Area2D
	player_root.get_parent().add_child(afterimage)
	afterimage.call("configure",
		player_root, visual, rescue_size,
		dash_afterimage_tint, MovementConstants.DASH_AFTERIMAGE_LIFETIME
	)
	afterimage.connect("expired", _on_afterimage_expired)
	active_afterimages.append(afterimage)
	dash_afterimages_spawned += 1

func _on_afterimage_expired(afterimage: Area2D) -> void:
	active_afterimages.erase(afterimage)

func update_cosmetic_motion(
	delta: float,
	facing_direction: Vector2,
	velocity: Vector2,
	dashing: bool,
	dash_direction: Vector2,
	frozen: bool
) -> void:
	if player_hair != null:
		player_hair.call(
			"simulate", delta, velocity, facing_direction,
			dashing, dash_direction, frozen
		)

func update_visual_state(
	horizontal_input: float,
	grounded: bool,
	delta: float,
	climbing: bool,
	climb_stamina: float,
	dashing: bool,
	velocity: Vector2,
	wall_slide_timer: float,
	facing_direction: Vector2,
	jumped: bool
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

	visual.flip_h = facing_direction.x < 0.0
	action_effect.flip_h = visual.flip_h
	var body_animation := _mapped_body_animation(_body_animation_for_state(
		horizontal_input, grounded, climbing, dashing, velocity, wall_slide_timer
	))
	if dashing:
		body_one_shot_active = false
		_play_body_animation(body_animation)
	elif jumped:
		_play_body_animation(_mapped_body_animation("jump_start"), true)
		play_effect_once("jump", 2)
	elif climbing and not was_climbing and velocity.y < 0.0:
		_play_body_animation(_mapped_body_animation("climb_up_entry"), true)
		play_effect_once("climb_entry", 1)
	elif climbing and not was_climbing:
		play_effect_once("climb_entry", 1)
	if not body_one_shot_active:
		_play_body_animation(body_animation)
	was_climbing = climbing
	_update_effect_loop(
		"climb_loop" if climbing else "idle_loop" if grounded and is_zero_approx(horizontal_input) else ""
	)

func _body_animation_for_state(
	horizontal_input: float,
	grounded: bool,
	climbing: bool,
	dashing: bool,
	velocity: Vector2,
	wall_slide_timer: float
) -> String:
	if dashing:
		return "dash"
	if climbing:
		return "climb_up" if velocity.y < 0.0 else "climb_down"
	if wall_slide_timer > 0.0 and not grounded:
		return "wall_slide"
	if not grounded:
		if velocity.y < 0.0:
			return "rise"
		return "fall_fast" if velocity.y >= MovementConstants.MAX_FALL else "fall"
	if not is_zero_approx(horizontal_input):
		return "run_fast" if absf(velocity.x) >= MovementConstants.MAX_RUN * 0.7 else "run_slow"
	return "idle"

func _mapped_body_animation(state_name: String) -> String:
	var animation_map: Dictionary = profile.get("body_animation_map")
	return str(animation_map.get(state_name, state_name))

func _mapped_effect_animation(state_name: String) -> String:
	var animation_map: Dictionary = profile.get("effect_animation_map")
	return str(animation_map.get(state_name, state_name))

func _play_body_animation(animation_name: String, one_shot: bool = false) -> void:
	if body_one_shot_active and not one_shot:
		return
	if current_body_animation == animation_name and not one_shot:
		return
	current_body_animation = animation_name
	body_one_shot_active = one_shot
	visual.play(animation_name)

func _on_body_animation_finished() -> void:
	body_one_shot_active = false

func play_effect_once(animation_name: String, priority: int) -> void:
	animation_name = _mapped_effect_animation(animation_name)
	if effect_one_shot_active and priority <= effect_priority:
		return
	effect_priority = priority
	effect_one_shot_active = true
	current_effect_animation = animation_name
	action_effect.visible = true
	action_effect.play(animation_name)

func on_player_bumped(_player: CharacterBody2D, _opponent: CharacterBody2D, _while_dashing: bool) -> void:
	play_effect_once("danger", 3)

func _update_effect_loop(animation_name: String) -> void:
	if not animation_name.is_empty():
		animation_name = _mapped_effect_animation(animation_name)
	if effect_one_shot_active:
		return
	if animation_name.is_empty():
		current_effect_animation = ""
		action_effect.visible = false
		action_effect.stop()
	elif current_effect_animation != animation_name:
		current_effect_animation = animation_name
		action_effect.visible = true
		action_effect.play(animation_name)

func _on_effect_animation_finished() -> void:
	if effect_one_shot_active:
		effect_one_shot_active = false
		effect_priority = 0
		current_effect_animation = ""

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
