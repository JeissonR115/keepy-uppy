extends SceneTree


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
	await process_frame

	var arena: Node = main_scene.get_node("Arena")
	var player: PlayerController = arena.get_node("Player2")
	var manager: MatchManager = arena.get_node("MatchManager")
	var balloon: BalloonController = arena.get_node("Balloon")
	var cpu: CPUController = player.get_node("CPUController")
	player.bot_enabled = true
	manager.coin_toss_override = 0
	manager.match_seed_override = 271828
	manager.restart_match()
	manager.expected_balloon_player = player
	balloon.waiting_for_first_touch = true
	balloon.global_position = Vector2(160.0, 48.0)

	cpu.reaction_time = 9.0
	cpu.prediction_error_margin = 100.0
	cpu.aggression_level = 2.0
	cpu.dash_threshold_distance = -1.0
	cpu.prediction_horizon = 20.0
	if not _expect(
		is_equal_approx(cpu.reaction_time, 2.0)
		and is_equal_approx(cpu.prediction_error_margin, 64.0)
		and is_equal_approx(cpu.aggression_level, 1.0)
		and is_equal_approx(cpu.dash_threshold_distance, 0.0)
		and is_equal_approx(cpu.prediction_horizon, 5.0),
		"CPU difficulty properties did not clamp out-of-range values."
	):
		return

	cpu.prediction_error_margin = 24.0
	cpu.reaction_time = 0.12
	cpu.reset()
	cpu.update_decision(0.01)
	if not _expect(
		cpu.horizontal_intent == 0.0,
		"CPU ignored the configured reaction delay on entering its turn."
	):
		return
	for _frame in range(20):
		cpu.update_decision(0.01)
	if not _expect(
		cpu.horizontal_intent < 0.0,
		"CPU did not begin moving toward the opening balloon after its reaction delay."
	):
		return

	balloon.waiting_for_first_touch = false
	balloon.gravity_scale = 0.14
	balloon.linear_velocity = Vector2.ZERO
	cpu.reaction_time = 0.0
	cpu.dash_threshold_distance = 10.0
	cpu.update_decision(1.0)
	if not _expect(
		cpu.dash_requested and not cpu.dash_direction.is_zero_approx(),
		"CPU did not request a ready dash when its interception was beyond the threshold."
	):
		return
	for _frame in range(2):
		await physics_frame
	if not _expect(
		not player.dash_available and player.movement_state == PlayerController.MovementState.DASH,
		"PlayerController did not execute the CPU's dash intent through the normal dash state."
	):
		return
	cpu.dash_threshold_distance = 200.0
	cpu.update_decision(1.0)
	if not _expect(
		not cpu.dash_requested,
		"CPU ignored an increased dash distance threshold."
	):
		return

	manager.expected_balloon_player = arena.get_node("Player1")
	cpu.aggression_level = 0.0
	cpu.update_decision(1.0)
	if not _expect(
		not cpu.obstruction_selected,
		"Zero aggression selected obstruction."
	):
		return
	cpu.aggression_level = 1.0
	if not _expect(
		cpu.obstruction_selected,
		"Maximum aggression did not select obstruction."
	):
		return

	manager.match_seed_override = 314159
	manager.restart_match()
	manager.expected_balloon_player = player
	balloon.waiting_for_first_touch = true
	balloon.global_position = Vector2(160.0, 48.0)
	cpu.prediction_error_margin = 24.0
	cpu.update_decision(1.0)
	var first_seed_offset := cpu.prediction_error_offset
	manager.restart_match()
	manager.expected_balloon_player = player
	balloon.waiting_for_first_touch = true
	balloon.global_position = Vector2(160.0, 48.0)
	cpu.update_decision(1.0)
	if not _expect(
		cpu.prediction_error_offset.is_equal_approx(first_seed_offset)
		and first_seed_offset.length() <= cpu.prediction_error_margin,
		"Identical match seeds did not reproduce a bounded prediction error."
	):
		return

	manager.match_seed_override = 314160
	manager.restart_match()
	manager.expected_balloon_player = player
	balloon.waiting_for_first_touch = true
	balloon.global_position = Vector2(160.0, 48.0)
	cpu.update_decision(1.0)
	if not _expect(
		not cpu.prediction_error_offset.is_equal_approx(first_seed_offset),
		"Changing the match seed did not change the CPU prediction error."
	):
		return

	print("CPU difficulty bounds, reaction, dash execution, aggression, and seeded decisions verified.")
	quit()
