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
		player_1.velocity.y > 90.0 and player_1.velocity.y < 120.0,
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
	print('Wall slide/jump, climb stamina, corner correction, and stamina endurance verified.')
	quit()
