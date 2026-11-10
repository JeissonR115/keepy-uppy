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
	var settings_manager: Node = main_scene.get_node("ControlSettingsManager")
	settings_manager.settings_path = "/tmp/keepy-accelerate-controls.cfg"
	root.add_child(main_scene)
	await process_frame

	var arena: Node = main_scene.get_node("Arena")
	var player_1: CharacterBody2D = arena.get_node("Player1")
	var player_2: CharacterBody2D = arena.get_node("Player2")
	if not _expect(
		is_equal_approx(player_1.accelerate_duration, 0.8)
		and is_equal_approx(player_1.accelerate_speed_multiplier, 1.35)
		and is_equal_approx(player_1.accelerate_cooldown, 4.0)
		and is_equal_approx(player_1.accelerate_max_speed, 210.0),
		"Approved default accelerate tuning was changed."
	):
		return

	for player: CharacterBody2D in [player_1, player_2]:
		player.max_run_speed = 120.0
		player.ground_acceleration = 1000.0
		player.ground_deceleration = 1000.0
		player.accelerate_speed_multiplier = 1.5
		player.accelerate_duration = 0.25
		player.accelerate_cooldown = 0.7
		player.accelerate_max_speed = 150.0
		player.global_position = Vector2(70 if player == player_1 else 250, 152)
		player.velocity = Vector2.ZERO
	await physics_frame
	Input.action_press("player_1_right")
	Input.action_press("player_2_right")
	Input.action_press("player_1_accelerate")
	for _frame in range(10):
		await physics_frame
	if not _expect(
		player_1.accelerate_timer > 0.0
		and player_1.velocity.x > player_2.velocity.x
		and player_1.velocity.x <= player_1.accelerate_max_speed + 0.1
		and player_2.accelerate_timer == 0.0,
		"Player 1 boost did not exceed ordinary run speed within its cap independently of Player 2."
	):
		return
	Input.action_release("player_1_accelerate")
	Input.action_release("player_2_right")
	for _frame in range(12):
		await physics_frame
	if not _expect(
		is_zero_approx(player_1.accelerate_timer)
		and player_1.accelerate_cooldown_timer > 0.0
		and player_1.velocity.x <= player_1.max_run_speed + 0.1,
		"Boost duration did not expire back to ordinary run speed while cooldown remained active."
	):
		return

	Input.action_press("player_1_accelerate")
	await physics_frame
	Input.action_release("player_1_accelerate")
	if not _expect(
		is_zero_approx(player_1.accelerate_timer)
		and not player_1.try_activate_accelerate(),
		"Accelerate started again during its cooldown."
	):
		return

	Input.action_press("player_2_right")
	Input.action_press("player_2_accelerate")
	for _frame in range(3):
		await physics_frame
	if not _expect(
		player_2.accelerate_timer > 0.0
		and is_zero_approx(player_1.accelerate_timer)
		and player_1.accelerate_cooldown_timer > 0.0
		and player_2.velocity.x <= player_2.accelerate_max_speed + 0.1,
		"Player 2 boost was coupled to Player 1's cooldown or exceeded its own speed cap."
	):
		return
	Input.action_release("player_2_accelerate")

	for _frame in range(48):
		await physics_frame
	if not _expect(
		player_1.try_activate_accelerate()
		and player_1.accelerate_timer > 0.0
		and player_1.accelerate_cooldown_timer > 0.0,
		"Accelerate did not become available again after its cooldown."
	):
		return

	Input.action_release("player_1_accelerate")
	Input.action_release("player_1_right")
	Input.action_release("player_2_right")
	print("Accelerate defaults, independent boost, duration, cooldown, normal-speed return, and speed cap verified.")
	quit()
