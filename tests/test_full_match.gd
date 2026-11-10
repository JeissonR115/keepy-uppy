extends SceneTree

var manager: Node
var balloon: RigidBody2D
var coin_toss_count: int = 0


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _on_coin_toss_completed(_result: String, _server: CharacterBody2D) -> void:
	coin_toss_count += 1


func _award_point_to(winner: CharacterBody2D) -> void:
	manager.last_valid_toucher = manager.player_2 if winner == manager.player_1 else manager.player_1
	balloon.ground_contact_reported = false
	balloon.ground_touched.emit()
	for _frame in range(10):
		await process_frame
		if manager.match_state != manager.MatchState.ROUND_OVER:
			return


func _run_test() -> void:
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	manager = main_scene.get_node("Arena/MatchManager")
	manager.coin_toss_override = 1
	manager.round_intermission = 0.001
	manager.coin_toss_completed.connect(_on_coin_toss_completed)
	root.add_child(main_scene)
	await process_frame
	balloon = main_scene.get_node("Arena/Balloon")
	var player_1: CharacterBody2D = manager.player_1
	var player_2: CharacterBody2D = manager.player_2
	var scoreboard: CanvasLayer = main_scene.get_node("Arena/Scoreboard")
	if not _expect(
		manager.target_score == 5 and manager.sets_to_win == 3
		and manager.coin_toss_result == "TAILS"
		and manager.round_server == player_2 and coin_toss_count == 1,
		"Full match did not start with the expected match rules and toss result."
	):
		return

	var set_winners: Array[CharacterBody2D] = [player_1, player_2, player_1, player_2, player_1]
	for set_index in range(set_winners.size()):
		var set_winner := set_winners[set_index]
		var other_player := player_2 if set_winner == player_1 else player_1
		for _point in range(4):
			await _award_point_to(set_winner)
			await _award_point_to(other_player)
		if not _expect(
			manager.player_1_score == 4 and manager.player_2_score == 4,
			"A set did not reach the expected 4-4 deciding point."
		):
			return
		await _award_point_to(set_winner)
		var p1_sets_expected := 0
		var p2_sets_expected := 0
		for completed_set in range(set_index + 1):
			if set_winners[completed_set] == player_1:
				p1_sets_expected += 1
			else:
				p2_sets_expected += 1
		if not _expect(
			manager.player_1_sets == p1_sets_expected
			and manager.player_2_sets == p2_sets_expected
			and manager.player_1_score == 0 and manager.player_2_score == 0
			and manager.next_server == set_winner
			and coin_toss_count == 1,
			"Set result, score reset, next serve, or one-toss-per-match rule failed."
		):
			return
		if set_index < set_winners.size() - 1 and not _expect(
			manager.match_state == manager.MatchState.ACTIVE
			and manager.round_server == set_winner,
			"The next set did not begin with the previous set's final point winner serving."
		):
			return

	if not _expect(
		manager.match_state == manager.MatchState.COMPLETE
		and manager.match_winner == player_1
		and manager.player_1_sets == 3 and manager.player_2_sets == 2
		and scoreboard.get_node("HUD/StatusLabel").text == "P1 WINS"
			and manager.round_number == 45,
		"The full first-to-three-sets match did not terminate cleanly after 3-2 sets."
	):
		return
	print("Full five-set match acceptance passed: 3-2 sets, five points per set, next server transitions, and one coin toss.")
	quit()
