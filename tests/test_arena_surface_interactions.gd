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
	var main_scene := (load("res://src/scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main_scene)
	await process_frame
	paused = false
	var two_players_button: Button = main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	)
	two_players_button.pressed.emit()
	main_scene.get_node("PlayerCountMenu")._select_level("classic")
	await physics_frame
	var arena: Node = main_scene.get_node("Arena")
	var map: Node2D = arena.get_node("MapRoot/ClassicArenaGeometry")
	var balloon: BalloonController = arena.get_node("Balloon")
	var player: PlayerController = arena.get_node("Player1")
	var match_manager: MatchManager = arena.get_node("MatchManager")
	var entered_bodies: Array[String] = []
	balloon.body_entered.connect(func(body: Node) -> void: entered_bodies.append("%s:%s" % [body.name, body.get_groups()]))
	match_manager.round_intermission = 0.05
	match_manager.restart_match()

	balloon.reset_round(Vector2(88, 90))
	balloon.gravity_scale = 0.0
	balloon.linear_velocity = Vector2(0, 100)
	for _frame in range(24):
		await physics_frame
	if not _expect(balloon.global_position.y > 122.0 and not balloon.ground_contact_reported, "Balloon did not pass through the player-only one-way platform: y=%s reported=%s mask=%s." % [balloon.global_position.y, balloon.ground_contact_reported, balloon.collision_mask]):
		return

	balloon.reset_round(Vector2(168, 40))
	balloon.gravity_scale = 0.0
	balloon.linear_velocity = Vector2(0, 100)
	for _frame in range(40):
		await physics_frame
	if not _expect(balloon.linear_velocity.y < -100.0 and not balloon.ground_contact_reported, "Trampoline did not bounce the balloon upward without scoring."):
		return

	balloon.reset_round(Vector2(48, 88))
	balloon.gravity_scale = 0.0
	balloon.linear_velocity = Vector2(-100, 0)
	for _frame in range(18):
		await physics_frame
	if not _expect(not balloon.ground_contact_reported, "An ordinary solid climbable wall incorrectly scored the balloon."):
		return

	balloon.reset_round(Vector2(40, 40))
	balloon.gravity_scale = 0.0
	player.global_position = Vector2(168, 56)
	player.velocity = Vector2(0, 100)
	for _frame in range(12):
		await physics_frame
	if not _expect(player.velocity.y < 0.0, "Player did not receive an upward trampoline launch."):
		return

	balloon.reset_round(Vector2(140, 130))
	balloon.gravity_scale = 0.0
	balloon.linear_velocity = Vector2(0, 100)
	match_manager.round_intermission = 5.0
	var scoring_contacts := [0]
	balloon.ground_touched.connect(func() -> void: scoring_contacts[0] += 1)
	for _frame in range(30):
		await physics_frame
	if not _expect(scoring_contacts[0] == 1, "Scoring floor did not report exactly one balloon contact: count=%s pos=%s reported=%s score=%s bodies=%s." % [scoring_contacts[0], balloon.global_position, balloon.ground_contact_reported, match_manager.player_1_score + match_manager.player_2_score, entered_bodies]):
		return
	balloon._on_body_entered(map.get_node("ScoringFloorTiles"))
	balloon._on_body_entered(map.get_node("ScoringFloorTiles"))
	if not _expect(scoring_contacts[0] == 1, "Repeated scoring-floor contacts produced more than one event in a round."):
		return
	match_manager.round_intermission = 0.05
	await create_timer(0.08).timeout
	if not _expect(match_manager.player_1_score + match_manager.player_2_score == 1, "Scoring floor did not award exactly one point."):
		return
	main_scene.queue_free()
	await process_frame
	print("Balloon platform pass-through, trampoline rebounds, player launch, and scoring-floor response verified.")
	quit()
