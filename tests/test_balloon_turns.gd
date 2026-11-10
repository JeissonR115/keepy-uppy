extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _prepare_turn(manager: Node, balloon: RigidBody2D, server: CharacterBody2D) -> void:
	manager.match_state = manager.MatchState.ACTIVE
	manager.round_faulting_player = null
	manager.set_next_server(server)
	manager.pending_normal_hits.clear()
	manager.pending_dash_rescues.clear()
	manager.pending_expected_player = null
	balloon.reset_round(Vector2(40, 80))
	balloon.player_contact_area.monitoring = false


func _run_test() -> void:
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	var arena: Node = main_scene.get_node("Arena")
	var player_1: CharacterBody2D = arena.get_node("Player1")
	var player_2: CharacterBody2D = arena.get_node("Player2")
	var manager: Node = arena.get_node("MatchManager")
	var balloon: RigidBody2D = arena.get_node("Balloon")
	manager.round_intermission = 5.0

	_prepare_turn(manager, balloon, player_1)
	balloon.player_hit.emit(player_1)
	manager.resolve_pending_contacts()
	if not _expect(
		manager.last_valid_toucher == player_1
		and manager.expected_balloon_player == player_2,
		"The server's first contact did not pass the turn to the opponent."
	):
		return
	balloon.dash_rescued.emit(player_2, Vector2.UP)
	manager.resolve_pending_contacts()
	if not _expect(
		manager.last_valid_toucher == player_2
		and manager.expected_balloon_player == player_1,
		"A valid dash rescue did not alternate the expected player."
	):
		return
	balloon.player_hit.emit(player_1)
	manager.resolve_pending_contacts()
	if not _expect(
		manager.last_valid_toucher == player_1
		and manager.expected_balloon_player == player_2,
		"A rally contact did not alternate back to the opponent."
	):
		return

	_prepare_turn(manager, balloon, player_1)
	balloon.player_hit.emit(player_2)
	balloon.player_hit.emit(player_1)
	manager.resolve_pending_contacts()
	if not _expect(
		manager.round_faulting_player == player_2
		and manager.match_state == manager.MatchState.ROUND_OVER,
		"Out-of-turn contact did not fault deterministically when the wrong callback arrived first."
	):
		return
	await process_frame
	if not _expect(manager.player_1_score == 1, "Out-of-turn fault did not award one point to the expected player."):
		return

	_prepare_turn(manager, balloon, player_1)
	balloon.player_hit.emit(player_1)
	balloon.player_hit.emit(player_2)
	manager.resolve_pending_contacts()
	if not _expect(
		manager.round_faulting_player == player_2,
		"Out-of-turn fault changed when the callback order was reversed."
	):
		return
	await process_frame
	if not _expect(
		manager.player_1_score == 2 and manager.player_2_score == 0,
		"A duplicate same-tick contact awarded more than one fault point."
	):
		return

	print("Serve and rally alternation, dash turns, deterministic callback order, and single fault points verified.")
	quit()
