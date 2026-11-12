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
	var player_2: CharacterBody2D = main_scene.get_node("Arena/Player2")
	Input.action_release("player_1_right")
	Input.action_release("player_2_left")
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
	for _frame in range(6):
		await physics_frame
	if not _expect(player_2.global_position.y < player_1.global_position.y, "Holding jump did not increase jump height."):
		return
	Input.action_release("player_2_jump")
	for _frame in range(20):
		await physics_frame

	for _frame in range(60):
		await physics_frame
	var coyote_test_ledge := StaticBody2D.new()
	coyote_test_ledge.position = Vector2(80, 120)
	coyote_test_ledge.collision_layer = 1
	var coyote_test_shape := CollisionShape2D.new()
	var coyote_test_rectangle := RectangleShape2D.new()
	coyote_test_rectangle.size = Vector2(64, 8)
	coyote_test_shape.shape = coyote_test_rectangle
	coyote_test_ledge.add_child(coyote_test_shape)
	arena.add_child(coyote_test_ledge)
	player_1.global_position = Vector2(108, 104)
	player_1.velocity = Vector2.ZERO
	for _frame in range(3):
		await physics_frame
	if not _expect(player_1.is_on_floor(), "Player 1 did not land on the temporary Coyote Time test ledge."):
		return
	Input.action_press("player_1_right")
	for _frame in range(20):
		await physics_frame
		if not player_1.is_on_floor():
			break
	for _frame in range(2):
		await physics_frame
	var jump_key := InputEventKey.new()
	jump_key.physical_keycode = 70
	jump_key.pressed = true
	Input.parse_input_event(jump_key)
	await physics_frame
	await physics_frame
	if not _expect(player_1.velocity.y < 0.0, "Coyote Time did not allow a jump after leaving the temporary test ledge."):
		return
	jump_key.pressed = false
	Input.parse_input_event(jump_key)
	Input.action_release("player_1_right")

	for _frame in range(50):
		await physics_frame
	player_1.global_position = Vector2(108, 104)
	player_1.velocity = Vector2.ZERO
	player_1.coyote_timer = 0.0
	for _frame in range(3):
		await physics_frame
	Input.action_press("player_1_right")
	for _frame in range(20):
		await physics_frame
		if not player_1.is_on_floor():
			break
	Input.action_release("player_1_right")
	for _frame in range(ceili(MovementConstants.COYOTE_TIME * 60.0) + 1):
		await physics_frame
	Input.action_press("player_1_jump")
	await physics_frame
	Input.action_release("player_1_jump")
	if not _expect(
		player_1.velocity.y >= 0.0,
		"Coyote Time allowed a jump after its configured interval expired."
	):
		return

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
	Input.action_release("player_1_jump")
	for _frame in range(40):
		await physics_frame
	player_1.global_position = Vector2(170, 0)
	player_1.velocity = Vector2(0.0, 100.0)
	Input.action_press("player_1_jump")
	await physics_frame
	Input.action_release("player_1_jump")
	for _frame in range(ceili(MovementConstants.JUMP_BUFFER * 60.0) + 2):
		await physics_frame
	for _frame in range(80):
		await physics_frame
		if player_1.is_on_floor():
			break
	if not _expect(
		player_1.is_on_floor() and player_1.velocity.y >= 0.0,
		"Expired jump buffer triggered unexpectedly after landing."
	):
		return

	Input.action_release("player_1_right")
	Input.action_release("player_1_jump")
	player_1.global_position = Vector2(160, 152)
	player_1.velocity = Vector2.ZERO
	for _frame in range(8):
		await physics_frame
	if not _expect(player_1.is_on_floor(), "Player 1 did not settle on the floor before jump measurements."):
		return
	var full_jump_start := player_1.global_position.y
	var full_jump_peak := full_jump_start
	Input.action_press("player_1_jump")
	for _frame in range(13):
		await physics_frame
		full_jump_peak = minf(full_jump_peak, player_1.global_position.y)
	Input.action_release("player_1_jump")
	for _frame in range(30):
		await physics_frame
		full_jump_peak = minf(full_jump_peak, player_1.global_position.y)
	var full_jump_height := full_jump_start - full_jump_peak
	if not _expect(
		full_jump_height >= 54.0 and full_jump_height <= 59.0,
		"Full jump height was outside the expected 56 px range: %s." % full_jump_height
	):
		return

	player_1.global_position = Vector2(160, 152)
	player_1.velocity = Vector2.ZERO
	for _frame in range(8):
		await physics_frame
	var short_jump_start := player_1.global_position.y
	var short_jump_peak := short_jump_start
	Input.action_press("player_1_jump")
	await physics_frame
	Input.action_release("player_1_jump")
	for _frame in range(35):
		await physics_frame
		short_jump_peak = minf(short_jump_peak, player_1.global_position.y)
	if not _expect(
		short_jump_start - short_jump_peak < full_jump_height - 10.0,
		"Releasing jump early did not produce a distinctly shorter jump."
	):
		return

	player_1.global_position = Vector2(200, 60)
	player_1.velocity = Vector2.ZERO
	Input.action_press("player_1_down")
	var fast_fall_speed := 0.0
	for _frame in range(28):
		await physics_frame
		fast_fall_speed = maxf(fast_fall_speed, player_1.velocity.y)
	Input.action_release("player_1_down")
	if not _expect(
		fast_fall_speed > MovementConstants.MAX_FALL
		and fast_fall_speed <= MovementConstants.FAST_MAX_FALL,
		"Fast fall did not accelerate toward its configured limit: %s." % fast_fall_speed
	):
		return

	player_1.global_position = Vector2(120, 152)
	player_1.velocity = Vector2.ZERO
	for _frame in range(2):
		await physics_frame
	Input.action_press("player_1_right")
	for _frame in range(10):
		await physics_frame
	Input.action_release("player_1_right")
	for _frame in range(15):
		await physics_frame
	if not _expect(
		is_zero_approx(player_1.velocity.x),
		"Player did not stop within 0.25 seconds after releasing horizontal input."
	):
		return

	print('Jump, coyote time, buffering, and air movement verified.')
	quit()
