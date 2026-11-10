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

	var player_1: CharacterBody2D = main_scene.get_node("Arena/Player1")
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

	Input.action_press("player_1_right")
	Input.action_press("player_2_left")
	for _frame in range(60):
		await physics_frame
	if not _expect(player_1.is_on_floor() and player_2.is_on_floor(), "Players did not collide with the arena ground."):
		return
	if not _expect(player_1.global_position.x < player_2.global_position.x, "Players passed through each other."):
		return

	player_1.global_position = Vector2(72, 152)
	player_2.global_position = Vector2(248, 152)
	player_1.velocity = Vector2.ZERO
	player_2.velocity = Vector2.ZERO
	for _frame in range(3):
		await physics_frame
	Input.action_press("player_1_jump")
	Input.action_press("player_2_jump")
	await physics_frame
	await physics_frame
	Input.action_release("player_1_jump")
	for _frame in range(14):
		await physics_frame
	Input.action_release("player_2_jump")
	for _frame in range(20):
		await physics_frame
	if not _expect(player_2.global_position.y < player_1.global_position.y, "Holding jump did not increase jump height."):
		return

	for _frame in range(60):
		await physics_frame
	player_1.global_position = Vector2(108, 104)
	player_1.velocity = Vector2.ZERO
	for _frame in range(3):
		await physics_frame
	if not _expect(player_1.is_on_floor(), "Player 1 did not land on the test platform."):
		return
	Input.action_press("player_1_right")
	for _frame in range(20):
		await physics_frame
		if not player_1.is_on_floor():
			break
	for _frame in range(2):
		await physics_frame
	var jump_key := InputEventKey.new()
	jump_key.physical_keycode = 32
	jump_key.pressed = true
	Input.parse_input_event(jump_key)
	await physics_frame
	await physics_frame
	if not _expect(player_1.velocity.y < 0.0, "Coyote Time did not allow a jump after leaving the platform."):
		return
	jump_key.pressed = false
	Input.parse_input_event(jump_key)
	Input.action_release("player_1_right")

	for _frame in range(50):
		await physics_frame
	player_1.global_position = Vector2(170, 150)
	player_1.velocity = Vector2.ZERO
	await physics_frame
	if not _expect(not player_1.is_on_floor(), "Player 1 was not airborne before the buffered jump."):
		return
	var landing_start := player_1.global_position.y
	jump_key.pressed = true
	Input.parse_input_event(jump_key)
	for _frame in range(8):
		await physics_frame
	jump_key.pressed = false
	Input.parse_input_event(jump_key)
	if not _expect(
		player_1.global_position.y < landing_start or player_1.velocity.y < 0.0,
		"Jump Buffer did not trigger a jump on landing."
	):
		return

	print("Movement, jump assist, collisions, and Input Map remapping verified.")
	quit()
