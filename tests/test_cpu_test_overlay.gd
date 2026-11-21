extends SceneTree

const NAV_GRAPH := preload("res://src/models/player/nav_graph.gd")
const NAV_GRAPH_OVERLAY := preload("res://src/models/player/nav_graph_overlay.gd")
const CPU_DEBUG_PANEL := preload("res://src/scenes/ui/debug/cpu_debug_panel.gd")
const CPU_DECISION_SNAPSHOT := preload("res://src/models/player/cpu_decision_snapshot.gd")
const CPU_INTENT := preload("res://src/models/player/cpu_intent.gd")


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
	graph.load_graph(
		{
			"schema_version": 1,
			"level": "overlay-test",
			"nodes": [
				{"id": 1, "position": {"x": 10.0, "y": 20.0}},
				{"id": 2, "position": {"x": 30.0, "y": 20.0}},
			],
			"edges": [{"from": 1, "to": 2, "action": "WALK", "cost": 1.0}],
		},
		"overlay-test"
	)
	var intent: CPUIntent = CPU_INTENT.new()
	intent.horizontal = 1.0
	intent.jump = true
	var snapshot = CPU_DECISION_SNAPSHOT.new()
	snapshot.capture(
		"POSITION",
		"Following graph path.",
		Vector2(30.0, 20.0),
		1,
		PackedInt64Array([1, 2]),
		PackedInt64Array([1]),
		1,
		2,
		"WALK",
		intent,
		"Interception target changed.",
		PackedVector2Array([Vector2(24.0, 10.0), Vector2(24.0, 20.0)])
	)
	var overlay: NavGraphOverlay = NAV_GRAPH_OVERLAY.new()
	var panel = CPU_DEBUG_PANEL.new()
	root.add_child(overlay)
	root.add_child(panel)
	await process_frame
	overlay.set_graph(graph)
	overlay.set_snapshot(snapshot)
	panel.set_snapshot(snapshot)
	panel.layer_toggled.connect(overlay.set_layer_visible)
	if not _expect(
		overlay.visible
		and overlay.route == PackedInt64Array([1, 2])
		and overlay.previous_route == PackedInt64Array([1])
		and overlay.target_position == Vector2(30.0, 20.0)
		and overlay.predicted_trajectory.size() == 2
		and panel.state_label.text == "STATE: POSITION"
		and panel.reason_label.text == "WHY: Following graph path."
		and panel.edge_label.text == "EDGE: 1>2 WALK"
		and panel.intent_label.text == "I H1 J1 D0",
		"CPU debug overlay or panel did not display its decision snapshot."
	):
		return
	panel._on_layer_toggled(false, "graph")
	if not _expect(
		not overlay.show_graph and overlay.show_active_route and overlay.show_target,
		"Graph visibility toggle changed unrelated debug layers."
	):
		return
	panel._on_layer_toggled(false, "active_route")
	if not _expect(
		not overlay.show_graph
		and not overlay.show_active_route
		and overlay.show_previous_route
		and overlay.show_trajectory,
		"Active route toggle was not independent from other layers."
	):
		return
	print("CPU debug panel and visualization expose live snapshots with independent layer toggles.")
	quit()
