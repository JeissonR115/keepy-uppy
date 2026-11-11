class_name ArenaCamera
extends Camera2D

@export var follow_lerp_rate: float = 6.0

@onready var player_1: Node2D = get_parent().get_node("Player1")
@onready var player_2: Node2D = get_parent().get_node("Player2")
@onready var balloon: Node2D = get_parent().get_node("Balloon")


func _ready() -> void:
	position_smoothing_enabled = false
	set_arena_bounds(Rect2(0.0, 0.0, 320.0, 180.0))


func _process(delta: float) -> void:
	var min_x := minf(player_1.global_position.x, player_2.global_position.x)
	var max_x := maxf(player_1.global_position.x, player_2.global_position.x)
	var min_y := minf(player_1.global_position.y, player_2.global_position.y)
	var max_y := maxf(player_1.global_position.y, player_2.global_position.y)
	min_x = minf(min_x, balloon.global_position.x)
	max_x = maxf(max_x, balloon.global_position.x)
	min_y = minf(min_y, balloon.global_position.y)
	max_y = maxf(max_y, balloon.global_position.y)
	var target := Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)
	global_position = global_position.lerp(target, clampf(delta * follow_lerp_rate, 0.0, 1.0))


func set_arena_bounds(bounds: Rect2) -> void:
	limit_left = floori(bounds.position.x)
	limit_top = floori(bounds.position.y)
	limit_right = ceili(bounds.end.x)
	limit_bottom = ceili(bounds.end.y)
