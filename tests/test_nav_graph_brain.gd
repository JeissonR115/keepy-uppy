extends SceneTree

const NAV_GRAPH := preload("res://src/models/player/nav_graph.gd")
const NAV_GRAPH_BRAIN := preload("res://src/models/player/nav_graph_brain.gd")
const SURFACE_TECHNIQUES := preload("res://src/models/player/player_surface_techniques.gd")


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
	main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	).pressed.emit()
	main_scene.get_node("PlayerCountMenu")._select_level("classic")
	await process_frame
	await physics_frame

	var arena: Node = main_scene.get_node("Arena")
	var player := arena.get_node("Player2") as PlayerController
	var manager := arena.get_node("MatchManager") as MatchManager
	player.bot_enabled = false
	manager.match_state = MatchManager.MatchState.ACTIVE
	manager.accepting_gameplay_input = true
	manager.round_intermission = 0.0
	player.reset_for_round(Vector2(160.0, 152.0))
	for _frame in range(3):
		await physics_frame
	if not _expect(player.is_on_floor(), "Navigation test player did not settle on the floor."):
		return

	var walk_intent := _decide_edge(player, "WALK", Vector2(-32.0, 0.0))
	if not _expect(
		walk_intent != null and walk_intent.horizontal < 0.0
		and not walk_intent.jump and not walk_intent.dash,
		"WALK edge did not produce movement toward its destination."
	):
		return
	var walk_start_x := player.global_position.x
	player.bot_enabled = true
	player.cpu_controller.set_brain(_edge_brain(player, "WALK", Vector2(-32.0, 0.0)))
	await physics_frame
	player.bot_enabled = false
	if not _expect(
		player.global_position.x < walk_start_x,
		"PlayerController did not move along the CPU WALK intent."
	):
		return

	player.reset_for_round(Vector2(160.0, 152.0))
	for _frame in range(3):
		await physics_frame
	var jump_intent := _decide_edge(player, "JUMP", Vector2(0.0, -40.0))
	if not _expect(
		jump_intent != null and jump_intent.jump,
		"JUMP edge did not produce a jump request from the floor."
	):
		return
	player.bot_enabled = true
	player.cpu_controller.set_brain(_edge_brain(player, "JUMP", Vector2(0.0, -40.0)))
	await physics_frame
	if not _expect(player.velocity.y < 0.0, "PlayerController did not jump along the CPU route."):
		return

	player.bot_enabled = false
	player.reset_for_round(Vector2(160.0, 152.0))
	for _frame in range(3):
		await physics_frame
	player.dash_available = true
	player.dash_cooldown_timer = 0.0
	var dash_intent := _decide_edge(player, "DASH", Vector2(32.0, -32.0))
	if not _expect(
		dash_intent != null
		and dash_intent.dash
		and dash_intent.dash_direction.is_equal_approx(Vector2(1.0, -1.0).normalized()),
		"DASH edge did not produce a normalized directional dash request."
	):
		return
	player.bot_enabled = true
	player.cpu_controller.set_brain(_edge_brain(player, "DASH", Vector2(32.0, -32.0)))
	await physics_frame
	if not _expect(
		player.movement_state == PlayerController.MovementState.DASH,
		"PlayerController did not begin the CPU DASH action."
	):
		return

	player.bot_enabled = false
	var platform := StaticBody2D.new()
	platform.position = Vector2(160.0, 100.0)
	platform.collision_layer = 4
	platform.add_to_group("one_way_platform")
	var platform_shape := CollisionShape2D.new()
	platform_shape.one_way_collision = true
	var platform_rectangle := RectangleShape2D.new()
	platform_rectangle.size = Vector2(40.0, 4.0)
	platform_shape.shape = platform_rectangle
	platform.add_child(platform_shape)
	arena.add_child(platform)
	player.reset_for_round(Vector2(160.0, 90.0))
	player.velocity = Vector2(0.0, 60.0)
	for _frame in range(8):
		await physics_frame
	if not _expect(
		player.is_on_floor() and SURFACE_TECHNIQUES.is_on_one_way_platform(player),
		"Navigation test player did not land on the one-way platform."
	):
		return
	var drop_intent := _decide_edge(player, "DROP", Vector2(0.0, 40.0))
	if not _expect(
		drop_intent != null and drop_intent.down and drop_intent.jump,
		"DROP edge did not request down+jump on a one-way platform."
	):
		return
	player.bot_enabled = true
	player.cpu_controller.set_brain(_edge_brain(player, "DROP", Vector2(0.0, 40.0)))
	await physics_frame
	if not _expect(
		player.platform_drop_timer > 0.0
		and not player.get_collision_mask_value(3),
		"PlayerController did not drop through the platform along the CPU route."
	):
		return

	player.bot_enabled = false
	var wall := StaticBody2D.new()
	wall.position = Vector2(8.0, 80.0)
	wall.collision_layer = 1
	var wall_shape := CollisionShape2D.new()
	var wall_rectangle := RectangleShape2D.new()
	wall_rectangle.size = Vector2(2.0, 500.0)
	wall_shape.shape = wall_rectangle
	wall.add_child(wall_shape)
	arena.add_child(wall)
	player.reset_for_round(Vector2(14.0, 80.0))
	for _frame in range(2):
		await physics_frame
	var wall_jump_intent := _decide_edge(player, "WALL_JUMP", Vector2(0.0, -40.0))
	if not _expect(
		wall_jump_intent != null
		and wall_jump_intent.jump
		and wall_jump_intent.horizontal > 0.0,
		"WALL_JUMP edge did not jump away from the contacted wall."
	):
		return
	player.bot_enabled = true
	player.cpu_controller.set_brain(_edge_brain(player, "WALL_JUMP", Vector2(0.0, -40.0)))
	await physics_frame
	if not _expect(
		player.velocity.y < 0.0,
		"PlayerController did not wall-jump along the CPU route."
	):
		return

	main_scene.queue_free()
	await process_frame
	print("NavGraphBrain executes WALK, JUMP, DASH, DROP, and WALL_JUMP through PlayerController.")
	quit()


func _decide_edge(
	player: PlayerController, action: String, destination_offset: Vector2
) -> CPUIntent:
	return _edge_brain(player, action, destination_offset).decide(1.0 / 60.0)


func _edge_brain(
	player: PlayerController, action: String, destination_offset: Vector2
) -> CPUBrain:
	var graph = NAV_GRAPH.new()
	var start_position := player.global_position
	if not graph.load_graph(
		{
			"schema_version": 1,
			"level": "classic",
			"nodes": [
				{"id": 1, "position": {"x": start_position.x, "y": start_position.y}},
				{
					"id": 2,
					"position": {
						"x": start_position.x + destination_offset.x,
						"y": start_position.y + destination_offset.y,
					},
				},
			],
			"edges": [{"from": 1, "to": 2, "action": action, "cost": 1.0}],
		}
	):
		push_error("Navigation test graph failed to load for %s." % action)
		quit(1)
		return null
	var brain = NAV_GRAPH_BRAIN.new()
	if not brain.configure(player, graph, 1, 2):
		push_error("Navigation test route failed to configure: %s" % brain.last_error)
		quit(1)
		return null
	return brain
