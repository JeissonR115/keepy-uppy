class_name NavGraphOverlay
extends Node2D

const EDGE_COLOR := Color(0.35, 0.8, 1.0, 0.75)
const NODE_COLOR := Color(0.9, 0.95, 1.0, 1.0)
const ROUTE_COLOR := Color(1.0, 0.72, 0.24, 1.0)
const PREVIOUS_ROUTE_COLOR := Color(1.0, 0.72, 0.24, 0.24)
const TARGET_COLOR := Color(1.0, 0.3, 0.4, 0.95)
const TRAJECTORY_COLOR := Color(0.75, 0.95, 0.4, 0.9)

var graph: NavGraph
var route: PackedInt64Array
var previous_route := PackedInt64Array()
var target_position: Vector2 = Vector2.ZERO
var predicted_trajectory := PackedVector2Array()
var cpu_position: Vector2 = Vector2.ZERO
var decision_state: String = ""
var decision_reason: String = ""
var show_graph: bool = true
var show_active_route: bool = true
var show_previous_route: bool = true
var show_target: bool = true
var show_trajectory: bool = true
var show_cpu_label: bool = true


func _ready() -> void:
	z_index = 100
	visible = false


func set_graph(nav_graph: NavGraph) -> void:
	graph = nav_graph
	route = PackedInt64Array()
	visible = graph != null
	queue_redraw()


func set_route(route_nodes: PackedInt64Array) -> void:
	route = route_nodes.duplicate()
	queue_redraw()


func set_snapshot(snapshot, cpu: PlayerController = null) -> void:
	if snapshot == null:
		return
	route = snapshot.route.duplicate()
	previous_route = snapshot.previous_route.duplicate()
	target_position = snapshot.target_position
	predicted_trajectory = snapshot.predicted_trajectory.duplicate()
	decision_state = snapshot.state
	decision_reason = snapshot.reason
	if cpu != null:
		cpu_position = to_local(cpu.global_position)
	queue_redraw()


func set_layer_visible(layer_name: String, is_visible: bool) -> void:
	match layer_name:
		"graph":
			show_graph = is_visible
		"active_route":
			show_active_route = is_visible
		"previous_route":
			show_previous_route = is_visible
		"target":
			show_target = is_visible
		"trajectory":
			show_trajectory = is_visible
		"cpu_label":
			show_cpu_label = is_visible
		_:
			return
	queue_redraw()


func clear_graph() -> void:
	graph = null
	route = PackedInt64Array()
	previous_route = PackedInt64Array()
	visible = false
	queue_redraw()


func _draw() -> void:
	if graph != null:
		var point_ids := graph.get_point_ids()
		if show_graph:
			for point_id: int in point_ids:
				var from_position := graph.get_point_position(point_id)
				for connected_id: int in graph.get_point_connections(point_id):
					draw_line(
						from_position,
						graph.get_point_position(connected_id),
						EDGE_COLOR,
						1.0,
						true
					)
			for point_id: int in point_ids:
				var is_route_node := route.has(point_id)
				draw_circle(
					graph.get_point_position(point_id),
					4.0 if is_route_node else 3.0,
					ROUTE_COLOR if is_route_node else NODE_COLOR
				)
		if show_previous_route:
			_draw_route(previous_route, PREVIOUS_ROUTE_COLOR, 2.0)
		if show_active_route:
			_draw_route(route, ROUTE_COLOR, 2.5)
	if show_trajectory:
		for index in range(predicted_trajectory.size() - 1):
			draw_line(
				predicted_trajectory[index],
				predicted_trajectory[index + 1],
				TRAJECTORY_COLOR,
				1.5,
				true
			)
	if show_target:
		draw_circle(target_position, 5.0, TARGET_COLOR, false, 1.5, true)
		draw_line(target_position + Vector2(-7.0, 0.0), target_position + Vector2(7.0, 0.0), TARGET_COLOR)
		draw_line(target_position + Vector2(0.0, -7.0), target_position + Vector2(0.0, 7.0), TARGET_COLOR)
	if show_cpu_label and not decision_state.is_empty():
		draw_string(
			ThemeDB.fallback_font,
			cpu_position + Vector2(-18.0, -14.0),
			"CPU %s" % decision_state,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			6,
			TARGET_COLOR
		)


func _draw_route(route_nodes: PackedInt64Array, color: Color, width: float) -> void:
	if graph == null:
		return
	for index in range(route_nodes.size() - 1):
		if not graph.has_point(int(route_nodes[index])) or not graph.has_point(int(route_nodes[index + 1])):
			continue
		draw_line(
			graph.get_point_position(route_nodes[index]),
			graph.get_point_position(route_nodes[index + 1]),
			color,
			width,
			true
		)
