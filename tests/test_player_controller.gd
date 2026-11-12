extends SceneTree

const MovementConstants = preload("res://src/models/player/player_movement_constants.gd")


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false



func _run_test() -> void:
	if not _expect(
		ProjectSettings.get_setting("physics/common/physics_ticks_per_second") == 60,
		"Physics tick rate must be configured to 60 Hz."
	):
		return
	if not _expect(
		is_equal_approx(MovementConstants.MAX_RUN, 130.0)
		and is_equal_approx(MovementConstants.RUN_ACCEL, 1000.0)
		and is_equal_approx(MovementConstants.RUN_REDUCE, 600.0)
		and is_equal_approx(MovementConstants.GRAVITY, 1100.0)
		and is_equal_approx(MovementConstants.JUMP_SPEED, -200.0)
		and is_equal_approx(MovementConstants.DASH_SPEED, 300.0)
		and is_equal_approx(MovementConstants.DASH_TIME, 0.2)
		and is_equal_approx(MovementConstants.CLIMB_MAX_STAMINA, 110.0),
		"Player movement tuning constants do not match the movement guide."
	):
		return
	if not _expect(
		MovementConstants.CAPE_ROWS == 6
		and is_equal_approx(MovementConstants.CAPE_SEGMENT, 2.5)
		and is_equal_approx(MovementConstants.CAPE_GRAVITY, 250.0)
		and is_equal_approx(MovementConstants.CAPE_DAMPING, 0.90)
		and MovementConstants.CAPE_ITERATIONS == 4,
		"Cape tuning constants do not match the movement guide."
	):
		return
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	var two_players_button: Button = main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	)
	two_players_button.pressed.emit()
	main_scene.get_node("PlayerCountMenu")._select_level("classic")

	var arena: Node = main_scene.get_node("Arena")
	var player_1: CharacterBody2D = arena.get_node("Player1")
	var player_2: CharacterBody2D = main_scene.get_node("Arena/Player2")
	var player_1_start := player_1.global_position
	var player_2_start := player_2.global_position

	Input.action_press("player_1_right")
	Input.action_press("player_2_left")
	for _frame in range(3):
		await physics_frame
	if not _expect(absf(player_1.velocity.x) < 45.0, "Air control did not reduce acceleration."):
		return
	for _frame in range(9):
		await physics_frame

	if not _expect(player_1.global_position.x > player_1_start.x, "Player 1 did not move right."):
		return
	if not _expect(player_2.global_position.x < player_2_start.x, "Player 2 did not move left."):
		return
	var player_1_speed := absf(player_1.velocity.x)
	Input.action_release("player_1_right")
	Input.action_release("player_2_left")
	for _frame in range(4):
		await physics_frame
	if not _expect(absf(player_1.velocity.x) < player_1_speed, "Player 1 did not decelerate after input release."):
		return

	var remapped_right := InputEventKey.new()
	remapped_right.physical_keycode = KEY_F
	var previous_right_events := InputMap.action_get_events("player_1_right")
	InputMap.action_erase_events("player_1_right")
	InputMap.action_add_event("player_1_right", remapped_right)

	var simulated_key := remapped_right.duplicate() as InputEventKey
	simulated_key.pressed = true
	Input.parse_input_event(simulated_key)
	var remap_test_start := player_1.global_position
	for _frame in range(12):
		await physics_frame

	if not _expect(
		player_1.global_position.x > remap_test_start.x,
		"Player 1 did not respond to the remapped right action."
	):
		return
	simulated_key.pressed = false
	Input.parse_input_event(simulated_key)
	InputMap.action_erase_events("player_1_right")
	for event: InputEvent in previous_right_events:
		InputMap.action_add_event("player_1_right", event)

	print('Movement and remappable input verified.')
	quit()
