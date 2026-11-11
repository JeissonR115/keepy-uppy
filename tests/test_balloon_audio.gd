extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _positional_sound_count() -> int:
	return root.find_children("*", "AudioStreamPlayer2D", true, false).size()


func _run_test() -> void:
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	current_scene = main_scene
	await process_frame
	var two_players_button: Button = main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	)
	two_players_button.pressed.emit()
	main_scene.get_node("PlayerCountMenu")._select_level("classic")
	var balloon: BalloonController = main_scene.get_node("Arena/Balloon")
	var player: PlayerController = main_scene.get_node("Arena/Player1")
	var manager: Node = root.get_node("AudioManager")

	balloon.global_position = Vector2(160.0, 80.0)
	player.global_position = Vector2(160.0, 90.0)
	player.velocity = Vector2(0.0, -120.0)
	var sounds_before_contact := _positional_sound_count()
	balloon._on_player_contact_area_body_entered(player)
	var normal_contact: Dictionary = balloon.pending_contact_impulses[player.get_instance_id()]
	if not _expect(
		is_equal_approx(normal_contact["impact_speed"], 120.0)
		and _positional_sound_count() == sounds_before_contact + 1,
		"Normal balloon contact did not preserve relative impact speed and play a sound."
	):
		return

	var last_path := str(manager._last_paths["balloon_touch"])
	balloon.player_contact_cooldowns.clear()
	player.velocity = Vector2(0.0, -240.0)
	var sounds_before_hard_hit := _positional_sound_count()
	balloon._on_player_contact_area_body_entered(player)
	var hard_contact: Dictionary = balloon.pending_contact_impulses[player.get_instance_id()]
	if not _expect(
		is_equal_approx(hard_contact["impact_speed"], 240.0)
		and _positional_sound_count() == sounds_before_hard_hit + 1
		and manager._last_paths["balloon_touch"] != last_path,
		"Hard balloon contact did not play a new variant at the higher impact intensity."
	):
		return

	balloon.player_contact_cooldowns.clear()
	player.velocity = Vector2(240.0, 0.0)
	balloon.apply_dash_rescue(player, Vector2.RIGHT)
	var dash_contact: Dictionary = balloon.pending_contact_impulses[player.get_instance_id()]
	if not _expect(
		is_equal_approx(dash_contact["impact_speed"], 240.0),
		"Dash-rescue contact did not use relative impact speed for its sound intensity."
	):
		return

	var ground: Node = main_scene.get_node("Arena/MapRoot/ClassicArenaGeometry/ScoringFloorTiles")
	var sounds_before_burst := _positional_sound_count()
	balloon._on_body_entered(ground)
	balloon._on_body_entered(ground)
	if not _expect(
		_positional_sound_count() == sounds_before_burst + 1 and balloon.ground_contact_reported,
		"Scoring-ground burst sound was not played exactly once."
	):
		return

	await create_timer(0.2).timeout
	main_scene.queue_free()
	await process_frame
	print("Balloon impact intensity, dash rescue, variant changes, and guarded burst verified.")
	quit()
