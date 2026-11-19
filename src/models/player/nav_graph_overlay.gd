class_name NavGraphOverlay
extends Node2D

const EDGE_COLOR := Color(0.35, 0.8, 1.0, 0.75)
const NODE_COLOR := Color(0.9, 0.95, 1.0, 1.0)
const ROUTE_COLOR := Color(1.0, 0.72, 0.24, 1.0)

var graph: NavGraph
var route: PackedInt64Array


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


func clear_graph() -> void:
	graph = null
	route = PackedInt64Array()
	visible = false
	queue_redraw()


func _draw() -> void:
	if graph == null:
		return
	var point_ids := graph.get_point_ids()
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

	for route_index in range(route.size() - 1):
		draw_line(
			graph.get_point_position(route[route_index]),
			graph.get_point_position(route[route_index + 1]),
			ROUTE_COLOR,
			2.5,
			true
		)

	for point_id: int in point_ids:
		var is_route_node := route.has(point_id)
		draw_circle(
			graph.get_point_position(point_id),
			4.0 if is_route_node else 3.0,
			ROUTE_COLOR if is_route_node else NODE_COLOR
		)
