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
	var collision_count := [0]
	player_1.player_bumped.connect(func(_player: CharacterBody2D, _opponent: CharacterBody2D, _dashing: bool) -> void: collision_count[0] += 1)
	var player_1_start := player_1.global_position
	Input.action_press("player_1_right")
	Input.action_press("player_2_left")
	for _frame in range(60):
		await physics_frame
	if not _expect(player_1.is_on_floor() and player_2.is_on_floor(), "Players did not collide with the arena ground."):
		return
	if not _expect(collision_count[0] > 0, "Players did not register their physical collisions."):
		return
	print('Player floor contact and collision reporting verified.')
	quit()
