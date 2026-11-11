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
	if not _expect(
		root.get_multiplayer().multiplayer_peer is OfflineMultiplayerPeer,
		"The local audio test is not using the offline multiplayer peer."
	):
		return
	await create_timer(0.2).timeout

	var positional_before := main_scene.find_children("*", "AudioStreamPlayer2D", true, false).size()
	manager.play_gameplay_event("balloon_explode", Vector2(40.0, 60.0))
	if not _expect(
		main_scene.find_children("*", "AudioStreamPlayer2D", true, false).size()
			== positional_before + 1,
		"Offline gameplay-event playback did not play its sound locally."
	):
		return

	positional_before = main_scene.find_children("*", "AudioStreamPlayer2D", true, false).size()
	manager.play_local_action("jump", Vector2(80.0, 90.0), true)
	if not _expect(
		main_scene.find_children("*", "AudioStreamPlayer2D", true, false).size()
			== positional_before + 1,
		"Offline local-action playback did not play immediately."
	):
		return

	await create_timer(0.2).timeout
	main_scene.queue_free()
	await process_frame
	print("Offline gameplay and immediate local-action dispatch verified.")
	quit()
