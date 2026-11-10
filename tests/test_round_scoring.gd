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
	var match_manager: Node = arena.get_node("MatchManager")
	match_manager.coin_toss_override = 0
	match_manager.round_intermission = 0.15
	root.add_child(main_scene)
	await process_frame
	var two_players_button: Button = main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	)
	two_players_button.pressed.emit()
	await process_frame

	var player_1: CharacterBody2D = arena.get_node("Player1")
	var player_2: CharacterBody2D = arena.get_node("Player2")
	var balloon: RigidBody2D = arena.get_node("Balloon")
	var scoreboard: CanvasLayer = arena.get_node("Scoreboard")
	if not _expect(
		match_manager.target_score == 5 and match_manager.sets_to_win == 3
		and match_manager.round_server == player_1
		and match_manager.last_valid_toucher == player_1,
		"Match did not start with the configured set rules and server contact."
	):
		return

	match_manager.last_valid_toucher = player_1
	match_manager.round_has_valid_contact = true
	balloon.ground_touched.emit()
	await process_frame
	if not _expect(
		match_manager.player_1_score == 1
		and scoreboard.get_node("HUD/ScoreRow/Player1Score").text == "1",
		"Ground contact did not award exactly one point to the last valid toucher: state=%s scores=%s-%s valid=%s toucher=%s." % [
			match_manager.match_state, match_manager.player_1_score, match_manager.player_2_score,
			match_manager.round_has_valid_contact, match_manager.last_valid_toucher
		]
	):
		return
	balloon.ground_touched.emit()
	await create_timer(0.01).timeout
	if not _expect(
		match_manager.player_1_score == 1,
		"Duplicate ground events scored another point during the resolving point."
	):
		return
	await create_timer(0.25).timeout
	if not _expect(
		match_manager.round_server == player_1 and match_manager.priority_player == player_1
		and match_manager.last_valid_toucher == player_1,
		"Point winner did not serve and receive opening priority."
	):
		return

	# A valid second contact lets the other player claim the point.
	match_manager.last_valid_toucher = player_2
	match_manager.round_has_valid_contact = true
	balloon.ground_touched.emit()
	await create_timer(0.25).timeout
	if not _expect(
		match_manager.player_1_score == 1 and match_manager.player_2_score == 1,
		"Ground contact did not award the second point to the last valid toucher."
	):
		return

	match_manager.player_1_score = 4
	match_manager.player_2_score = 4
	match_manager.match_state = match_manager.MatchState.ACTIVE
	match_manager.last_valid_toucher = player_2
	match_manager.round_has_valid_contact = true
	balloon.ground_contact_reported = false
	balloon.ground_touched.emit()
	await process_frame
	if not _expect(
		match_manager.player_2_sets == 1
		and match_manager.player_1_sets == 0
		and match_manager.player_1_score == 0 and match_manager.player_2_score == 0,
		"A 4-4 set did not end on the next point and reset only its point scores."
	):
		return
	await create_timer(0.25).timeout
	if not _expect(
		match_manager.match_state == match_manager.MatchState.ACTIVE
		and match_manager.player_2_sets == 1
		and match_manager.round_server == player_2,
		"Set transition did not retain set wins and give the last point winner the next serve."
	):
		return

	match_manager.player_1_sets = 2
	match_manager.player_2_sets = 1
	match_manager.player_1_score = 4
	match_manager.player_2_score = 0
	match_manager._resolve_fault(player_2)
	await process_frame
	if not _expect(
		match_manager.match_state == match_manager.MatchState.COMPLETE
		and match_manager.match_winner == player_1
		and match_manager.player_1_sets == 3,
		"The third set win did not terminate the match with the correct winner."
	):
		return
	await process_frame
	if not _expect(
		scoreboard.get_node("HUD/StatusLabel").text == "P1 WINS"
		and match_manager.next_server == player_1,
		"Match winner was not shown or an extra round replaced the final result."
	):
		return

	print("Last-touch scoring, serve attribution, duplicate grounds, 4-4 set, set reset, next server, and match victory verified.")
	quit()
