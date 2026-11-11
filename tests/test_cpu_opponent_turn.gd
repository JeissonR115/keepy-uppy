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
	main_scene.get_node("PlayerCountMenu")._select_level("classic")
	await process_frame

	var arena: Node = main_scene.get_node("Arena")
	var player: PlayerController = arena.get_node("Player2")
	var opponent: PlayerController = arena.get_node("Player1")
	var manager: MatchManager = arena.get_node("MatchManager")
	var balloon: BalloonController = arena.get_node("Balloon")
	var cpu: CPUController = player.get_node("CPUController")
	player.bot_enabled = true
	cpu.reaction_time = 0.0
	cpu.aggression_level = 1.0
	manager.match_seed_override = 271828
	manager.restart_match()
	manager.match_state = MatchManager.MatchState.ACTIVE
	manager.expected_balloon_player = opponent

	player.global_position = Vector2(160.0, 144.0)
	opponent.global_position = Vector2(72.0, 144.0)
	balloon.waiting_for_first_touch = false
	balloon.global_position = Vector2(160.0, 48.0)
	balloon.gravity_scale = 0.14
	balloon.linear_velocity = Vector2(0.0, 100.0)
	cpu.reset()
	cpu.update_decision(1.0)
	if not _expect(
		cpu.state == CPUController.State.CPU_TURNO_RIVAL
		and cpu.horizontal_intent > 0.0
		and not cpu.dash_requested,
		"CPU did not prioritize safe lateral movement when the balloon path threatened it."
	):
		return

	manager.match_state = MatchManager.MatchState.ACTIVE
	manager.expected_balloon_player = opponent
	manager.register_normal_hit(player)
	manager.resolve_pending_contacts()
	if not _expect(
		manager.round_faulting_player == player,
		"CPU contact during the rival's turn bypassed normal out-of-turn fault validation."
	):
		return

	manager.match_state = MatchManager.MatchState.ACTIVE
	manager.round_faulting_player = null
	manager.expected_balloon_player = opponent
	player.global_position = Vector2(200.0, 144.0)
	opponent.global_position = Vector2(150.0, 144.0)
	balloon.global_position = Vector2(280.0, 48.0)
	balloon.linear_velocity = Vector2.ZERO
	cpu.reset()
	cpu.update_decision(1.0)
	if not _expect(
		cpu.obstruction_selected and cpu.horizontal_intent > 0.0,
		"CPU did not move toward a safe position between the rival and balloon."
	):
		return
	var obstruction_start_x := player.global_position.x
	for _frame in range(10):
		await physics_frame
	if not _expect(
		player.global_position.x > obstruction_start_x,
		"CPU obstruction intent did not use the player's normal movement."
	):
		return

	cpu.aggression_level = 0.0
	cpu.reset()
	cpu.update_decision(1.0)
	if not _expect(
		not cpu.obstruction_selected and is_zero_approx(cpu.horizontal_intent),
		"CPU moved to obstruct when aggression selected a neutral rival-turn position."
	):
		return

	player.global_position = Vector2(160.0, 144.0)
	opponent.global_position = Vector2(72.0, 144.0)
	balloon.global_position = Vector2(160.0, 130.0)
	balloon.linear_velocity = Vector2.ZERO
	cpu.aggression_level = 1.0
	cpu.reset()
	cpu.update_decision(1.0)
	if not _expect(
		cpu.horizontal_intent > 0.0 and cpu.obstruction_selected,
		"CPU attempted obstruction instead of evading an immediate balloon threat."
	):
		return

	print("CPU rival-turn evasion, safe obstruction, and normal fault validation verified.")
	quit()
