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
	var manager: Node = main_scene.get_node("Arena/MatchManager")
	manager.coin_toss_override = 0
	root.add_child(main_scene)
	await process_frame
	await process_frame

	var arena: Node = main_scene.get_node("Arena")
	var player_1: CharacterBody2D = arena.get_node("Player1")
	var player_2: CharacterBody2D = arena.get_node("Player2")
	var scoreboard: CanvasLayer = arena.get_node("Scoreboard")
	var hud: Control = scoreboard.get_node("HUD")
	var competitive_label: Label = hud.get_node("CompetitiveLabel")
	if not _expect(
		hud.get_node("ScoreRow/Player1Score").text == "0"
		and hud.get_node("ScoreRow/Player2Score").text == "0"
		and hud.get_node("SetScoreRow/Player1Sets").text == "0"
		and hud.get_node("SetScoreRow/Player2Sets").text == "0"
		and competitive_label.text.contains("HEADS")
		and competitive_label.text.contains("NEXT P1")
		and competitive_label.text.contains("PRI P1"),
		"Scoreboard did not display points, sets, toss, server, and priority at match start."
	):
		return

	manager.set_next_server(player_2)
	manager._set_priority(player_1)
	if not _expect(
		competitive_label.text.contains("NEXT P2")
		and competitive_label.text.contains("PRI P1"),
		"Scoreboard did not track next server independently from current priority."
	):
		return
	manager.score_changed.emit(4, 4)
	manager.set_score_changed.emit(2, 1)
	if not _expect(
		hud.get_node("ScoreRow/Player1Score").text == "4"
		and hud.get_node("ScoreRow/Player2Score").text == "4"
		and hud.get_node("SetScoreRow/Player1Sets").text == "2"
		and hud.get_node("SetScoreRow/Player2Sets").text == "1",
		"Scoreboard did not update points and sets."
	):
		return
	manager.round_ended.emit(player_2, 4, 4)
	if not _expect(hud.get_node("StatusLabel").text == "P2 SCORES", "Point result was not shown."):
		return
	manager.set_ended.emit(player_2, 2, 1)
	if not _expect(hud.get_node("StatusLabel").text == "P2 TAKES SET 3", "Set result was not shown."):
		return
	manager.match_ended.emit(player_1)
	if not _expect(hud.get_node("StatusLabel").text == "P1 WINS", "Match winner was not shown."):
		return

	var balloon: Node2D = arena.get_node("Balloon")
	var balloon_bounds := Rect2(balloon.global_position - Vector2(9, 9), Vector2(18, 18))
	var backdrop: ColorRect = hud.get_node("Backdrop")
	if not _expect(
		not backdrop.get_global_rect().intersects(balloon_bounds)
		and backdrop.get_global_rect().end.x <= 320.0,
		"Scoreboard backdrop overlaps the balloon or extends beyond the logical viewport."
	):
		return
	for node_path: NodePath in [
		NodePath("ScoreRow"), NodePath("SetScoreRow"), NodePath("CompetitiveLabel"), NodePath("StatusLabel")
	]:
		var rect := (hud.get_node(node_path) as Control).get_global_rect()
		if not _expect(rect.position.x >= 0.0 and rect.end.x <= 320.0, "A scoreboard row exceeds the viewport width."):
			return

	print("Scoreboard points, sets, toss, server, priority, results, winner, and viewport placement verified.")
	quit()
