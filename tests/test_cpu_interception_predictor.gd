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
	var cpu: CPUController = player.get_node("CPUController")
	var balloon: BalloonController = arena.get_node("Balloon")
	var level_manager: LevelManager = arena.get_node("LevelManager")
	var arena_data: ArenaData = level_manager.get_selected_arena() as ArenaData
	var radius := balloon.balloon_collision_radius
	var world_bounds := arena_data.playable_bounds
	var balloon_bounds := Rect2(
		world_bounds.position + Vector2.ONE * radius,
		world_bounds.size - Vector2.ONE * radius * 2.0
	)
	balloon.gravity_scale = balloon.gravity_strength
	balloon.air_resistance = 0.0
	balloon.horizontal_damping = 0.0

	balloon.global_position = Vector2(160.0, 48.0)
	balloon.waiting_for_first_touch = true
	var waiting_prediction := cpu.predict_interception(120.0)
	if not _expect(
		not waiting_prediction["found"] and is_zero_approx(waiting_prediction["time"]),
		"Predictor returned an interception before the balloon's first touch."
	):
		return

	balloon.waiting_for_first_touch = false
	balloon.global_position = Vector2(160.0, 100.0)
	balloon.gravity_scale = 0.0
	balloon.linear_velocity = Vector2(0.0, 60.0)
	var interpolation_prediction := cpu.predict_interception(110.0, 0.5)
	if not _expect(
		interpolation_prediction["found"]
		and absf(interpolation_prediction["time"] - (1.0 / 6.0)) < 0.002,
		"Predictor did not interpolate the target crossing time within a physics step."
	):
		return

	balloon.global_position = Vector2(298.0, 48.0)
	balloon.linear_velocity = Vector2(120.0, 0.0)
	balloon.gravity_scale = balloon.gravity_strength
	var wall_prediction := cpu.predict_interception(120.0)
	if not _expect(
		wall_prediction["found"] and wall_prediction["position"].x < balloon_bounds.end.x,
		"Predictor did not constrain the interception after a side-wall rebound."
	):
		return

	balloon.global_position = Vector2(160.0, 20.0)
	balloon.linear_velocity = Vector2(0.0, -120.0)
	var ceiling_prediction := cpu.predict_interception(48.0, 1.5)
	if not _expect(
		ceiling_prediction["found"]
		and ceiling_prediction["position"].y == 48.0
		and ceiling_prediction["time"] > 0.0,
		"Predictor did not simulate a ceiling rebound before interception."
	):
		return

	balloon.global_position = Vector2(160.0, 48.0)
	balloon.linear_velocity = Vector2.ZERO
	var beyond_ground_prediction := cpu.predict_interception(balloon_bounds.end.y + 1.0)
	if not _expect(
		not beyond_ground_prediction["found"],
		"Predictor reported a target below the playable ground boundary."
	):
		return

	var invalid_target := cpu.predict_interception(NAN)
	var invalid_horizon := cpu.predict_interception(120.0, NAN)
	var negative_horizon := cpu.predict_interception(120.0, -1.0)
	if not _expect(
		not invalid_target["found"]
		and not invalid_horizon["found"]
		and not negative_horizon["found"]
		and invalid_target["position"].is_finite(),
		"Predictor accepted a non-finite target or invalid horizon."
	):
		return

	balloon.linear_velocity = Vector2(NAN, 0.0)
	var invalid_velocity := cpu.predict_interception(120.0)
	balloon.linear_velocity = Vector2.ZERO
	if not _expect(
		not invalid_velocity["found"] and invalid_velocity["position"].is_finite(),
		"Predictor did not fall back safely for non-finite balloon velocity."
	):
		return

	print("CPU predictor first-touch, interpolation, rebounds, ground cutoff, and invalid-input checks passed.")
	quit()
