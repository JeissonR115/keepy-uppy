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


func _graph(nodes: Array[Dictionary], edges: Array[Dictionary]) -> NavGraph:
	var graph := NAV_GRAPH.new()
	graph.load_graph(
		{"schema_version": 1, "level": "brain-test", "nodes": nodes, "edges": edges},
		"brain-test"
	)
	return graph


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
	var cpu := TEST_CPU_BRAIN.new(player)
	player.bot_enabled = true
	player.global_position = Vector2(160.0, 144.0)
	manager.match_state = MatchManager.MatchState.ACTIVE
	manager.expected_balloon_player = player
	balloon.player_contacts_armed = true
	balloon.waiting_for_first_touch = true
	balloon.global_position = Vector2(160.0, 114.0)
	player.cpu_controller.set_brain(cpu)
	cpu.decide(1.0 / 60.0)
	if not _expect(
		cpu.get_decision_state_name() == "SERVE"
		and not player.cpu_balloon_contact_suppressed,
		"CPU did not enter the safe SERVE state for the suspended first touch."
	):
		return

	manager.expected_balloon_player = manager.player_1
	cpu.decide(1.0 / 60.0)
	if not _expect(
		cpu.get_decision_state_name() == "AVOID"
		and player.cpu_balloon_contact_suppressed
		and not balloon.apply_dash_rescue(player, Vector2.UP),
		"CPU did not avoid and suppress a balloon contact during the rival's turn."
	):
		return
	balloon._on_player_contact_area_body_entered(player)
	if not _expect(
		manager.pending_normal_hits.is_empty(),
		"A normal CPU contact was registered during the rival's turn."
	):
		return

	manager.expected_balloon_player = player
	balloon.waiting_for_first_touch = false
	balloon.gravity_scale = 0.0
	balloon.global_position = Vector2(160.0, 120.0)
	balloon.linear_velocity = Vector2(0.0, 60.0)
	var start := player.global_position
	var hit_graph := _graph(
		[
			{"id": 1, "position": {"x": start.x, "y": start.y}},
			{"id": 2, "position": {"x": start.x, "y": start.y - 12.0}},
		],
		[{"from": 1, "to": 2, "action": "JUMP", "cost": 1.0, "bidirectional": true}]
	)
	cpu.set_graph(hit_graph)
	player.cpu_controller.set_brain(cpu)
	cpu.decide(1.0 / 60.0)
	if not _expect(
		cpu.get_decision_state_name() == "HIT"
		and not player.cpu_balloon_contact_suppressed,
		"CPU did not select HIT for a safe upward interception."
	):
		return

	var position_graph := _graph(
		[
			{"id": 1, "position": {"x": start.x, "y": start.y}},
			{"id": 2, "position": {"x": 200.0, "y": start.y}},
			{"id": 3, "position": {"x": 240.0, "y": start.y - 12.0}},
		],
		[
			{"from": 1, "to": 2, "action": "WALK", "cost": 1.0, "bidirectional": true},
			{"from": 2, "to": 3, "action": "WALK", "cost": 1.0, "bidirectional": true},
		]
	)
	cpu.set_graph(position_graph)
	balloon.global_position = Vector2(240.0, 50.0)
	balloon.linear_velocity = Vector2(0.0, 60.0)
	var position_intent: CPUIntent = cpu.decide(1.0 / 60.0)
	var original_route_reason := cpu.last_route_change_reason
	if not _expect(
		cpu.get_decision_state_name() == "POSITION"
		and cpu.target_node == 3
		and position_intent.horizontal > 0.0,
		"CPU did not navigate the graph toward a distant interception."
	):
		return
	balloon.global_position.x = 241.0
	cpu.decide(1.0 / 60.0)
	if not _expect(
		cpu.target_node == 3 and cpu.last_route_change_reason == original_route_reason,
		"CPU recomputed its route while the predicted destination remained in the same node."
	):
		return
	balloon.global_position.x = 200.0
	cpu.decide(1.0 / 60.0)
	if not _expect(
		cpu.target_node == 2 and cpu.previous_route == PackedInt64Array([1, 2, 3]),
		"CPU did not update its route and retain the previous route when the target node changed."
	):
		return

	balloon.global_position = Vector2(160.0, 156.0)
	balloon.linear_velocity = Vector2.ZERO
	cpu.decide(1.0 / 60.0)
	if not _expect(
		player.cpu_balloon_contact_suppressed,
		"CPU did not suppress an unsafe downward normal contact."
	):
		return
	balloon.global_position = Vector2(160.0, 114.0)
	balloon.waiting_for_first_touch = false
	cpu.set_graph(null)
	cpu.decide(1.0 / 60.0)
	if not _expect(
		cpu.fallback_brain != null
		and cpu.reason == "No valid graph is loaded for this arena.",
		"A missing navigation graph did not activate the local CPU fallback."
	):
		return
	print("Test CPU brain covers serve, route positioning, hit safety, turn avoidance, and target changes.")
	quit()
