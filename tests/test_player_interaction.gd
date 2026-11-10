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

	var arena: Node = main_scene.get_node("Arena")
	var player_1: CharacterBody2D = arena.get_node("Player1")
	var player_2: CharacterBody2D = arena.get_node("Player2")
	var match_manager: Node = arena.get_node("MatchManager")
	var balloon: RigidBody2D = arena.get_node("Balloon")

	if not _expect(
		(match_manager.next_server == player_1 or match_manager.next_server == player_2)
		and match_manager.priority_player == match_manager.next_server,
		"Opening coin toss did not select a valid server and priority player."
	):
		return

	balloon.player_hit.emit(player_1)
	match_manager.resolve_pending_contacts()
	if not _expect(match_manager.priority_player == player_1, "Normal balloon-hit signal did not update priority."):
		return
	balloon.dash_rescued.emit(player_2, Vector2.RIGHT)
	match_manager.resolve_pending_contacts()
	if not _expect(match_manager.priority_player == player_2, "Dash-rescue signal did not update priority."):
		return

	match_manager.set_next_server(player_1)
	if not _expect(
		player_1.get_node("PriorityIndicator").visible
		and not player_2.get_node("PriorityIndicator").visible,
		"Priority indicator did not identify the selected player."
	):
		return
	if not _expect(match_manager.priority_player == player_1, "Opening server did not receive priority."):
		return
	match_manager.register_normal_hit(player_1)
	match_manager.register_normal_hit(player_2)
	match_manager.resolve_pending_contacts()
	if not _expect(match_manager.priority_player == player_2, "Same-kind tie did not go to the non-priority player."):
		return
	if not _expect(
		player_2.get_node("PriorityIndicator").visible
		and not player_1.get_node("PriorityIndicator").visible,
		"Priority indicator did not move to the tie-break winner."
	):
		return

	match_manager.set_next_server(player_1)
	match_manager.register_normal_hit(player_1)
	match_manager.register_dash_rescue(player_2, Vector2.RIGHT)
	match_manager.resolve_pending_contacts()
	if not _expect(match_manager.priority_player == player_2, "Dash rescue did not take precedence over a normal hit."):
		return

	match_manager.set_next_server(player_1)
	player_2.velocity.x = 0.0
	player_1.player_bumped.emit(player_1, player_2, false)
	var priority_normal_push := player_2.velocity.x
	player_2.velocity.x = 0.0
	match_manager.set_next_server(player_2)
	player_1.player_bumped.emit(player_1, player_2, false)
	var non_priority_normal_push := player_2.velocity.x
	if not _expect(
		priority_normal_push > non_priority_normal_push,
		"Priority did not strengthen normal player displacement."
	):
		return

	player_2.velocity.x = 0.0
	match_manager.set_next_server(player_1)
	player_1.player_bumped.emit(player_1, player_2, true)
	var priority_dash_push := player_2.velocity.x
	player_2.velocity.x = 0.0
	match_manager.set_next_server(player_2)
	player_1.player_bumped.emit(player_1, player_2, true)
	var non_priority_dash_push := player_2.velocity.x
	if not _expect(
		priority_dash_push > non_priority_dash_push,
		"Priority did not strengthen dash displacement."
	):
		return

	print("Priority policy, contact tie-breaks, and push strengths verified.")
	quit()
