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
	var cpu: CPUController = player.get_node("CPUController")
	var balloon: BalloonController = arena.get_node("Balloon")
	var manager: MatchManager = arena.get_node("MatchManager")
	cpu.reaction_time = 0.0
	player.bot_enabled = true
	manager.expected_balloon_player = player
	balloon.global_position = Vector2(160.0, 48.0)
	balloon.waiting_for_first_touch = true
	cpu.update_decision()
	if not _expect(
		cpu.horizontal_intent < 0.0,
		"CPU did not pursue the balloon while waiting for the opening touch."
	):
		return

	balloon.waiting_for_first_touch = false
	balloon.gravity_scale = 0.14
	balloon.linear_velocity = Vector2.ZERO
	var falling_prediction := cpu.predict_interception(120.0)
	if not _expect(
		falling_prediction["found"]
		and absf(falling_prediction["position"].y - 120.0) < 0.01
		and falling_prediction["time"] > 0.0
		and falling_prediction["time"] <= CPUController.DEFAULT_PREDICTION_HORIZON,
		"Predictor did not find a bounded falling-balloon interception."
	):
		return

	balloon.global_position = Vector2(298.0, 48.0)
	balloon.linear_velocity = Vector2(120.0, 0.0)
	var wall_prediction := cpu.predict_interception(120.0)
	if not _expect(
		wall_prediction["found"] and wall_prediction["position"].x < 303.0,
		"Predictor did not account for a known side-wall rebound."
	):
		return

	balloon.global_position = Vector2(160.0, 48.0)
	balloon.linear_velocity = Vector2.ZERO
	var beyond_ground_prediction := cpu.predict_interception(160.0)
	if not _expect(
		not beyond_ground_prediction["found"],
		"Predictor returned an interception below the scoring-ground boundary."
	):
		return

	var invalid_prediction := cpu.predict_interception(NAN)
	if not _expect(
		not invalid_prediction["found"]
		and invalid_prediction["position"].is_finite(),
		"Predictor did not reject invalid target data with a safe fallback."
	):
		return

	player.global_position = Vector2(160.0, 144.0)
	balloon.global_position = Vector2(160.0, 48.0)
	balloon.linear_velocity = Vector2.ZERO
	cpu.reset()
	cpu.update_decision(1.0)
	if not _expect(
		cpu.jump_requested,
		"CPU did not request a jump when the predicted interception was directly above it."
	):
		return

	print("CPU interception prediction, jump intent, wall rebound, ground limit, and invalid input verified.")
	quit()
