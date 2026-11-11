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
	current_scene = main_scene
	await process_frame

	var manager: Node = root.get_node("AudioManager")
	var menu: PlayerCountMenu = main_scene.get_node("PlayerCountMenu")
	var scoreboard: Scoreboard = main_scene.get_node("Arena/Scoreboard")
	if not _expect(
		manager._menu_music.playing and not manager._match_music.playing,
		"Menu music did not start automatically with the initial menu."
	):
		return
	if not _expect(
		manager._menu_music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD
		and manager._match_music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,
		"Menu and match music are not configured to loop."
	):
		return
	if not _expect(
		is_equal_approx(manager._menu_music.volume_db, -6.0)
		and is_equal_approx(manager._match_music.volume_db, -4.0)
		and is_equal_approx(manager._match_music.pitch_scale, 0.92),
		"Music volume or the lower match pitch is not configured."
	):
		return

	menu._select_player_count(2)
	if not _expect(
		manager._match_music.playing and not manager._menu_music.playing,
		"Selecting a game mode did not switch to match music."
	):
		return

	scoreboard._on_match_ended(scoreboard.match_manager.player_1)
	if not _expect(
		manager._menu_music.playing and not manager._match_music.playing,
		"Ending the match did not automatically restore menu music."
	):
		return

	manager.call("play_match_music")
	menu.open_menu()
	if not _expect(
		manager._menu_music.playing and not manager._match_music.playing,
		"Opening the player-count menu did not restore menu music."
	):
		return

	main_scene.queue_free()
	await process_frame
	print("Looping menu and match music, automatic transitions, volume, and pitch verified.")
	quit()
