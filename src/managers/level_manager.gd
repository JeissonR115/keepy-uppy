class_name LevelManager
extends Node

const DEFAULT_CATALOG := preload("res://src/resources/arena_catalog.tres")
const SAFE_BOUNDARY_THICKNESS := 8.0

@export var catalog: ArenaCatalog = DEFAULT_CATALOG

@onready var map_root: Node2D = get_parent().get_node("MapRoot")
@onready var match_manager: MatchManager = get_parent().get_node("MatchManager")
@onready var balloon: BalloonController = get_parent().get_node("Balloon")
@onready var camera: ArenaCamera = get_parent().get_node("Camera2D")
@onready var player_1: PlayerController = get_parent().get_node("Player1")
@onready var player_2: PlayerController = get_parent().get_node("Player2")

var active_arena: ArenaData
var active_map: Node2D
var base_balloon_gravity: float
var base_balloon_speed: float


func _ready() -> void:
	base_balloon_gravity = balloon.gravity_strength
	base_balloon_speed = balloon.max_horizontal_speed
	var arenas := get_available_arenas()
	if arenas.is_empty():
		push_warning("No valid arenas are registered in the arena catalog.")
		return
	_activate_arena(arenas[0])


func get_available_arenas() -> Array[ArenaData]:
	if catalog == null:
		return []
	return catalog.get_valid_arenas()


func select_arena(arena_id: String) -> bool:
	for arena: ArenaData in get_available_arenas():
		if arena.id == arena_id:
			return _activate_arena(arena)
	return false


func get_selected_arena() -> ArenaData:
	return active_arena


func _activate_arena(arena: ArenaData) -> bool:
	var packed_map := arena.map_scene
	if packed_map == null or not packed_map.can_instantiate():
		push_warning("Arena '%s' has no instantiable map scene." % arena.id)
		return false
	var map_instance := packed_map.instantiate()
	if not map_instance is Node2D:
		push_warning("Arena '%s' root must extend Node2D." % arena.id)
		map_instance.free()
		return false
	for child: Node in map_root.get_children():
		child.free()
	map_root.add_child(map_instance)
	active_map = map_instance as Node2D
	active_arena = arena
	match_manager.player_1_spawn_position = arena.player_1_spawn
	match_manager.player_2_spawn_position = arena.player_2_spawn
	var gravity_multiplier := maxf(arena.balloon_gravity_scale_multiplier, 0.0)
	var speed_multiplier := maxf(arena.balloon_speed_multiplier, 0.1)
	balloon.gravity_strength = base_balloon_gravity * gravity_multiplier
	balloon.max_horizontal_speed = base_balloon_speed * speed_multiplier
	player_1.arena_speed_multiplier = maxf(arena.player_speed_multiplier, 0.1)
	player_2.arena_speed_multiplier = player_1.arena_speed_multiplier
	camera.set_arena_bounds(arena.playable_bounds)
	_configure_safe_boundaries(arena)
	return true


func _configure_safe_boundaries(arena: ArenaData) -> void:
	var safe_bounds := Rect2(
		arena.playable_bounds.position + arena.safe_margin,
		arena.playable_bounds.size - arena.safe_margin * 2.0
	)
	var boundary_depth := SAFE_BOUNDARY_THICKNESS
	_add_safe_boundary(
		"SafeLeftBoundary",
		Vector2(safe_bounds.position.x - boundary_depth * 0.5, safe_bounds.get_center().y),
		Vector2(boundary_depth, safe_bounds.size.y + boundary_depth * 2.0)
	)
	_add_safe_boundary(
		"SafeRightBoundary",
		Vector2(safe_bounds.end.x + boundary_depth * 0.5, safe_bounds.get_center().y),
		Vector2(boundary_depth, safe_bounds.size.y + boundary_depth * 2.0)
	)
	_add_safe_boundary(
		"SafeCeilingBoundary",
		Vector2(safe_bounds.get_center().x, safe_bounds.position.y - boundary_depth * 0.5),
		Vector2(safe_bounds.size.x, boundary_depth)
	)


func _add_safe_boundary(
	boundary_name: String,
	boundary_position: Vector2,
	shape_size: Vector2
) -> void:
	var boundary := StaticBody2D.new()
	boundary.name = boundary_name
	boundary.position = boundary_position
	boundary.collision_layer = 1
	boundary.collision_mask = 0
	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = shape_size
	collision_shape.shape = rectangle
	boundary.add_child(collision_shape)
	active_map.add_child(boundary)
