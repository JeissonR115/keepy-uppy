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
	await process_frame

	var arena: Node = main_scene.get_node("Arena")
	var balloon: RigidBody2D = arena.get_node("Balloon")
	var player: CharacterBody2D = arena.get_node("Player1")
	var manager: Node = arena.get_node("MatchManager")
	manager.round_intermission = 2.0
	balloon.player_contact_area.monitoring = false
	player.global_position = Vector2(40, 106)
	player.velocity = Vector2.ZERO
	balloon.reset_round(Vector2(40, 90))
	manager.set_next_server(player)
	balloon._on_player_contact_area_body_entered(player)
	manager.resolve_pending_contacts()
	await physics_frame
	var base_velocity: Vector2 = balloon.linear_velocity
	if not _expect(base_velocity.y < 0.0 and is_zero_approx(base_velocity.x), "A stationary upward contact did not launch straight up."):
		return

	balloon.reset_round(Vector2(40, 90))
	manager.set_next_server(player)
	player.velocity = Vector2(140, 0)
	balloon._on_player_contact_area_body_entered(player)
	manager.resolve_pending_contacts()
	await physics_frame
	var moving_velocity: Vector2 = balloon.linear_velocity
	if not _expect(
		moving_velocity.x > 0.0 and moving_velocity.y < 0.0
		and moving_velocity.length() > base_velocity.length(),
		"Player movement did not affect balloon launch direction and speed."
	):
		return

	player.global_position = Vector2(120, 106)
	balloon.reset_round(Vector2(40, 90))
	manager.set_next_server(player)
	player.velocity = Vector2.ZERO
	balloon.apply_dash_rescue(player, Vector2.RIGHT)
	manager.resolve_pending_contacts()
	await physics_frame
	var base_dash_speed := balloon.linear_velocity.length()
	balloon.reset_round(Vector2(40, 90))
	manager.set_next_server(player)
	player.velocity = Vector2(200, 0)
	balloon.apply_dash_rescue(player, Vector2.RIGHT)
	manager.resolve_pending_contacts()
	await physics_frame
	if not _expect(
		balloon.linear_velocity.length() > base_dash_speed
		and balloon.linear_velocity.length() <= balloon.max_dash_rescue_impulse / balloon.mass + 0.1,
		"Dash rescue did not scale with movement within its configured impulse cap: base=%s moving=%s max=%s." % [
			base_dash_speed,
			balloon.linear_velocity.length(),
			balloon.max_dash_rescue_impulse / balloon.mass,
		]
	):
		return

	balloon.reset_round(Vector2(40, 90))
	manager.set_next_server(player)
	player.global_position = Vector2(40, 74)
	player.velocity = Vector2.ZERO
	balloon._on_player_contact_area_body_entered(player)
	manager.resolve_pending_contacts()
	await process_frame
	if not _expect(
		manager.round_faulting_player == player
		and manager.match_state == manager.MatchState.ROUND_OVER
		and manager.player_2_score == 0,
		"A first downward-directed contact did not replay the point without awarding a point."
	):
		return

	print("Normal and dash launch direction, speed scaling, caps, and downward-hit fault verified.")
	quit()
