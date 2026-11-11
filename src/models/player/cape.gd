class_name PlayerCape
extends Node2D

const MovementConstants = preload("res://src/models/player/player_movement_constants.gd")

@onready var fill: Polygon2D = $Polygon2D
@onready var outline: Line2D = $Line2D

var positions := PackedVector2Array()
var previous_positions := PackedVector2Array()
var initialized: bool = false


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	positions.resize(MovementConstants.CAPE_ROWS * 2)
	previous_positions.resize(MovementConstants.CAPE_ROWS * 2)
	outline.closed = true


func reset_simulation() -> void:
	initialized = false


func simulate(
	delta: float,
	anchor_a: Vector2,
	anchor_b: Vector2,
	player_velocity: Vector2,
	cape_color: Color,
	frozen: bool = false,
	dash_direction: Vector2 = Vector2.ZERO,
	dash_progress: float = 0.0
) -> void:
	fill.color = cape_color
	outline.default_color = cape_color.darkened(MovementConstants.CAPE_OUTLINE_DARKEN)
	if not _is_finite_vector(anchor_a) or not _is_finite_vector(anchor_b):
		reset_simulation()
		return

	if (
		not initialized
		or not _all_points_finite(positions)
		or not _all_points_finite(previous_positions)
		or positions[0].distance_to(anchor_a) > MovementConstants.CAPE_RESET_DISTANCE
		or positions[MovementConstants.CAPE_ROWS].distance_to(anchor_b)
		> MovementConstants.CAPE_RESET_DISTANCE
		or not _is_finite_vector(player_velocity)
	):
		_reset_to_anchors(anchor_a, anchor_b)

	if frozen or not is_finite(delta) or delta <= 0.0:
		_render_geometry()
		return

	var acceleration := Vector2(0.0, MovementConstants.CAPE_GRAVITY)
	if _is_finite_vector(player_velocity):
		acceleration -= player_velocity * MovementConstants.CAPE_WIND_GAIN
	var dash_intensity := sin(PI * clampf(dash_progress, 0.0, 1.0))
	if _is_finite_vector(dash_direction):
		acceleration -= dash_direction * MovementConstants.CAPE_DASH_PULL * dash_intensity
	for column in 2:
		for row in range(1, MovementConstants.CAPE_ROWS):
			var index := column * MovementConstants.CAPE_ROWS + row
			var current := positions[index]
			positions[index] = (
				current
				+ (current - previous_positions[index]) * MovementConstants.CAPE_DAMPING
				+ acceleration * delta * delta
			)
			previous_positions[index] = current

	var anchors := [anchor_a, anchor_b]
	var base_width := anchor_a.distance_to(anchor_b)
	var segment_length := MovementConstants.CAPE_SEGMENT * (
		1.0 + MovementConstants.CAPE_DASH_STRETCH * dash_intensity
	)
	for _iteration in MovementConstants.CAPE_ITERATIONS:
		for column in 2:
			var column_start := column * MovementConstants.CAPE_ROWS
			positions[column_start] = anchors[column]
			for row in range(MovementConstants.CAPE_ROWS - 1):
				_constrain(
					column_start + row,
					column_start + row + 1,
					segment_length,
					row == 0
				)
		for row in range(1, MovementConstants.CAPE_ROWS):
			var taper := lerpf(
				1.0,
				MovementConstants.CAPE_TAPER,
				float(row) / (MovementConstants.CAPE_ROWS - 1)
			)
			_constrain(row, MovementConstants.CAPE_ROWS + row, base_width * taper)
		positions[0] = anchor_a
		positions[MovementConstants.CAPE_ROWS] = anchor_b
		if not _all_points_finite(positions):
			_reset_to_anchors(anchor_a, anchor_b)
			break

	_render_geometry()


func _reset_to_anchors(anchor_a: Vector2, anchor_b: Vector2) -> void:
	for row in MovementConstants.CAPE_ROWS:
		var offset := Vector2.DOWN * MovementConstants.CAPE_SEGMENT * row
		positions[row] = anchor_a + offset
		previous_positions[row] = positions[row]
		positions[MovementConstants.CAPE_ROWS + row] = anchor_b + offset
		previous_positions[MovementConstants.CAPE_ROWS + row] = positions[MovementConstants.CAPE_ROWS + row]
	initialized = true


func _constrain(index_a: int, index_b: int, rest_length: float, pin_a: bool = false) -> void:
	var difference := positions[index_b] - positions[index_a]
	var current_length := difference.length()
	if current_length < 0.0001:
		return
	var correction := difference * ((current_length - rest_length) / current_length)
	if pin_a:
		positions[index_b] -= correction
	else:
		positions[index_a] += correction * 0.5
		positions[index_b] -= correction * 0.5


func _render_geometry() -> void:
	var polygon_points := PackedVector2Array()
	for row in MovementConstants.CAPE_ROWS:
		polygon_points.append(positions[row].round())
	for row in range(MovementConstants.CAPE_ROWS - 1, -1, -1):
		polygon_points.append(positions[MovementConstants.CAPE_ROWS + row].round())
	fill.polygon = polygon_points
	outline.points = polygon_points


func _all_points_finite(points: PackedVector2Array) -> bool:
	for point in points:
		if not _is_finite_vector(point):
			return false
	return true


func _is_finite_vector(value: Vector2) -> bool:
	return is_finite(value.x) and is_finite(value.y)
