extends SceneTree

const MovementConstants = preload("res://src/models/player/player_movement_constants.gd")
const DIRECTION_ACTIONS := [
	[],
	["player_1_right"],
	["player_1_up", "player_1_right"],
	["player_1_up"],
	["player_1_up", "player_1_left"],
	["player_1_left"],
	["player_1_down", "player_1_left"],
	["player_1_down"],
	["player_1_down", "player_1_right"],
]
const EXPECTED_DIRECTIONS := [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2(0.70710678, -0.70710678),
	Vector2.UP,
	Vector2(-0.70710678, -0.70710678),
	Vector2.LEFT,
	Vector2(-0.70710678, 0.70710678),
	Vector2.DOWN,
	Vector2(0.70710678, 0.70710678),
]
const DIRECTIONAL_ACTIONS := [
	"player_1_left",
	"player_1_right",
	"player_1_up",
	"player_1_down",
]


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _release_directional_actions() -> void:
	for action: String in DIRECTIONAL_ACTIONS:
		Input.action_release(action)


func _run_test() -> void:
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	var two_players_button: Button = main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	)
	two_players_button.pressed.emit()

	var player: PlayerController = main_scene.get_node("Arena/Player1")
	var player_2: PlayerController = main_scene.get_node("Arena/Player2")
	player.facing_direction = Vector2.LEFT

	for index in range(DIRECTION_ACTIONS.size()):
		player.reset_for_round(Vector2(120, 152))
		player.facing_direction = Vector2.LEFT
		_release_directional_actions()
		for action: String in DIRECTION_ACTIONS[index]:
			Input.action_press(action)
		Input.action_press("player_1_dash")

		for _frame in range(8):
			await physics_frame
			if player.is_dashing:
				break
		if not _expect(player.is_dashing, "Dash did not activate for direction case %d." % index):
			return
		if not _expect(
			player.dash_direction.is_equal_approx(EXPECTED_DIRECTIONS[index]),
			"Unexpected dash direction for case %d: %s" % [index, player.dash_direction]
		):
			return
		if not _expect(
			player.cape.visible
			and player.cape.get_node("Polygon2D").visible
			and player.cape.positions.size() == MovementConstants.CAPE_ROWS * 2,
			"Player cape did not provide the visible dash trail for case %d." % index
		):
			return
		if not _expect(not player.dash_available, "Dash charge was not consumed immediately."):
			return

		Input.action_release("player_1_dash")
		_release_directional_actions()
		for _frame in range(20):
			await physics_frame
			if not player.is_dashing and player.dash_freeze_timer <= 0.0:
				break
		if not _expect(
			player.cape.visible and player.cape.get_node("Polygon2D").visible,
			"Player cape disappeared after dash case %d." % index
		):
			return

	player.reset_for_round(Vector2(120, 80))
	_release_directional_actions()
	var dash_start := Vector2.ZERO
	Input.action_press("player_1_right")
	Input.action_press("player_1_dash")
	for _frame in range(8):
		await physics_frame
		if player.dash_freeze_timer > 0.0:
			dash_start = player.global_position
			break
	if not _expect(player.dash_freeze_timer > 0.0, "Dash did not enter its local freeze interval."):
		return
	var opponent_start := player_2.global_position
	Input.action_press("player_2_right")
	var freeze_position := player.global_position
	for _frame in range(2):
		await physics_frame
	if not _expect(
		player.global_position.is_equal_approx(freeze_position),
		"Player moved during its dash freeze."
	):
		return
	if not _expect(
		player_2.global_position.x > opponent_start.x,
		"Dash freeze paused the other local player."
	):
		return

	var observed_dash := false
	for _frame in range(20):
		await physics_frame
		if player.is_dashing:
			if not observed_dash:
				dash_start = player.global_position
			observed_dash = true
		elif observed_dash:
			break
	var dash_distance := player.global_position.distance_to(dash_start)
	if not _expect(
		dash_distance >= 55.0 and dash_distance <= 75.0,
		"Dynamic dash did not travel substantially farther than its previous 36 px: %s." % dash_distance
	):
		return
	if not _expect(
		player.velocity.x >= 140.0
		and player.velocity.x <= MovementConstants.END_DASH_SPEED
		and absf(player.velocity.y) < 1.0,
		"Horizontal dash did not preserve its configured exit velocity."
	):
		return
	if not _expect(not player.dash_available, "An airborne dash refilled without landing."):
		return

	Input.action_release("player_1_dash")
	Input.action_release("player_1_right")
	Input.action_press("player_1_dash")
	for _frame in range(8):
		await physics_frame
	if not _expect(not player.is_dashing, "A spent air dash charge was reused before landing."):
		return
	Input.action_release("player_1_dash")

	player.global_position = Vector2(120, 152)
	player.velocity = Vector2.ZERO
	for _frame in range(3):
		await physics_frame
	if not _expect(player.dash_available, "Dash did not refill after landing and the refill delay."):
		return

	player.reset_for_round(Vector2(120, 152))
	_release_directional_actions()
	Input.action_press("player_1_right")
	Input.action_press("player_1_down")
	Input.action_press("player_1_dash")
	for _frame in range(12):
		await physics_frame
		if player.dash_ultra_triggered:
			break
	if not _expect(
		player.dash_ultra_triggered
		and player.dash_velocity.x
		>= MovementConstants.DASH_SPEED
		* Vector2(1.0, 1.0).normalized().x
		* MovementConstants.ULTRA_MULT
		and player.dash_velocity.x
		<= MovementConstants.DASH_SPEED
		* (1.0 + MovementConstants.DASH_SPEED_PULSE)
		* Vector2(1.0, 1.0).normalized().x
		* MovementConstants.ULTRA_MULT
		and is_zero_approx(player.dash_velocity.y)
		and player.ducking,
		"Downward diagonal dash did not trigger an ultra and duck."
	):
		return
	var duck_shape := player.get_node("CollisionShape2D").shape as CapsuleShape2D
	if not _expect(
		is_equal_approx(
			duck_shape.height,
			player.normal_collision_height - MovementConstants.DUCK_COLLISION_HEIGHT_REDUCTION
		),
		"Ducking did not reduce the player collision height."
	):
		return
	Input.action_press("player_1_jump")
	for _frame in range(3):
		await physics_frame
		if not player.is_dashing:
			break
	if not _expect(
		not player.is_dashing
		and not player.ducking
		and is_equal_approx(
			player.velocity.x,
			MovementConstants.SUPER_JUMP_H * MovementConstants.DUCK_SUPER_X_MULT
		)
		and is_equal_approx(
			player.velocity.y,
			MovementConstants.JUMP_SPEED * MovementConstants.DUCK_SUPER_Y_MULT
		),
		"Ducking dash did not chain into a hyper jump with retained speed: dashing=%s ducking=%s velocity=%s floor=%s." % [
			player.is_dashing, player.ducking, player.velocity, player.is_on_floor()
		]
	):
		return
	var hyper_speed := MovementConstants.SUPER_JUMP_H * MovementConstants.DUCK_SUPER_X_MULT
	for _frame in range(3):
		await physics_frame
	if not _expect(
		player.velocity.x
		> hyper_speed - MovementConstants.RUN_REDUCE * 3.0 / 60.0 - 0.1,
		"Hyper speed did not decay slowly while steering in the same direction."
	):
		return
	Input.action_release("player_1_right")
	for _frame in range(3):
		await physics_frame
	if not _expect(
		player.velocity.x < 280.0,
		"Hyper speed was not reduced promptly after releasing horizontal input."
	):
		return
	Input.action_release("player_1_jump")
	_release_directional_actions()
	Input.action_release("player_1_dash")

	player.reset_for_round(Vector2(120, 152))
	Input.action_press("player_1_right")
	Input.action_press("player_1_dash")
	for _frame in range(8):
		await physics_frame
		if player.is_dashing:
			break
	Input.action_release("player_1_dash")
	Input.action_press("player_1_jump")
	for _frame in range(3):
		await physics_frame
		if not player.is_dashing:
			break
	if not _expect(
		not player.is_dashing
		and is_equal_approx(player.velocity.x, MovementConstants.SUPER_JUMP_H)
		and is_equal_approx(player.velocity.y, MovementConstants.JUMP_SPEED),
		"Horizontal dash did not chain into a super jump."
	):
		return
	Input.action_release("player_1_jump")
	_release_directional_actions()

	player.reset_for_round(Vector2(14, 80))
	Input.action_press("player_1_up")
	Input.action_press("player_1_dash")
	for _frame in range(8):
		await physics_frame
		if player.is_dashing:
			break
	Input.action_release("player_1_up")
	Input.action_release("player_1_dash")
	Input.action_press("player_1_jump")
	for _frame in range(3):
		await physics_frame
		if not player.is_dashing:
			break
	if not _expect(
		not player.is_dashing
		and is_equal_approx(player.velocity.x, MovementConstants.SUPER_WALL_JUMP_H)
		and is_equal_approx(player.velocity.y, MovementConstants.SUPER_WALL_JUMP_SPEED),
		"Upward dash did not bounce away from a nearby wall."
	):
		return
	Input.action_release("player_1_jump")
	_release_directional_actions()

	var corner_obstacle := StaticBody2D.new()
	corner_obstacle.collision_layer = 1
	corner_obstacle.collision_mask = 0
	corner_obstacle.position = Vector2(210, 115)
	var corner_shape := CollisionShape2D.new()
	var corner_rectangle := RectangleShape2D.new()
	corner_rectangle.size = Vector2(100, 50)
	corner_shape.shape = corner_rectangle
	corner_obstacle.add_child(corner_shape)
	main_scene.get_node("Arena").add_child(corner_obstacle)
	player.reset_for_round(Vector2(130, 78.0))
	for _frame in range(2):
		await physics_frame
	Input.action_press("player_1_right")
	Input.action_press("player_1_dash")
	var corner_dash_started := false
	var corner_contact_y := 0.0
	var corner_contact_observed := false
	for _frame in range(18):
		await physics_frame
		if player.is_dashing or player.dash_freeze_timer > 0.0:
			corner_dash_started = true
			if not corner_contact_observed and player.global_position.x >= 150.0:
				corner_contact_y = player.global_position.y
				corner_contact_observed = true
		elif corner_dash_started:
			break
	if not _expect(
		corner_dash_started
		and corner_contact_observed
		and player.global_position.x > 160.0
		and player.global_position.y < corner_contact_y
		and player.global_position.y
		>= corner_contact_y - MovementConstants.DASH_CORNER_CORRECTION - 0.1,
		"Dash did not travel around a corner using at most 4 px of correction: started=%s contact=%s contact_y=%s end=%s velocity=%s dashing=%s." % [
			corner_dash_started, corner_contact_observed, corner_contact_y,
			player.global_position, player.velocity, player.is_dashing
		]
	):
		return
	Input.action_release("player_1_right")
	Input.action_release("player_1_dash")

	Input.action_release("player_2_right")
	print("Dash techniques, retained hyper speed, wall bounce and 4 px corner correction verified.")
	quit()
