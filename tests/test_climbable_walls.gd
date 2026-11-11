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
	var main_scene := (load("res://src/scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main_scene)
	await process_frame
	var menu: Node = main_scene.get_node("PlayerCountMenu")
	menu._select_player_count(2)
	menu._select_level("classic")
	var player: PlayerController = main_scene.get_node("Arena/Player1")
	var balloon: BalloonController = main_scene.get_node("Arena/Balloon")
	var map: Node = main_scene.get_node("Arena/MapRoot/ClassicArenaGeometry")
	balloon.reset_round(Vector2(160, 32))
	balloon.gravity_scale = 0.0
	player.global_position = Vector2(14, 100)
	player.velocity = Vector2.ZERO
	if not _expect(is_zero_approx(player.call("_climbable_wall_direction_within", 2.0)), "Ordinary arena boundary was treated as climbable."):
		return
	Input.action_press("player_1_grab")
	Input.action_press("player_1_up")
	await physics_frame
	if not _expect(player.movement_state != PlayerController.MovementState.CLIMB, "Player climbed an ordinary arena boundary."):
		return
	Input.action_release("player_1_grab")
	Input.action_release("player_1_up")

	player.global_position = Vector2(69, 100)
	player.velocity = Vector2.ZERO
	await physics_frame
	if not _expect(not map.get_node("ClimbableWallTiles").get_used_cells().is_empty(), "Classic map has no climbable TileSet wall."):
		return
	var wall_probe := KinematicCollision2D.new()
	player.test_move(player.global_transform, Vector2(-2, 0), wall_probe)
	if not _expect(not is_zero_approx(player.call("_climbable_wall_direction_within", 2.0)), "TileSet climbable wall was not detected by the player probe."):
		return
	Input.action_press("player_1_grab")
	Input.action_press("player_1_up")
	for _frame in range(3):
		await physics_frame
	if not _expect(player.movement_state == PlayerController.MovementState.CLIMB and player.velocity.y < 0.0, "Player could not climb upward while holding grab and up."):
		return
	var stamina_before_release: float = player.climb_stamina
	Input.action_release("player_1_up")
	await physics_frame
	if not _expect(player.movement_state == PlayerController.MovementState.CLIMB and player.climb_stamina < stamina_before_release, "Holding a wall did not consume climbing stamina."):
		return
	Input.action_release("player_1_grab")
	await physics_frame
	if not _expect(player.movement_state != PlayerController.MovementState.CLIMB, "Player remained attached after releasing grab."):
		return

	player.global_position = Vector2(70, 100)
	player.velocity = Vector2.ZERO
	Input.action_press("player_1_grab")
	Input.action_press("player_1_up")
	await physics_frame
	player.climb_stamina = 0.01
	await physics_frame
	await physics_frame
	if not _expect(player.movement_state != PlayerController.MovementState.CLIMB, "Player remained climbing after exhausting stamina."):
		return

	player.global_position = Vector2(70, 100)
	player.velocity = Vector2.ZERO
	player.climb_stamina = 50.0
	Input.action_release("player_1_grab")
	Input.action_release("player_1_up")
	Input.action_release("player_1_jump")
	await physics_frame
	Input.action_press("player_1_grab")
	Input.action_press("player_1_up")
	await physics_frame
	Input.action_release("player_1_up")
	await physics_frame
	Input.action_press("player_1_jump")
	player.jump_buffer_timer = 0.08
	await physics_frame
	if not _expect(player.movement_state != PlayerController.MovementState.CLIMB and player.velocity.y < 0.0, "Jump did not detach the player from a climbable wall: state=%s velocity=%s wall=%s." % [player.movement_state, player.velocity, player.call("_wall_direction_within", 3.0)]):
		return
	Input.action_release("player_1_grab")
	Input.action_release("player_1_jump")
	Input.action_release("player_1_up")
	main_scene.queue_free()
	await process_frame
	print("Climbable-wall filtering, upward climbing, stamina, release, and wall jump verified.")
	quit()
