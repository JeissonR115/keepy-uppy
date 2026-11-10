extends SceneTree

var toss_count: int = 0
var emitted_toss_result: String = ""
var emitted_first_server: CharacterBody2D


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _on_coin_toss_completed(result: String, first_server: CharacterBody2D) -> void:
	toss_count += 1
	emitted_toss_result = result
	emitted_first_server = first_server


func _verify_toss(outcome: int, expected_result: String) -> bool:
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	var manager: Node = main_scene.get_node("Arena/MatchManager")
	manager.coin_toss_override = outcome
	manager.target_score = 1
	manager.round_intermission = 0.02
	manager.coin_toss_completed.connect(_on_coin_toss_completed)
	toss_count = 0
	emitted_first_server = null
	root.add_child(main_scene)
	await process_frame
	var player_1: CharacterBody2D = manager.player_1
	var player_2: CharacterBody2D = manager.player_2
	var expected_server := player_1 if outcome == 0 else player_2
	if not _expect(
		manager.coin_toss_result == expected_result
		and manager.round_server == expected_server
		and emitted_first_server == expected_server
		and toss_count == 1,
		"Coin toss outcome did not select and announce the correct opening server."
	):
		return false

	manager.last_valid_toucher = player_2 if expected_server == player_1 else player_1
	manager.get_node("../Balloon").ground_touched.emit()
	for _frame in range(20):
		await process_frame
		if manager.match_state != manager.MatchState.ROUND_OVER:
			break
	if not _expect(
		manager.match_state == manager.MatchState.ACTIVE
		and manager.round_number == 2
		and manager.round_server == expected_server
		and manager.coin_toss_result == expected_result
		and toss_count == 1,
		"A new set or point performed another toss or changed the initial toss record."
	):
		return false
	main_scene.queue_free()
	await process_frame
	return true


func _run_test() -> void:
	if not await _verify_toss(0, "HEADS"):
		return
	if not await _verify_toss(1, "TAILS"):
		return
	print("Both deterministic coin toss outcomes and single-toss match lifetime verified.")
	quit()
