extends SceneTree

const MOVEMENT := preload("res://src/models/player/player_movement_constants.gd")
const ACTIONS := preload("res://src/models/player/player_action_catalog.gd")


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _run_test() -> void:
	if not _expect(is_equal_approx(MOVEMENT.MAX_RUN, 130.0), "Automatic run speed is not 130 px/s."):
		return
	if not _expect(not InputMap.has_action("player_1_accelerate") and not InputMap.has_action("player_2_accelerate"), "Manual boost actions remain registered."):
		return
	if not _expect(not ACTIONS.action_names().has("player_1_accelerate") and not ACTIONS.action_names().has("player_2_accelerate"), "Manual boost actions remain in remappable controls."):
		return
	var main_scene := (load("res://src/scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main_scene)
	await process_frame
	var menu: Node = main_scene.get_node("PlayerCountMenu")
	menu._select_player_count(2)
	menu._select_level("classic")
	var player: PlayerController = main_scene.get_node("Arena/Player1")
	player.reset_for_round(Vector2(120, 152))
	await physics_frame
	Input.action_press("player_1_right")
	for _frame in range(12):
		await physics_frame
	Input.action_release("player_1_right")
	if not _expect(is_equal_approx(player.velocity.x, MOVEMENT.MAX_RUN), "Holding run did not reach the automatic speed cap."):
		return
	for _frame in range(12):
		await physics_frame
	if not _expect(is_zero_approx(player.velocity.x), "Run speed did not decelerate after movement input was released."):
		return
	main_scene.queue_free()
	await process_frame
	print("Automatic run speed, cap, deceleration, and removal of manual boost bindings verified.")
	quit()
