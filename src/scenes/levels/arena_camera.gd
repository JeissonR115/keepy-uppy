
class_name ArenaCamera
extends Camera2D

@export_group("Seguimiento")
@export var follow_lerp_rate: float = 8.0

@export_group("Zoom dinámico")
@export var min_zoom: float = 0.5
@export var max_zoom: float = 1.0
@export var zoom_margin: float = 1.15
@export var zoom_lerp_rate: float = 5.0

@onready var player_1: Node2D = get_parent().get_node("Player1")
@onready var player_2: Node2D = get_parent().get_node("Player2")
@onready var balloon: Node2D = get_parent().get_node("Balloon")

var arena_bounds := Rect2(0.0, 0.0, 320.0, 180.0)


func _ready() -> void:
	position_smoothing_enabled = false
	set_arena_bounds(arena_bounds)


func _process(delta: float) -> void:
	var objects := [
		player_1.global_position,
		player_2.global_position,
		balloon.global_position
	]

	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF

	for object_position in objects:
		min_x = minf(min_x, object_position.x)
		max_x = maxf(max_x, object_position.x)
		min_y = minf(min_y, object_position.y)
		max_y = maxf(max_y, object_position.y)

	var target_position := Vector2(
		(min_x + max_x) * 0.5,
		(min_y + max_y) * 0.5
	)

	global_position = global_position.lerp(
		target_position,
		clampf(delta * follow_lerp_rate, 0.0, 1.0)
	)

	var viewport_size := get_viewport_rect().size

	# Zoom mínimo permitido por el tamaño de la arena.
	var arena_max_zoom := minf(
		viewport_size.x / arena_bounds.size.x,
		viewport_size.y / arena_bounds.size.y
	)

	var effective_min_zoom := minf(min_zoom, arena_max_zoom)

	# Espacio necesario para mantener todos los objetos visibles.
	var required_width := maxf(max_x - min_x, 1.0) * zoom_margin
	var required_height := maxf(max_y - min_y, 1.0) * zoom_margin

	var required_zoom := minf(
		viewport_size.x / required_width,
		viewport_size.y / required_height
	)

	var target_zoom_value := clampf(
		required_zoom,
		effective_min_zoom,
		minf(max_zoom, arena_max_zoom)
	)

	var target_zoom := Vector2.ONE * target_zoom_value

	zoom = zoom.lerp(
		target_zoom,
		clampf(delta * zoom_lerp_rate, 0.0, 1.0)
	)


func set_arena_bounds(bounds: Rect2) -> void:
	arena_bounds = bounds

	limit_left = floori(bounds.position.x)
	limit_top = floori(bounds.position.y)
	limit_right = ceili(bounds.end.x)
	limit_bottom = ceili(bounds.end.y)
