extends SceneTree

const MovementConstants = preload("res://src/models/player/player_movement_constants.gd")

var rescued_count := 0


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _on_dash_rescued(_player: CharacterBody2D, _direction: Vector2) -> void:
	rescued_count += 1


func _run_test() -> void:
	var main_scene := (load("res://src/scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main_scene)
	await process_frame
	var main_menu: Node = main_scene.get_node("PlayerCountMenu")
	main_scene.get_node("PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton").pressed.emit()
	main_menu._select_level("classic")
	await physics_frame
	var arena: Node = main_scene.get_node("Arena")
	var player: PlayerController = arena.get_node("Player1")
	var balloon: BalloonController = arena.get_node("Balloon")
	var match_manager: MatchManager = arena.get_node("MatchManager")
	for _frame in range(60):
		if match_manager.accepting_gameplay_input:
			break
		await physics_frame
	if not _expect(
		match_manager.accepting_gameplay_input,
		"Match setup did not release gameplay input before the dash test."
	):
		return
	balloon.dash_rescued.connect(_on_dash_rescued)
	match_manager.set_next_server(player)
	player.reset_for_round(Vector2(112, 90))
	balloon.reset_round(Vector2(280, 48))
	balloon.player_contacts_armed = true
	balloon.gravity_scale = 0.0
	Input.action_press("player_1_right")
	Input.action_press("player_1_dash")
	for _frame in range(30):
		await physics_frame
		if not player.is_dashing and player.presentation.dash_afterimages_spawned == MovementConstants.DASH_AFTERIMAGE_COUNT:
			break
	Input.action_release("player_1_right")
	Input.action_release("player_1_dash")
	if not _expect(
		player.presentation.dash_afterimages_spawned == MovementConstants.DASH_AFTERIMAGE_COUNT
		and not player.presentation.active_afterimages.is_empty()
		and not player.dash_rescue_area.monitoring,
		"Dash did not leave six fading, rescue-enabled sprite afterimages."
	):
		return
	if not _expect(rescued_count == 0 and not player.dash_rescue_hit, "The balloon was unexpectedly rescued before contacting the dash trail."):
		return
	var final_ghost := player.presentation.active_afterimages.back() as Area2D
	var final_ghost_sprite := final_ghost.get_node("Sprite") as Sprite2D
	var source_sprite := player.visual as AnimatedSprite2D
	var player_2 := arena.get_node("Player2") as PlayerController
	var player_2_afterimage_tint: Color = player_2.presentation.dash_afterimage_tint
	if not _expect(
		final_ghost_sprite.texture != null
		and final_ghost_sprite.modulate.a > 0.0
		and is_equal_approx(final_ghost_sprite.modulate.r, player.presentation.dash_afterimage_tint.r)
		and is_equal_approx(final_ghost_sprite.modulate.g, player.presentation.dash_afterimage_tint.g)
		and is_equal_approx(final_ghost_sprite.modulate.b, player.presentation.dash_afterimage_tint.b)
		and is_equal_approx(player.presentation.dash_afterimage_tint.a, 0.55)
		and is_equal_approx(player_2_afterimage_tint.a, 0.55)
		and player_2_afterimage_tint != player.presentation.dash_afterimage_tint
		and final_ghost_sprite.z_index > source_sprite.z_index
		and final_ghost.collision_mask == 4
		and final_ghost.collision_layer == 0,
		"Afterimage does not repeat the player sprite with a translucent visual-only rescue sensor."
	):
		return
	var player_2_ghost := (
		load("res://src/models/player/player_dash_afterimage.tscn") as PackedScene
	).instantiate() as Area2D
	player_2_ghost.monitoring = false
	player_2_ghost.collision_mask = 0
	arena.add_child(player_2_ghost)
	player_2_ghost.call(
		"configure",
		player_2,
		player_2.visual,
		player_2.dash_rescue_half_extents * 2.0,
		player_2_afterimage_tint,
		1.0
	)
	var player_2_ghost_color := (
		player_2_ghost.get_node("Sprite") as Sprite2D
	).modulate
	if not _expect(
		is_equal_approx(player_2_ghost_color.r, player_2_afterimage_tint.r)
		and is_equal_approx(player_2_ghost_color.g, player_2_afterimage_tint.g)
		and is_equal_approx(player_2_ghost_color.b, player_2_afterimage_tint.b)
		and is_equal_approx(player_2_ghost_color.a, player_2_afterimage_tint.a),
		"Player 2's dash afterimage did not use its identity-tinted profile."
	):
		return
	player_2_ghost.queue_free()
	player.is_dashing = true
	player._on_dash_rescue_area_body_entered(balloon)
	player.is_dashing = false
	if not _expect(rescued_count == 1 and player.dash_rescue_hit, "The primary dash rescue could not be established for the extra-trail test."):
		return
	for _frame in range(6):
		await physics_frame
	balloon.global_position = final_ghost.global_position
	balloon.linear_velocity = Vector2.ZERO
	for _frame in range(1):
		await physics_frame
	if not _expect(
		rescued_count == 2 and player.presentation.dash_trail_rescue_hit,
		"The trailing dash sprites did not provide exactly one additional rescue touch: rescues=%d trail=%s ghost=%s monitoring=%s armed=%s cooldown=%s." % [
			rescued_count,
			player.presentation.dash_trail_rescue_hit,
			is_instance_valid(final_ghost),
			final_ghost.monitoring if is_instance_valid(final_ghost) else false,
			balloon.player_contacts_armed,
			balloon.player_contact_cooldowns.get(player.get_instance_id(), -1.0)
		]
	):
		return
	for _frame in range(4):
		await physics_frame
	if not _expect(rescued_count == 2, "The six afterimage areas provided more than one additional rescue touch."):
		return
	for _frame in range(18):
		await physics_frame
	if not _expect(
		player.presentation.active_afterimages.is_empty()
		and player.presentation.dash_afterimages_spawned == MovementConstants.DASH_AFTERIMAGE_COUNT,
		"Dash afterimages or their rescue window outlived the configured fade."
	):
		return
	main_scene.queue_free()
	await process_frame
	print("Six pixel-tinted dash afterimages fade out and extend one rescue opportunity.")
	quit()
