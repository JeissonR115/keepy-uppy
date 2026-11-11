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
	await process_frame
	var manager: Node = root.get_node("AudioManager")
	if not _expect(manager._events.size() == 11, "AudioManager did not load all 11 manifest events."):
		return
	if not _expect(
		AudioServer.get_bus_index("SFX") >= 0 and AudioServer.get_bus_index("UI") >= 0,
		"The SFX and UI audio buses are not available."
	):
		return

	var manifest: Dictionary = manager._events
	var path_count := 0
	for event_id: String in manifest:
		var event: Dictionary = manifest[event_id]
		var expected_files: Array = []
		var loaded_variants: Array = []
		if event["mode"] == "intensity":
			for files: Array in event["files"].values():
				expected_files.append_array(files)
			for variants: Array in manager._streams[event_id].values():
				loaded_variants.append_array(variants)
		else:
			expected_files = event["files"]
			loaded_variants = manager._streams[event_id]
		path_count += expected_files.size()
		for path: String in expected_files:
			var found := false
			for variant: Dictionary in loaded_variants:
				if variant["path"] == path:
					found = true
					if not _expect(
						variant["stream"] is AudioStreamWAV
						and variant["stream"].loop_mode == AudioStreamWAV.LOOP_DISABLED,
						"Audio asset is not a non-looping WAV: %s" % path
					):
						return
			if not _expect(found, "AudioManager did not load manifest asset %s." % path):
				return
	if not _expect(path_count == 29, "The manifest does not describe exactly 29 WAV assets."):
		return

	for event_id: String in ["laugh_p1", "laugh_p2", "footstep"]:
		var previous_path := ""
		for _variant in range(12):
			var picked: Dictionary = manager._pick(event_id, 0.5)
			if not _expect(
				not picked.is_empty() and picked["path"] != previous_path,
				"Event %s repeated the same variant consecutively." % event_id
			):
				return
			previous_path = picked["path"]

	for tier: String in ["soft", "medium", "hard"]:
		var previous_path := ""
		var intensity: float = {"soft": 0.2, "medium": 0.5, "hard": 0.9}[tier]
		for _variant in range(8):
			var picked: Dictionary = manager._pick("balloon_touch", intensity)
			if not _expect(
				picked["path"].contains("_%s_" % tier)
				and picked["path"] != previous_path,
				"Balloon-touch tier selection or consecutive variation failed for %s." % tier
			):
				return
			previous_path = picked["path"]

	var quiet_step: Dictionary = manager._pick("footstep", 0.0)
	var loud_step: Dictionary = manager._pick("footstep", 1.0)
	if not _expect(
		is_equal_approx(quiet_step["volume_db"], -14.0)
		and is_equal_approx(loud_step["volume_db"], -8.0),
		"Footstep volume does not interpolate between -14 and -8 dB."
	):
		return
	var quiet_hit: Dictionary = manager._pick("balloon_touch", 0.0)
	var loud_hit: Dictionary = manager._pick("balloon_touch", 1.0)
	if not _expect(
		is_equal_approx(quiet_hit["volume_db"], -12.0)
		and is_equal_approx(loud_hit["volume_db"], -2.0),
		"Balloon-touch volume does not interpolate between -12 and -2 dB."
	):
		return

	var previous_child_count := manager.get_child_count()
	manager.play("menu_select")
	manager.play("menu_select")
	if not _expect(
		manager.get_child_count() == previous_child_count + 2,
		"Overlapping sounds did not create independent playback instances."
	):
		return
	await create_timer(0.5).timeout
	if not _expect(
		manager.get_child_count() == previous_child_count,
		"Finished audio players were not freed."
	):
		return

	print("Audio manifest, buses, WAV import settings, variants, volume, and overlap verified.")
	quit()
