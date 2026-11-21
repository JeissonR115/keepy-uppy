class_name CPUNodeTargetSelector
extends RefCounted

const DISTANCE_EPSILON := 0.001
const COST_EPSILON := 0.001


static func select_target(
	graph: NavGraph, player_position: Vector2, interception_position: Vector2
) -> Dictionary:
	if graph == null or graph.get_point_count() == 0:
		return {"found": false, "start_node": -1, "target_node": -1, "route": PackedInt64Array()}
	var point_ids := graph.get_point_ids()
	point_ids.sort()
	var start_node := -1
	var nearest_distance := INF
	for point_id: int in point_ids:
		var distance := player_position.distance_squared_to(graph.get_point_position(point_id))
		if distance < nearest_distance - DISTANCE_EPSILON or (
			is_equal_approx(distance, nearest_distance) and (start_node < 0 or point_id < start_node)
		):
			nearest_distance = distance
			start_node = point_id

	var best_target := -1
	var best_distance := INF
	var best_path_cost := INF
	var best_path := PackedInt64Array()
	for point_id: int in point_ids:
		var candidate_path := graph.get_id_path(start_node, point_id)
		if candidate_path.is_empty():
			continue
		var distance := interception_position.distance_squared_to(
			graph.get_point_position(point_id)
		)
		var path_cost := _path_cost(graph, candidate_path)
		var is_better := distance < best_distance - DISTANCE_EPSILON
		if is_equal_approx(distance, best_distance):
			is_better = (
				path_cost < best_path_cost - COST_EPSILON
				or (is_equal_approx(path_cost, best_path_cost) and point_id < best_target)
			)
		if is_better or best_target < 0:
			best_target = point_id
			best_distance = distance
			best_path_cost = path_cost
			best_path = candidate_path
	return {
		"found": best_target >= 0,
		"start_node": start_node,
		"target_node": best_target,
		"route": best_path,
	}


static func _path_cost(graph: NavGraph, path: PackedInt64Array) -> float:
	var result := 0.0
	for index in range(path.size() - 1):
		result += graph.get_edge_cost(int(path[index]), int(path[index + 1]))
	return result
