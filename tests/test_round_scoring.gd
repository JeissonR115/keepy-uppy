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
	var balloon: RigidBody2D = arena.get_node("Balloon")
	var match_manager: Node = arena.get_node("MatchManager")
	var scoreboard: CanvasLayer = arena.get_node("Scoreboard")
	match_manager.target_score = 2
	match_manager.round_intermission = 0.05
	match_manager.player_1_spawn_position = Vector2(72, 152)
	match_manager.player_2_spawn_position = Vector2(248, 152)
	match_manager.set_next_server(player_1)

	match_manager.last_valid_toucher = player_1
	balloon.ground_touched.emit()
	await process_frame
	if not _expect(
		scoreboard.get_node("HUD/ScoreRow/Player2Score").text == "1"
		and scoreboard.get_node("HUD/StatusLabel").text == "P2 SCORES",
		"Scoreboard did not display the point while the round result was active."
	):
		return
	balloon.ground_touched.emit()
	await create_timer(0.15).timeout
	if not _expect(match_manager.player_2_score == 1 and match_manager.player_1_score == 0, "Last-toucher fault did not award one point to the opponent."):
		return
	if not _expect(match_manager.round_number == 2, "Duplicate ground events produced an extra round point."):
		return
	if not _expect(match_manager.next_server == player_2, "Point winner was not selected as the next server."):
		return
	if not _expect(match_manager.match_state == match_manager.MatchState.ACTIVE, "Round did not restart after its intermission."):
		return
	if not _expect(
		player_1.global_position.distance_to(match_manager.player_1_spawn_position) < 1.0,
		"Player positions did not reset for the next round."
	):
		return

	match_manager.last_valid_toucher = null
	balloon.ground_touched.emit()
	await create_timer(0.15).timeout
	if not _expect(match_manager.player_1_score == 1, "No-touch round did not award the point opposite its server."):
		return
	if not _expect(match_manager.player_2_score == 1, "Match score was not retained across the round reset."):
		return
	if not _expect(
		scoreboard.get_node("HUD/ScoreRow/Player1Score").text == "1"
		and scoreboard.get_node("HUD/ScoreRow/Player2Score").text == "1",
		"Scoreboard did not retain both players' scores after a round reset."
	):
		return
	if not _expect(match_manager.round_number == 3, "The next round did not start after the no-touch point."):
		return

	match_manager.last_valid_toucher = player_1
	balloon.ground_touched.emit()
	await process_frame
	await process_frame
	if not _expect(match_manager.match_state == match_manager.MatchState.COMPLETE, "Reaching the target did not end the match."):
		return
	if not _expect(match_manager.match_winner == player_2, "The wrong player was declared the match winner."):
		return
	if not _expect(
		scoreboard.get_node("HUD/StatusLabel").text == "P2 WINS",
		"Scoreboard did not display the match winner."
	):
		return
	if not _expect(match_manager.round_number == 3, "A new round started after the match ended."):
		return

	print("Scoring, duplicate ground events, round reset, and match victory verified.")
	quit()
