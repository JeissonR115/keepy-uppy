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
	player_1.reset_for_round(Vector2(160, 152))
	for _frame in range(2):
		await physics_frame
	Input.action_press("player_1_right")
	var acceleration_frames := 0
	for _frame in range(12):
		await physics_frame
		acceleration_frames += 1
		if player_1.velocity.x >= MovementConstants.MAX_RUN:
			break
	Input.action_release("player_1_right")
	if not _expect(
		acceleration_frames <= 7
		and is_equal_approx(player_1.velocity.x, MovementConstants.MAX_RUN),
		"Ground acceleration did not reach run speed within 0.12 seconds."
	):
		return
	for _frame in range(12):
		await physics_frame
	if not _expect(
		is_zero_approx(player_1.velocity.x),
		"Ground movement did not stop within 0.2 seconds after releasing input."
	):
		return

	Input.action_press("player_1_right")
	for _frame in range(8):
		await physics_frame
	Input.action_release("player_1_right")
	Input.action_press("player_1_left")
	var reversal_frames := 0
	for _frame in range(20):
		await physics_frame
		reversal_frames += 1
		if player_1.velocity.x <= -MovementConstants.MAX_RUN:
			break
	Input.action_release("player_1_left")
	if not _expect(
		player_1.velocity.x <= -MovementConstants.MAX_RUN
		and absf(player_1.velocity.x) <= MovementConstants.MAX_RUN
		and reversal_frames <= 20,
		"Ground reversal exceeded its configured response or horizontal speed limit."
	):
		return

	print('Ground acceleration, braking, reversal, and horizontal speed limit verified.')
	quit()
