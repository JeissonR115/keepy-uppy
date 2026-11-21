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
	var player_profiles: Array[Dictionary] = [
		{"player": arena.get_node("Player1") as PlayerController, "prefix": PlayerActionCatalog.PLAYER_ONE_PREFIX},
		{"player": arena.get_node("Player2") as PlayerController, "prefix": PlayerActionCatalog.PLAYER_TWO_PREFIX},
	]
	var shared_settings := (player_profiles[0].player.visual_profile.get("shared_settings")
		as PlayerVisualSettings)
	if not _expect(
		shared_settings != null
		and player_profiles[1].player.visual_profile.get("shared_settings") == shared_settings,
		"Both player profiles do not reference the same tint settings."
	):
		return

	for player_data: Dictionary in player_profiles:
		var player: PlayerController = player_data.player
		var prefix: String = player_data.prefix
		var profile_tint: Color = player.visual_profile.get("tint")
		var identity_color := PlayerActionCatalog.player_color(prefix)
		var expected_tint := profile_tint.lerp(identity_color, shared_settings.tint_strength)
		if not _expect(
			player.visual.modulate == expected_tint
			and player.action_effect.modulate == expected_tint
			and player.visual.sprite_frames.get_frame_texture("idle", 0) != null,
			"%s sprite or action effect lost its readable identity tint." % prefix
		):
			return

		player.movement_state = PlayerController.MovementState.DASH
		player._update_presentation_state(0.0, false, 1.0 / 60.0)
		player.movement_state = PlayerController.MovementState.CLIMB
		player.velocity.y = -45.0
		player._update_presentation_state(0.0, false, 1.0 / 60.0)
		if not _expect(
			player.visual.modulate.r == expected_tint.r
			and player.visual.modulate.g == expected_tint.g
			and player.visual.modulate.b == expected_tint.b
			and player.action_effect.modulate == expected_tint,
			"%s body or action effect lost its identity tint during dash or climb." % prefix
		):
			return

		var source_afterimage_tint: Color = player.visual_profile.get("dash_afterimage_tint")
		var expected_afterimage := source_afterimage_tint.lerp(
			identity_color, shared_settings.tint_strength
		)
		var actual_afterimage: Color = player.presentation.dash_afterimage_tint
		if not _expect(
			is_equal_approx(actual_afterimage.r, expected_afterimage.r)
			and is_equal_approx(actual_afterimage.g, expected_afterimage.g)
			and is_equal_approx(actual_afterimage.b, expected_afterimage.b)
			and is_equal_approx(actual_afterimage.a, source_afterimage_tint.a),
			"%s afterimage tint did not blend identity while preserving its alpha." % prefix
		):
			return

		var afterimage := (
			load("res://src/models/player/player_dash_afterimage.tscn") as PackedScene
		).instantiate() as Area2D
		afterimage.monitoring = false
		afterimage.collision_mask = 0
		arena.add_child(afterimage)
		afterimage.call(
			"configure",
			player,
			player.visual,
			player.dash_rescue_half_extents * 2.0,
			actual_afterimage,
			1.0
		)
		var afterimage_sprite := afterimage.get_node("Sprite") as Sprite2D
		if not _expect(
			afterimage_sprite.texture != null
			and afterimage_sprite.modulate == actual_afterimage,
			"%s dash afterimage did not render with its blended identity tint." % prefix
		):
			return
		afterimage.queue_free()

	main_scene.queue_free()
	await process_frame
	print("Both player profiles retain readable identity tint through sprite, effect, dash, and climb visuals.")
	quit()
