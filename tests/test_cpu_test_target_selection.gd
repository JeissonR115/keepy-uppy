extends SceneTree

const NAV_GRAPH := preload("res://src/models/player/nav_graph.gd")
const TARGET_SELECTOR := preload("res://src/models/player/cpu_node_target_selector.gd")


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
	var data := {
		"schema_version": 1,
		"level": "target-test",
		"nodes": [
			{"id": 1, "position": {"x": 0.0, "y": 0.0}},
			{"id": 2, "position": {"x": 10.0, "y": 0.0}},
			{"id": 3, "position": {"x": 8.0, "y": 0.0}},
			{"id": 4, "position": {"x": 10.0, "y": 10.0}},
		],
		"edges": [
			{"from": 1, "to": 2, "action": "WALK", "cost": 1.0, "bidirectional": true},
			{"from": 2, "to": 4, "action": "JUMP", "cost": 2.0},
		]
	}
	if not _expect(graph.load_graph(data, "target-test"), "Target selection fixture graph failed to load."):
		return
	var choice: Dictionary = TARGET_SELECTOR.select_target(
		graph, Vector2(0.5, 0.0), Vector2(8.1, 0.0)
	)
	if not _expect(
		choice["found"]
		and choice["start_node"] == 1
		and choice["target_node"] == 2
		and choice["route"] == PackedInt64Array([1, 2]),
		"Selector chose the nearest geometric node even though it is disconnected."
	):
		return
	var tie_choice: Dictionary = TARGET_SELECTOR.select_target(
		graph, Vector2(0.0, 0.0), Vector2(10.0, 5.0)
	)
	if not _expect(
		tie_choice["target_node"] == 2,
		"Equal-distance target selection did not use deterministic path-cost/node-id tie breaks."
	):
		return
	var empty := NAV_GRAPH.new()
	var no_target: Dictionary = TARGET_SELECTOR.select_target(empty, Vector2.ZERO, Vector2.ONE)
	if not _expect(not no_target["found"], "Empty graphs must not produce a target."):
		return
	print("CPU target selection chooses reachable nodes and uses stable path-cost and id tie breaks.")
	quit()
