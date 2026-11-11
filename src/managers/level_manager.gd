class_name LevelManager
extends Node

const DEFAULT_CATALOG := preload("res://src/resources/arena_catalog.tres")

@export var catalog: Resource = DEFAULT_CATALOG

@onready var map_root: Node2D = get_parent().get_node("MapRoot")
@onready var match_manager: MatchManager = get_parent().get_node("MatchManager")
@onready var balloon: BalloonController = get_parent().get_node("Balloon")
@onready var camera: Camera2D = get_parent().get_node("Camera2D")
@onready var player_1: PlayerController = get_parent().get_node("Player1")
@onready var player_2: PlayerController = get_parent().get_node("Player2")

var active_arena: Resource
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


func get_available_arenas() -> Array[Resource]:
	if catalog == null or not catalog.has_method("get_valid_arenas"):
		return []
	return catalog.call("get_valid_arenas") as Array[Resource]


func select_arena(arena_id: String) -> bool:
	for arena: Resource in get_available_arenas():
		if str(arena.get("id")) == arena_id:
			return _activate_arena(arena)
	return false


func get_selected_arena() -> Resource:
	return active_arena


func _activate_arena(arena: Resource) -> bool:
	var packed_map := arena.get("map_scene") as PackedScene
	if packed_map == null or not packed_map.can_instantiate():
		push_warning("Arena '%s' has no instantiable map scene." % str(arena.get("id")))
		return false
	var map_instance := packed_map.instantiate()
	if not map_instance is Node2D:
		push_warning("Arena '%s' root must extend Node2D." % str(arena.get("id")))
		map_instance.free()
		return false
	for child: Node in map_root.get_children():
		child.free()
	map_root.add_child(map_instance)
	active_map = map_instance as Node2D
	active_arena = arena
	match_manager.player_1_spawn_position = arena.get("player_1_spawn")
	match_manager.player_2_spawn_position = arena.get("player_2_spawn")
	var gravity_multiplier := maxf(float(arena.get("balloon_gravity_scale_multiplier")), 0.0)
	var speed_multiplier := maxf(float(arena.get("balloon_speed_multiplier")), 0.1)
	balloon.gravity_strength = base_balloon_gravity * gravity_multiplier
	balloon.max_horizontal_speed = base_balloon_speed * speed_multiplier
	player_1.arena_speed_multiplier = maxf(float(arena.get("player_speed_multiplier")), 0.1)
	player_2.arena_speed_multiplier = player_1.arena_speed_multiplier
	var arena_bounds: Rect2 = arena.get("playable_bounds")
	camera.call("set_arena_bounds", arena_bounds)
	return true
