class_name PlayerHair
extends Node2D

const SEGMENT_COUNT := 6
const SEGMENT_LENGTH := 2.5
const DAMPING := 0.82
const FOLLOW_RATE := 12.0
const MAX_DELTA := 1.0 / 30.0

@onready var strand_a: Line2D = $StrandA
@onready var strand_b: Line2D = $StrandB

var anchor_a: Vector2 = Vector2.ZERO
var anchor_b: Vector2 = Vector2.ZERO
var points_a: Array[Vector2] = []
var previous_a: Array[Vector2] = []
var points_b: Array[Vector2] = []
var previous_b: Array[Vector2] = []


func configure(first_anchor: Vector2, second_anchor: Vector2, hair_color: Color) -> void:
	anchor_a = first_anchor
	anchor_b = second_anchor
	strand_a.default_color = hair_color
	strand_b.default_color = hair_color.darkened(0.18)
	reset_simulation()


func reset_simulation() -> void:
	points_a.clear()
	previous_a.clear()
	points_b.clear()
	previous_b.clear()
	for index in range(SEGMENT_COUNT):
		var offset := Vector2(0.0, SEGMENT_LENGTH * index)
		points_a.append(anchor_a + offset)
		previous_a.append(anchor_a + offset)
		points_b.append(anchor_b + offset)
		previous_b.append(anchor_b + offset)
	_update_lines()


func simulate(
	delta: float,
	player_velocity: Vector2,
	facing_direction: Vector2,
	dashing: bool,
	dash_direction: Vector2,
	frozen: bool
) -> void:
	if frozen or not is_inside_tree() or points_a.size() != SEGMENT_COUNT:
		return
	if not player_velocity.is_finite() or not facing_direction.is_finite():
		reset_simulation()
		return
	var step := clampf(delta, 0.0, MAX_DELTA)
	var face_sign := -1.0 if facing_direction.x < 0.0 else 1.0
	var trailing := Vector2(-face_sign, 0.35) - player_velocity * 0.008
	if dashing:
		trailing -= dash_direction * 1.25
	trailing.y = clampf(trailing.y, -0.8, 1.4)
	trailing = trailing.normalized()
	_simulate_strand(points_a, previous_a, anchor_a, trailing, step)
	_simulate_strand(points_b, previous_b, anchor_b, trailing.rotated(-0.18), step)
	_update_lines()


func _simulate_strand(
	points: Array[Vector2],
	previous: Array[Vector2],
	anchor: Vector2,
	trailing: Vector2,
	delta: float
) -> void:
	points[0] = anchor
	previous[0] = anchor
	var follow_weight := clampf(delta * FOLLOW_RATE, 0.0, 1.0)
	for index in range(1, SEGMENT_COUNT):
		var current := points[index]
		var inertia := (current - previous[index]) * DAMPING
		previous[index] = current
		var target := points[index - 1] + trailing * SEGMENT_LENGTH
		var next := (current + inertia).lerp(target, follow_weight)
		var segment := next - points[index - 1]
		if segment.length_squared() > 0.0001:
			next = points[index - 1] + segment.normalized() * SEGMENT_LENGTH
		points[index] = next


func _update_lines() -> void:
	global_position = global_position.round()
	strand_a.points = _pixel_snap_points(points_a)
	strand_b.points = _pixel_snap_points(points_b)


func _pixel_snap_points(points: Array[Vector2]) -> PackedVector2Array:
	var snapped := PackedVector2Array()
	for point in points:
		snapped.append(point.round())
	return snapped
