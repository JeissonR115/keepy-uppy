extends SceneTree

const NAV_GRAPH := preload("res://src/models/player/nav_graph.gd")


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _run_test() -> void:
	var graph := NAV_GRAPH.new()
	var valid_graph := {
		"schema_version": 1,
		"level": "classic",
		"nodes": [
			{"id": 1, "position": {"x": 0.0, "y": 0.0}},
			{"id": 2, "position": {"x": 1.0, "y": 0.0}},
			{"id": 3, "position": {"x": 0.0, "y": 2.0}},
			{"id": 4, "position": {"x": 2.0, "y": 0.0}},
		],
		"edges": [
			{"from": 1, "to": 4, "action": "WALK", "cost": 10.0},
			{"from": 1, "to": 2, "action": "JUMP", "cost": 1.0},
			{"from": 2, "to": 4, "action": "DASH", "cost": 1.0},
			{"from": 1, "to": 3, "action": "DROP", "cost": 1.0, "bidirectional": true},
			{"from": 3, "to": 4, "action": "WALL_JUMP", "cost": 5.0},
		],
	}
	if not _expect(graph.load_graph(valid_graph, "classic"), "Valid graph did not load."):
		return
	var path: PackedInt64Array = graph.get_id_path(1, 4)
	if not _expect(
		path == PackedInt64Array([1, 2, 4])
		and graph.get_edge_action(1, 2) == "JUMP"
		and graph.get_edge_action(2, 4) == "DASH"
		and is_equal_approx(graph.get_edge_cost(1, 2), 1.0),
		"Graph routing did not respect weighted edges or action metadata."
	):
		return
	if not _expect(
		graph.get_id_path(4, 1).is_empty()
		and graph.get_edge_action(3, 1) == "DROP"
		and graph.get_edge_count() == 6,
		"Graph did not preserve directed and bidirectional connections."
	):
		return

	var invalid_graph := valid_graph.duplicate(true)
	invalid_graph["edges"][0]["to"] = 999
	if not _expect(
		not graph.load_graph(invalid_graph, "classic")
		and not graph.last_error.is_empty()
		and graph.get_id_path(1, 4) == PackedInt64Array([1, 2, 4])
		and graph.level_id == "classic",
		"Invalid graph load replaced the active graph or omitted its error."
	):
		return
	if not _expect(
		not graph.load_graph(valid_graph, "sky-towers")
		and graph.get_id_path(1, 4) == PackedInt64Array([1, 2, 4]),
		"Level mismatch replaced the active graph."
	):
		return
	print("NavGraph validates, weights routes, preserves direction, and retains the prior graph on errors.")
	quit()
