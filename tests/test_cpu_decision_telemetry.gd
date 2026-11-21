extends SceneTree

const NAV_GRAPH := preload("res://src/models/player/nav_graph.gd")
const TEST_CPU_BRAIN := preload("res://src/models/player/test_cpu_brain.gd")


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _run_test() -> void:
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	var menu: PlayerCountMenu = main_scene.get_node("PlayerCountMenu")
	menu._select_player_count(1)
	menu._select_level("classic")
	await process_frame
	root.get_tree().paused = true
	var arena: Node = main_scene.get_node("Arena")
	var player: PlayerController = arena.get_node("Player2")
	var manager: MatchManager = arena.get_node("MatchManager")
	var balloon: BalloonController = arena.get_node("Balloon")
	player.bot_enabled = true
	player.global_position = Vector2(160.0, 144.0)
	manager.match_state = MatchManager.MatchState.ACTIVE
	manager.expected_balloon_player = player
	balloon.waiting_for_first_touch = false
	balloon.gravity_scale = 0.0
	balloon.global_position = Vector2(240.0, 50.0)
	balloon.linear_velocity = Vector2(0.0, 60.0)
	var graph := NAV_GRAPH.new()
	graph.load_graph(
		{
			"schema_version": 1,
			"level": "telemetry-test",
			"nodes": [
				{"id": 1, "position": {"x": 160.0, "y": 144.0}},
				{"id": 2, "position": {"x": 200.0, "y": 144.0}},
				{"id": 3, "position": {"x": 240.0, "y": 132.0}},
			],
			"edges": [
				{"from": 1, "to": 2, "action": "WALK", "cost": 1.0, "bidirectional": true},
				{"from": 2, "to": 3, "action": "JUMP", "cost": 1.0, "bidirectional": true},
			]
		},
		"telemetry-test"
	)
	var brain = TEST_CPU_BRAIN.new(player, graph)
	player.cpu_controller.set_brain(brain)
	var intent: CPUIntent = brain.decide(1.0 / 60.0)
	var snapshot = brain.decision_snapshot
	if not _expect(
		snapshot != null
		and snapshot.state == "POSITION"
		and snapshot.reason == brain.reason
		and snapshot.current_node == 1
		and snapshot.route == PackedInt64Array([1, 2, 3])
		and snapshot.current_edge_from == 1
		and snapshot.current_edge_to == 2
		and snapshot.current_edge_action == "WALK"
		and snapshot.intent.horizontal == intent.horizontal
		and snapshot.route_change_reason == brain.last_route_change_reason
		and snapshot.predicted_trajectory.size() > 1,
		"CPU decision snapshot omitted or mismatched per-tick route telemetry."
	):
		return
	balloon.global_position.x = 200.0
	brain.decide(1.0 / 60.0)
	if not _expect(
		brain.decision_snapshot.route == PackedInt64Array([1, 2])
		and brain.decision_snapshot.previous_route == PackedInt64Array([1, 2, 3])
		and brain.decision_snapshot.route_change_reason != snapshot.route_change_reason,
		"Decision snapshot did not preserve the previous route and latest route-change reason."
	):
		return
	print("CPU decision snapshots expose independent per-tick state, intent, route and edge data.")
	quit()
