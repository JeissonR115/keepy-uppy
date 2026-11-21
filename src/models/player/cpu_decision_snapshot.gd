class_name CPUDecisionSnapshot
extends RefCounted

var state: String = "INACTIVE"
var reason: String = ""
var target_position: Vector2 = Vector2.ZERO
var current_node: int = -1
var route := PackedInt64Array()
var previous_route := PackedInt64Array()
var current_edge_from: int = -1
var current_edge_to: int = -1
var current_edge_action: String = ""
var intent: CPUIntent
var route_change_reason: String = ""
var predicted_trajectory := PackedVector2Array()


func capture(
	state_name: String,
	reason_text: String,
	target: Vector2,
	current_node_id: int,
	active_route: PackedInt64Array,
	prior_route: PackedInt64Array,
	edge_from: int,
	edge_to: int,
	edge_action: String,
	cpu_intent: CPUIntent,
	route_reason: String,
	trajectory: PackedVector2Array
) -> void:
	state = state_name
	reason = reason_text
	target_position = target
	current_node = current_node_id
	route = active_route.duplicate()
	previous_route = prior_route.duplicate()
	current_edge_from = edge_from
	current_edge_to = edge_to
	current_edge_action = edge_action
	intent = CPUIntent.new()
	intent.horizontal = cpu_intent.horizontal
	intent.jump = cpu_intent.jump
	intent.dash = cpu_intent.dash
	intent.dash_direction = cpu_intent.dash_direction
	intent.down = cpu_intent.down
	intent.grab = cpu_intent.grab
	route_change_reason = route_reason
	predicted_trajectory = trajectory.duplicate()
