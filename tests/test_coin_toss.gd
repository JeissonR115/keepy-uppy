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
	var balloon: BalloonController = main_scene.get_node("Arena/Balloon")
	var presentation: CanvasLayer = main_scene.get_node("MainMatchPresentation")
	manager.coin_toss_override = outcome
	manager.target_score = 1
	manager.round_intermission = 0.02
	manager.coin_toss_completed.connect(_on_coin_toss_completed)
	toss_count = 0
	emitted_first_server = null
	root.add_child(main_scene)
	await process_frame
	manager.opening_presentation_gate_enabled = true
	var two_players_button: Button = main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	)
	two_players_button.pressed.emit()
	main_scene.get_node("PlayerCountMenu")._select_level("classic")
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
	if not _expect(
		manager.opening_presentation_pending
		and not manager.accepting_gameplay_input
		and not balloon.player_contacts_armed
		and presentation.toss_panel.visible
		and presentation.expected_player == expected_server
		and presentation.player_1_label.text == "Jugador 1"
		and presentation.player_2_label.text == "Jugador 2"
		and presentation.player_1_label.get_theme_color("font_color")
		== PlayerActionCatalog.player_color(PlayerActionCatalog.PLAYER_ONE_PREFIX)
		and presentation.player_2_label.get_theme_color("font_color")
		== PlayerActionCatalog.player_color(PlayerActionCatalog.PLAYER_TWO_PREFIX),
		"Visible toss presentation did not gate play or identify the actual starter."
	):
		return false
	var observed_frames: Dictionary = {}
	var presentation_sample_started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - presentation_sample_started < 1800:
		await process_frame
		for frame_index in range(presentation.COIN_FRAMES.size()):
			if presentation.coin_image.texture == presentation.COIN_FRAMES[frame_index]:
				observed_frames[frame_index] = true
	var starter_emphasized: bool = (
		presentation.player_1_label.modulate.a > presentation.player_2_label.modulate.a
		if outcome == 0
		else presentation.player_2_label.modulate.a > presentation.player_1_label.modulate.a
	)
	if not _expect(
		not manager.opening_presentation_pending
		and manager.accepting_gameplay_input
		and balloon.player_contacts_armed
		and manager.match_state == manager.MatchState.ACTIVE
		and observed_frames.size() == presentation.COIN_FRAMES.size()
		and starter_emphasized,
		"Gameplay did not resume after the visible toss presentation."
	):
		return false

	if not _expect(
		presentation.turn_arrow == null,
		"Headless main-scene execution created a visible turn arrow."
	):
		return false
	var test_arrow := Polygon2D.new()
	main_scene.get_node("Arena").add_child(test_arrow)
	presentation.turn_arrow = test_arrow
	presentation.call("_process", 0.0)
	if not _expect(not test_arrow.visible, "Turn arrow was visible before a valid contact."):
		return false
	manager.round_has_valid_contact = true
	presentation.call("_on_balloon_turn_changed", expected_server)
	presentation.call("_process", 0.0)
	var expected_server_prefix := (
		PlayerActionCatalog.PLAYER_ONE_PREFIX
		if expected_server == manager.player_1
		else PlayerActionCatalog.PLAYER_TWO_PREFIX
	)
	if not _expect(
		test_arrow.visible
		and test_arrow.color == PlayerActionCatalog.player_color(expected_server_prefix)
		and test_arrow.global_position.distance_to(
			expected_server.global_position + Vector2(0.0, -26.0)
		) <= 1.5,
		"Turn arrow did not follow and identify the expected player during a rally."
	):
		return false
	var following_player: CharacterBody2D = (
		manager.player_2 if expected_server == manager.player_1 else manager.player_1
	)
	presentation.call("_on_balloon_turn_changed", following_player)
	presentation.call("_process", 0.0)
	if not _expect(
		test_arrow.global_position.distance_to(
			following_player.global_position + Vector2(0.0, -26.0)
		) <= 1.5,
		"Turn arrow did not move after the authoritative turn changed."
	):
		return false
	manager.round_has_valid_contact = false
	presentation.call("_process", 0.0)
	if not _expect(not test_arrow.visible, "Turn arrow remained visible outside an active rally."):
		return false
	test_arrow.queue_free()
	presentation.turn_arrow = null

	manager.last_valid_toucher = expected_server
	manager.round_has_valid_contact = true
	balloon.ground_touched.emit()
	for _frame in range(120):
		await process_frame
		if (
			manager.match_state == manager.MatchState.ACTIVE
			and manager.round_number == 2
		):
			break
	if not _expect(
		manager.match_state == manager.MatchState.ACTIVE
		and manager.round_number == 2
		and manager.round_server == expected_server
		and manager.coin_toss_result == expected_result
		and toss_count == 1,
		"A new set or point performed another toss or changed the initial toss record: state=%s round=%s server=%s toss=%s count=%s." % [
			manager.match_state, manager.round_number, manager.round_server,
			manager.coin_toss_result, toss_count
		]
	):
		return false
	main_scene.queue_free()
	await process_frame
	return true


func _run_test() -> void:
	var simulation_scene: Node = load(
		"res://src/scenes/simulation/cpu_simulation.tscn"
	).instantiate()
	if not _expect(
		not simulation_scene.has_node("MainMatchPresentation")
		and not simulation_scene.get_node("Arena/MatchManager").opening_presentation_gate_enabled,
		"CPU simulation included or enabled the visible match presenter."
	):
		return
	simulation_scene.free()
	if not await _verify_toss(0, "HEADS"):
		return
	if not await _verify_toss(1, "TAILS"):
		return
	print("Both deterministic coin toss outcomes and single-toss match lifetime verified.")
	quit()
