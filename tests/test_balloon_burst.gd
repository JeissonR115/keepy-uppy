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
	var two_players_button: Button = main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	)
	two_players_button.pressed.emit()
	main_scene.get_node("PlayerCountMenu")._select_level("classic")
	await process_frame

	var arena: Node = main_scene.get_node("Arena")
	var balloon: RigidBody2D = arena.get_node("Balloon")
	var manager: Node = arena.get_node("MatchManager")
	manager.round_intermission = 0.5
	balloon.get_node("PlayerContactArea").monitoring = false
	manager.set_next_server(arena.get_node("Player1"))
	manager.last_valid_toucher = arena.get_node("Player2")
	manager.round_has_valid_contact = true
	balloon.reset_round(Vector2(40, 150))
	for _frame in range(40):
		if balloon.ground_contact_reported:
			break
		await physics_frame
	if not _expect(balloon.ground_contact_reported and balloon.ground_burst.visible, "Scoring-floor contact did not show the balloon burst."):
		return
	await process_frame
	if not _expect(
		manager.match_state == manager.MatchState.ROUND_OVER
		and manager.player_2_score == 1,
		"The burst delayed floor scoring or failed to end the point."
	):
		return
	balloon._on_body_entered(arena.get_node("ScoringGround"))
	await create_timer(0.28).timeout
	if not _expect(
		manager.player_2_score == 1 and not balloon.ground_burst.visible,
		"Repeated floor contact scored twice or the burst did not finish."
	):
		return
	await create_timer(0.28).timeout
	if not _expect(
		manager.match_state == manager.MatchState.ACTIVE
		and not balloon.ground_contact_reported
		and not balloon.ground_burst.visible,
		"The burst or ground-contact guard did not reset for the next point."
	):
		return

	print("Single floor burst, immediate scoring, duplicate suppression, and next-point reset verified.")
	quit()
