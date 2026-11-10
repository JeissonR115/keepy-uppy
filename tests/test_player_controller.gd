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
		is_equal_approx(MovementConstants.MAX_RUN, 90.0)
		and is_equal_approx(MovementConstants.RUN_ACCEL, 1000.0)
		and is_equal_approx(MovementConstants.RUN_REDUCE, 400.0)
		and is_equal_approx(MovementConstants.GRAVITY, 900.0)
		and is_equal_approx(MovementConstants.JUMP_SPEED, -105.0)
		and is_equal_approx(MovementConstants.DASH_SPEED, 240.0)
		and is_equal_approx(MovementConstants.DASH_TIME, 0.15)
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

	Input.action_press("player_1_right")
	Input.action_press("player_2_left")
	for _frame in range(60):
		await physics_frame
	if not _expect(player_1.is_on_floor() and player_2.is_on_floor(), "Players did not collide with the arena ground."):
		return
	if not _expect(player_1.global_position.x < player_2.global_position.x, "Players passed through each other."):
		return

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

	Input.action_release("player_1_right")
	Input.action_release("player_1_jump")
	player_1.global_position = Vector2(160, 152)
	player_1.velocity = Vector2.ZERO
	for _frame in range(2):
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
		full_jump_height >= 25.0 and full_jump_height <= 30.0,
		"Full jump height was outside the expected 28 px range: %s." % full_jump_height
	):
		return

	player_1.global_position = Vector2(160, 152)
	player_1.velocity = Vector2.ZERO
	for _frame in range(2):
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
	for _frame in range(28):
		await physics_frame
	var fast_fall_speed := player_1.velocity.y
	Input.action_release("player_1_down")
	if not _expect(
		fast_fall_speed > MovementConstants.MAX_FALL
		and fast_fall_speed <= MovementConstants.FAST_MAX_FALL,
		"Fast fall did not accelerate toward its 240 px/s limit: %s." % fast_fall_speed
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
	for _frame in range(6):
		await physics_frame
	if not _expect(
		is_zero_approx(player_1.velocity.x),
		"Player did not stop within 0.1 seconds after releasing horizontal input."
	):
		return

	player_1.reset_for_round(Vector2(14, 80))
	for _frame in range(2):
		await physics_frame
	player_1.velocity = Vector2(0.0, MovementConstants.MAX_FALL)
	Input.action_press("player_1_left")
	await physics_frame
	if not _expect(
		player_1.velocity.y >= MovementConstants.WALL_SLIDE_START
		and player_1.velocity.y < MovementConstants.WALL_SLIDE_START + 5.0,
		"Wall slide did not begin at the configured fall speed."
	):
		return
	for _frame in range(30):
		await physics_frame
	if not _expect(
		player_1.velocity.y > 60.0 and player_1.velocity.y < 95.0,
		"Wall-slide fall speed did not increase toward the normal fall limit."
	):
		return
	Input.action_release("player_1_left")
	Input.action_press("player_1_jump")
	for _frame in range(3):
		await physics_frame
		if player_1.velocity.x > 0.0:
			break
	if not _expect(
		is_equal_approx(player_1.velocity.x, MovementConstants.WALL_JUMP_H)
		and is_equal_approx(player_1.velocity.y, MovementConstants.JUMP_SPEED),
		"Wall jump did not launch away from the wall at its configured speed."
	):
		return
	Input.action_release("player_1_jump")

	player_1.reset_for_round(Vector2(14, 80))
	player_1.dash_available = false
	player_1.dash_refill_cooldown_timer = 0.0
	Input.action_press("player_1_grab")
	for _frame in range(3):
		await physics_frame
		if player_1.movement_state == PlayerController.MovementState.CLIMB:
			break
	if not _expect(
		player_1.movement_state == PlayerController.MovementState.CLIMB,
		"Grab did not enter climb within the configured wall distance."
	):
		return
	for _frame in range(6):
		await physics_frame
	if not _expect(
		is_equal_approx(
			player_1.climb_stamina,
			MovementConstants.CLIMB_MAX_STAMINA
			- MovementConstants.CLIMB_STILL_COST * 7.0 / 60.0
		)
		and is_zero_approx(player_1.velocity.y)
		and not player_1.dash_available,
		"Climbing in place did not hold position and spend stamina at the configured rate."
	):
		return
	Input.action_press("player_1_up")
	for _frame in range(6):
		await physics_frame
	if not _expect(
		is_equal_approx(player_1.velocity.y, MovementConstants.CLIMB_UP_SPEED)
		and is_equal_approx(
			player_1.climb_stamina,
			MovementConstants.CLIMB_MAX_STAMINA
			- MovementConstants.CLIMB_STILL_COST * 7.0 / 60.0
			- MovementConstants.CLIMB_UP_COST * 0.1
		),
		"Climbing upward did not use its configured speed and stamina cost."
	):
		return
	Input.action_release("player_1_up")
	Input.action_press("player_1_down")
	var stamina_before_descend: float = player_1.climb_stamina
	await physics_frame
	if not _expect(
		is_equal_approx(player_1.velocity.y, MovementConstants.CLIMB_DOWN_SPEED)
		and is_equal_approx(player_1.climb_stamina, stamina_before_descend),
		"Climbing down did not use its configured speed without an unintended stamina cost."
	):
		return
	Input.action_release("player_1_down")
	player_1.climb_stamina = MovementConstants.CLIMB_TIRED_THRESHOLD - 1.0
	await physics_frame
	if not _expect(
		player_1.visual.modulate.a < 1.0,
		"Climbing below the tired threshold did not show blinking feedback."
	):
		return
	Input.action_press("player_1_down")
	for _frame in range(2):
		await physics_frame
	player_1.climb_stamina = 60.0
	Input.action_press("player_1_jump")
	for _frame in range(3):
		await physics_frame
		if player_1.movement_state != PlayerController.MovementState.CLIMB:
			break
	if not _expect(
		player_1.movement_state == PlayerController.MovementState.NORMAL
		and is_equal_approx(player_1.velocity.x, MovementConstants.WALL_JUMP_H)
		and is_equal_approx(
			player_1.climb_stamina,
			60.0 - MovementConstants.CLIMB_JUMP_COST
		),
		"Jumping from climb did not exit, spend jump stamina, and launch away from the wall."
	):
		return
	Input.action_release("player_1_jump")
	Input.action_release("player_1_grab")
	Input.action_release("player_1_down")
	player_1.global_position = Vector2(160, 152)
	player_1.velocity = Vector2.ZERO
	player_1.climb_stamina = 10.0
	for _frame in range(3):
		await physics_frame
	if not _expect(
		player_1.is_on_floor()
		and is_equal_approx(player_1.climb_stamina, MovementConstants.CLIMB_MAX_STAMINA)
		and player_1.dash_available,
		"Climb stamina and dash charge did not refill on the ground."
	):
		return

	player_1.reset_for_round(Vector2(160, 152))
	for _frame in range(2):
		await physics_frame
	Input.action_press("player_1_right")
	var acceleration_ticks := 0
	for _frame in range(10):
		await physics_frame
		if player_1.velocity.x > 0.0:
			acceleration_ticks += 1
		if player_1.velocity.x >= MovementConstants.MAX_RUN:
			break
	Input.action_release("player_1_right")
	if not _expect(
		acceleration_ticks <= 6
		and is_equal_approx(player_1.velocity.x, MovementConstants.MAX_RUN),
		"Ground acceleration did not reach run speed in under 0.1 seconds."
	):
		return
	for _frame in range(6):
		await physics_frame
	if not _expect(
		is_zero_approx(player_1.velocity.x),
		"Ground movement did not stop in under 0.1 seconds after releasing input."
	):
		return

	var ceiling_obstacle := StaticBody2D.new()
	ceiling_obstacle.collision_layer = 1
	ceiling_obstacle.collision_mask = 0
	ceiling_obstacle.position = Vector2(210, 94)
	var ceiling_shape := CollisionShape2D.new()
	var ceiling_rectangle := RectangleShape2D.new()
	ceiling_rectangle.size = Vector2(100, 8)
	ceiling_shape.shape = ceiling_rectangle
	ceiling_obstacle.add_child(ceiling_shape)
	arena.add_child(ceiling_obstacle)
	player_1.reset_for_round(Vector2(155, 110))
	for _frame in range(2):
		await physics_frame
	var ceiling_start := player_1.global_position
	player_1.velocity = Vector2(0.0, MovementConstants.JUMP_SPEED)
	for _frame in range(5):
		await physics_frame
	if not _expect(
		player_1.global_position.y < ceiling_start.y
		and player_1.global_position.x < ceiling_start.x
		and player_1.global_position.x
		>= ceiling_start.x - MovementConstants.CEILING_CORNER_CORRECTION - 0.1,
		"Ceiling corner correction did not shift at most 4 px and continue upward: start=%s position=%s velocity=%s ceiling=%s." % [
			ceiling_start, player_1.global_position, player_1.velocity, player_1.is_on_ceiling()
		]
	):
		return

	player_1.reset_for_round(Vector2(14, 80))
	for _frame in range(2):
		await physics_frame
	Input.action_press("player_1_grab")
	for _frame in range(3):
		await physics_frame
		if player_1.movement_state == PlayerController.MovementState.CLIMB:
			break
	Input.action_press("player_1_up")
	var upward_climb_ticks := 0
	for _frame in range(160):
		await physics_frame
		upward_climb_ticks += 1
		if player_1.movement_state != PlayerController.MovementState.CLIMB:
			break
	Input.action_release("player_1_up")
	if not _expect(
		player_1.movement_state == PlayerController.MovementState.NORMAL
		and upward_climb_ticks >= 141
		and upward_climb_ticks <= 150,
		"Upward climbing duration did not match the approximately 2.4 second stamina budget."
	):
		return
	Input.action_release("player_1_grab")

	player_1.reset_for_round(Vector2(14, 80))
	for _frame in range(2):
		await physics_frame
	Input.action_press("player_1_grab")
	for _frame in range(3):
		await physics_frame
		if player_1.movement_state == PlayerController.MovementState.CLIMB:
			break
	var stationary_climb_ticks := 0
	for _frame in range(680):
		await physics_frame
		stationary_climb_ticks += 1
		if player_1.movement_state != PlayerController.MovementState.CLIMB:
			break
	Input.action_release("player_1_grab")
	if not _expect(
		player_1.movement_state == PlayerController.MovementState.NORMAL
		and stationary_climb_ticks >= 655
		and stationary_climb_ticks <= 666,
		"Stationary climbing duration did not match the approximately 11 second stamina budget."
	):
		return

	print("Movement, wall slide/jump, climb stamina, tired feedback, collisions, and remapping verified.")
	quit()
