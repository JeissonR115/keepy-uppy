class_name NavGraph
extends AStar2D

const SCHEMA_VERSION := 1
const EDGE_ACTIONS := ["WALK", "JUMP", "DASH", "DROP", "WALL_JUMP"]

var level_id: String = ""
var last_error: String = ""
var _edge_metadata: Dictionary = {}


func load_graph(graph: Dictionary, expected_level: String = "") -> bool:
	last_error = ""
	var version: Variant = graph.get("schema_version")
	if not _is_integer(version) or int(version) != SCHEMA_VERSION:
		return _reject("Graph schema_version must be %d." % SCHEMA_VERSION)
	var graph_level: Variant = graph.get("level")
	if typeof(graph_level) != TYPE_STRING or graph_level.strip_edges().is_empty():
		return _reject("Graph level must be a non-empty string.")
	if not expected_level.is_empty() and graph_level != expected_level:
		return _reject("Graph level '%s' does not match expected level '%s'." % [graph_level, expected_level])

	var nodes: Variant = graph.get("nodes")
	if not nodes is Array or nodes.is_empty():
		return _reject("Graph nodes must be a non-empty array.")
	var parsed_nodes: Array[Dictionary] = []
	var point_ids: Dictionary = {}
	for index in range(nodes.size()):
		var node_data: Variant = nodes[index]
		if not node_data is Dictionary:
			return _reject("Graph node at index %d must be an object." % index)
		var point_id: Variant = node_data.get("id")
		if not _is_integer(point_id):
			return _reject("Graph node at index %d requires an integer id." % index)
		var id := int(point_id)
		if point_ids.has(id):
			return _reject("Graph contains duplicate node id %d." % id)
		var position_data: Variant = node_data.get("position")
		if not _is_vector2(position_data):
			return _reject("Graph node %d requires a finite position with x and y." % id)
		point_ids[id] = true
		parsed_nodes.append(
			{"id": id, "position": Vector2(float(position_data["x"]), float(position_data["y"]))}
		)

	var edges: Variant = graph.get("edges")
	if not edges is Array:
		return _reject("Graph edges must be an array.")
	var parsed_edges: Array[Dictionary] = []
	var edge_keys: Dictionary = {}
	for index in range(edges.size()):
		var edge_data: Variant = edges[index]
		if not edge_data is Dictionary:
			return _reject("Graph edge at index %d must be an object." % index)
		var from_value: Variant = edge_data.get("from")
		var to_value: Variant = edge_data.get("to")
		if not _is_integer(from_value) or not _is_integer(to_value):
			return _reject("Graph edge at index %d requires integer from and to ids." % index)
		var from_id := int(from_value)
		var to_id := int(to_value)
		if not point_ids.has(from_id) or not point_ids.has(to_id):
			return _reject("Graph edge %d -> %d references an unknown node." % [from_id, to_id])
		if from_id == to_id:
			return _reject("Graph edge %d -> %d must connect distinct nodes." % [from_id, to_id])
		var action: Variant = edge_data.get("action")
		if typeof(action) != TYPE_STRING or not EDGE_ACTIONS.has(action):
			return _reject("Graph edge %d -> %d has an unsupported action." % [from_id, to_id])
		var cost: Variant = edge_data.get("cost")
		if not _is_number(cost) or not is_finite(float(cost)) or float(cost) <= 0.0:
			return _reject("Graph edge %d -> %d cost must be finite and positive." % [from_id, to_id])
		var bidirectional: Variant = edge_data.get("bidirectional", false)
		if typeof(bidirectional) != TYPE_BOOL:
			return _reject("Graph edge %d -> %d bidirectional must be boolean." % [from_id, to_id])

		var forward_key := _edge_key(from_id, to_id)
		var reverse_key := _edge_key(to_id, from_id)
		if edge_keys.has(forward_key):
			return _reject("Graph contains duplicate edge %d -> %d." % [from_id, to_id])
		if bidirectional and edge_keys.has(reverse_key):
			return _reject("Bidirectional edge %d -> %d duplicates a reverse edge." % [from_id, to_id])
		edge_keys[forward_key] = true
		parsed_edges.append(
			{"from": from_id, "to": to_id, "action": action, "cost": float(cost)}
		)
		if bidirectional:
			edge_keys[reverse_key] = true
			parsed_edges.append(
				{"from": to_id, "to": from_id, "action": action, "cost": float(cost)}
			)

	clear()
	_edge_metadata.clear()
	for node_data: Dictionary in parsed_nodes:
		add_point(node_data["id"], node_data["position"])
	for edge_data: Dictionary in parsed_edges:
		var from_id: int = edge_data["from"]
		var to_id: int = edge_data["to"]
		_edge_metadata[_edge_key(from_id, to_id)] = {
			"action": edge_data["action"],
			"cost": edge_data["cost"],
		}
		connect_points(from_id, to_id, false)
	level_id = graph_level
	return true


func get_edge_action(from_id: int, to_id: int) -> String:
	var edge: Dictionary = _edge_metadata.get(_edge_key(from_id, to_id), {})
	return str(edge.get("action", ""))


func get_edge_cost(from_id: int, to_id: int) -> float:
	var edge: Dictionary = _edge_metadata.get(_edge_key(from_id, to_id), {})
	return float(edge.get("cost", 0.0))


func get_edge_count() -> int:
	return _edge_metadata.size()


func _compute_cost(from_id: int, to_id: int) -> float:
	return get_edge_cost(from_id, to_id)


func _estimate_cost(_from_id: int, _to_id: int) -> float:
	return 0.0


func _reject(message: String) -> bool:
	last_error = message
	return false


func _edge_key(from_id: int, to_id: int) -> String:
	return "%d>%d" % [from_id, to_id]


func _is_vector2(value: Variant) -> bool:
	return (
		value is Dictionary
		and value.has("x")
		and value.has("y")
		and _is_number(value["x"])
		and _is_number(value["y"])
		and is_finite(float(value["x"]))
		and is_finite(float(value["y"]))
	)


func _is_integer(value: Variant) -> bool:
	return (
		typeof(value) == TYPE_INT
		or (
			typeof(value) == TYPE_FLOAT
			and is_finite(value)
			and is_equal_approx(float(value), roundf(float(value)))
		)
	)


func _is_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT]
