class_name NavGraphBrain
extends CPUBrain

const ARRIVAL_RADIUS := 8.0
const START_NODE_TOLERANCE := 24.0
const SurfaceTechniques = preload("res://src/models/player/player_surface_techniques.gd")
const MovementConstants = preload("res://src/models/player/player_movement_constants.gd")

var player: PlayerController
var graph: NavGraph
var route: PackedInt64Array
var route_index: int = 0
var action_started: bool = false
var route_complete: bool = false
var last_error: String = ""


func configure(
	route_player: PlayerController,
	nav_graph: NavGraph,
	start_node: int,
	destination_node: int
) -> bool:
	last_error = ""
	if route_player == null or nav_graph == null:
		return _reject("Route requires a player and a navigation graph.")
	if not nav_graph.has_point(start_node) or not nav_graph.has_point(destination_node):
		return _reject("Route start or destination node does not exist.")
	if route_player.global_position.distance_to(nav_graph.get_point_position(start_node)) \
		> START_NODE_TOLERANCE:
		return _reject("Player is not near the requested route start node.")
	var candidate_route := nav_graph.get_id_path(start_node, destination_node)
	if candidate_route.is_empty():
		return _reject("No route connects the requested start and destination nodes.")
	player = route_player
	graph = nav_graph
	route = candidate_route
	route_index = 0
	action_started = false
	route_complete = route.size() == 1
	return true


func decide(_delta: float) -> CPUIntent:
	var intent := CPUIntent.new()
	if route_complete or route.size() < 2 or not is_instance_valid(player):
		state = State.INACTIVE
		return intent
	state = State.CPU_TURNO_PROPIO

	while route_index < route.size() - 1:
		var next_node := int(route[route_index + 1])
		var target := graph.get_point_position(next_node)
		if player.global_position.distance_to(target) > ARRIVAL_RADIUS:
			break
		route_index += 1
		action_started = false
	if route_index >= route.size() - 1:
		route_complete = true
		state = State.INACTIVE
		return intent

	var from_id := int(route[route_index])
	var to_id := int(route[route_index + 1])
	var target_position := graph.get_point_position(to_id)
	var offset := target_position - player.global_position
	intent.horizontal = signf(offset.x) if absf(offset.x) > ARRIVAL_RADIUS else 0.0
	match graph.get_edge_action(from_id, to_id):
		"WALK":
			pass
		"JUMP":
			if not action_started and player.is_on_floor():
				intent.jump = true
				action_started = true
		"DASH":
			if (
				action_started
				and player.movement_state != PlayerController.MovementState.DASH
				and player.dash_available
				and player.dash_cooldown_timer <= 0.0
			):
				action_started = false
			if not action_started and player.dash_available and player.dash_cooldown_timer <= 0.0:
				intent.dash = true
				intent.dash_direction = offset.normalized()
				action_started = true
		"DROP":
			if not action_started:
				if player.is_on_floor() and SurfaceTechniques.is_on_one_way_platform(player):
					intent.down = true
					intent.jump = true
					action_started = true
				elif not player.is_on_floor():
					intent.down = true
			elif player.platform_drop_timer > 0.0 or not player.is_on_floor():
				intent.down = true
		"WALL_JUMP":
			var wall_direction: float = player._wall_direction_within(MovementConstants.WALL_CHECK_DIST)
			if wall_direction != 0.0 and not action_started:
				intent.horizontal = wall_direction
				intent.jump = true
				action_started = true
	return intent


func reset() -> void:
	state = State.INACTIVE
	route_index = 0
	action_started = false
	route_complete = route.size() == 1


func _reject(message: String) -> bool:
	last_error = message
	return false
