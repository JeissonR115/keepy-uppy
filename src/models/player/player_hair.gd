class_name PlayerHair
extends Node2D

const TRAIL_LENGTH := 6
const MAX_STEP := 2.0
const DEFAULT_COLOR := Color("#ad4045")
const DASH_COLOR := Color("#51b5ff")
const LANDING_FLASH_TIME := 0.1
const COLOR_BLEND := 0.2

const PIVOT_TRACKS := {
	"idle": [Vector3(0, 0, -11), Vector3(0.5, 0, -10)],
	"run": [Vector3(0, 1, -10), Vector3(0.272727, 1, -11), Vector3(0.454545, 1, -10), Vector3(0.818182, 1, -11)],
	"jump": [Vector3(0, 1, -12), Vector3(0.5, 1, -11), Vector3(0.75, 0, -11)],
	"fall": [Vector3(0, 1, -11), Vector3(1, 1, -11)],
	"climb": [Vector3(0, 1, -11)],
	"edge": [
		Vector3(0, 2, -11), Vector3(0.071429, 2, -11), Vector3(0.142857, 1, -11),
		Vector3(0.214286, 1, -10), Vector3(0.285714, 0, -11), Vector3(0.357143, 1, -11),
		Vector3(0.428571, 2, -11), Vector3(0.5, 1, -11), Vector3(0.642857, 2, -11),
		Vector3(0.714286, 3, -10), Vector3(0.928571, 3, -11)
	]
}

@onready var strand: Line2D = $HairViewport/Strand
@onready var viewport: SubViewport = $HairViewport
@onready var base: Sprite2D = $HairViewport/HairBase
@onready var pivot: Marker2D = $HairPivot
@onready var output: Sprite2D = $HairOutput

var anchor := Vector2(1.0, -11.0)
var trail: Array[Vector2] = []
var idle_trail_steps := 0
var trail_color := DEFAULT_COLOR
var target_color := DEFAULT_COLOR
var profile_default_color := DEFAULT_COLOR
var landing_flash_timer := 0.0
var was_grounded := false
var has_ground_state := false
var facing := 1.0
var sampled_velocity := Vector2.ZERO
var sampled_facing := Vector2.RIGHT
var sampled_dashing := false
var sampled_dash_direction := Vector2.ZERO
var sampled_frozen := false


func _process(delta: float) -> void:
	simulate(
		delta, sampled_velocity, sampled_facing, sampled_dashing,
		sampled_dash_direction, sampled_frozen
	)


func set_motion_state(
	player_velocity: Vector2,
	facing_direction: Vector2,
	dashing: bool,
	dash_direction: Vector2,
	frozen: bool
) -> void:
	sampled_velocity = player_velocity
	sampled_facing = facing_direction
	sampled_dashing = dashing
	sampled_dash_direction = dash_direction
	sampled_frozen = frozen


func configure(first_anchor: Vector2, _second_anchor: Vector2, hair_color: Color) -> void:
	anchor = first_anchor
	profile_default_color = hair_color
	target_color = profile_default_color
	if is_node_ready():
		_set_color(profile_default_color)
		reset_simulation()


func reset_simulation() -> void:
	sampled_velocity = Vector2.ZERO
	sampled_frozen = false
	trail.clear()
	var player_position := _player_position()
	for _index in range(TRAIL_LENGTH):
		trail.append(player_position)
	idle_trail_steps = 0
	_update_line()


func reset_state() -> void:
	target_color = profile_default_color
	landing_flash_timer = 0.0
	was_grounded = false
	has_ground_state = false
	_set_color(profile_default_color)
	reset_simulation()


func simulate(
	delta: float,
	player_velocity: Vector2,
	facing_direction: Vector2,
	dashing: bool,
	dash_direction: Vector2,
	frozen: bool
) -> void:
	if frozen or not is_inside_tree() or not player_velocity.is_finite():
		return
	facing = -1.0 if facing_direction.x < 0.0 else 1.0
	var player_position := _player_position()
	if player_velocity.round() != Vector2.ZERO:
		idle_trail_steps = TRAIL_LENGTH
		trail.append(player_position)
	else:
		if idle_trail_steps > 0:
			trail.append(player_position + Vector2(-facing * idle_trail_steps, idle_trail_steps))
			idle_trail_steps -= 1
	while trail.size() > TRAIL_LENGTH:
		trail.pop_front()
	_constrain_trail()
	_update_line()
	_update_pose()


func update_state(delta: float, grounded: bool, dashing: bool, body: AnimatedSprite2D) -> void:
	if has_ground_state and grounded and not was_grounded:
		landing_flash_timer = LANDING_FLASH_TIME
		_set_color(Color.WHITE)
	if grounded and not dashing:
		target_color = profile_default_color
	was_grounded = grounded
	has_ground_state = true
	_update_color(delta, dashing, Vector2.ZERO)
	_update_pose(body)


func _constrain_trail() -> void:
	for index in range(trail.size() - 2, -1, -1):
		var next_point := trail[index + 1]
		var point := trail[index]
		var difference := next_point - point
		trail[index] = next_point - difference.clamp(
			Vector2(-MAX_STEP, -MAX_STEP), Vector2(MAX_STEP, MAX_STEP)
		)


func _update_line() -> void:
	if not is_node_ready():
		return
	var facing_anchor := Vector2(absf(anchor.x) * facing, anchor.y)
	pivot.position = facing_anchor
	pivot.scale.x = facing
	var points := PackedVector2Array()
	for world_point in trail:
		points.append((to_local(world_point) + viewport.size * 0.5).round())
	strand.points = points
	strand.position = Vector2.ZERO
	base.position = viewport.size * 0.5
	output.position = Vector2(facing_anchor.x, -8.0 + anchor.y + 11.0)


func _update_pose(body: AnimatedSprite2D = null) -> void:
	if body == null:
		body = get_parent().get_node_or_null("Visual") as AnimatedSprite2D
	if body == null or body.sprite_frames == null:
		return
	var animation := String(body.animation)
	var source_track := "fall"
	match animation:
		"idle": source_track = "idle"
		"runSlow", "runFast": source_track = "run"
		"dangling": source_track = "jump"
		"fall", "fallFast", "wallslide", "dash", "flip": source_track = "fall"
		"climbPull", "climbPush", "climbup": source_track = "climb"
		"fallPose": source_track = "edge"
	var poses: Array = PIVOT_TRACKS[source_track]
	var frame_count := body.sprite_frames.get_frame_count(body.animation)
	var phase := float(body.frame) / float(maxi(frame_count - 1, 1))
	var pose := poses[0] as Vector3
	for index in range(1, poses.size()):
		var next_pose := poses[index] as Vector3
		if phase <= next_pose.x:
			var previous_pose := poses[index - 1] as Vector3
			var blend := inverse_lerp(previous_pose.x, next_pose.x, phase)
			pose = previous_pose.lerp(next_pose, blend)
			break
		pose = next_pose
	anchor = Vector2(pose.y, pose.z)
	_update_line()


func _update_color(delta: float, dashing: bool, _dash_direction: Vector2) -> void:
	if dashing:
		target_color = DASH_COLOR
	if landing_flash_timer > 0.0:
		landing_flash_timer = maxf(landing_flash_timer - delta, 0.0)
		return
	if trail_color != target_color:
		_set_color(trail_color.lerp(target_color, COLOR_BLEND))


func _set_color(color: Color) -> void:
	trail_color = color
	if is_node_ready():
		strand.modulate = color
		base.modulate = color


func _player_position() -> Vector2:
	var player := get_parent() as Node2D
	return player.global_position if player != null else global_position
