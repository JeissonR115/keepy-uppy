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
	var arena: Node = main_scene.get_node("Arena")
	var manager: Node = arena.get_node("MatchManager")
	var balloon: RigidBody2D = arena.get_node("Balloon")
	manager.coin_toss_override = 1
	manager.round_intermission = 0.05
	balloon.get_node("PlayerContactArea").monitoring = false
	root.add_child(main_scene)
	await process_frame
	var two_players_button: Button = main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	)
	two_players_button.pressed.emit()
	await process_frame

	var player_1: CharacterBody2D = arena.get_node("Player1")
	var player_2: CharacterBody2D = arena.get_node("Player2")
	if not _expect(
		manager.round_server == player_2
		and is_equal_approx(balloon.global_position.x, manager.player_2_spawn_position.x)
		and is_equal_approx(
			manager.player_2_spawn_position.y - balloon.global_position.y,
			manager.balloon_spawn_offset
		),
		"The opening balloon did not spawn above the coin-toss winner: server=%s P2=%s position=%s expected_offset=%s result=%s." % [
			manager.round_server, player_2.global_position, balloon.global_position,
			manager.balloon_spawn_offset, manager.coin_toss_result
		]
	):
		return

	manager._resolve_fault(player_2)
	await create_timer(0.08).timeout
	if not _expect(
		manager.round_server == player_1
		and manager.next_server == player_1
		and is_equal_approx(balloon.global_position.x, manager.player_1_spawn_position.x)
		and is_equal_approx(
			manager.player_1_spawn_position.y - balloon.global_position.y,
			manager.balloon_spawn_offset
		),
		"The next point did not spawn above its winner-server."
	):
		return

	print("Coin-toss and point-winner server spawn placement verified.")
	quit()
