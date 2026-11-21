extends SceneTree

const FAKE_CLIENT_PATH := "res://tests/fakes/fake_live_policy_client.py"
const POLICY_SETTINGS_PATH := "user://python-policy.cfg"

var _original_settings: PackedByteArray
var _had_original_settings: bool = false
var _main_scene: Node
var _child_pid: int = -1
var _bridge_port: int = 0
var _cleanup_started: bool = false
var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	_failed = true
	call_deferred("_cleanup_and_quit")
	return false


func _run_test() -> void:
	_backup_settings()
	if not _write_test_settings():
		_expect(false, "Could not write temporary Python policy settings.")
		return

	_main_scene = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(_main_scene)
	await process_frame
	var menu: PlayerCountMenu = _main_scene.get_node("PlayerCountMenu")
	var player: PlayerController = _main_scene.get_node("Arena/Player2")
	var manager: MatchManager = _main_scene.get_node("Arena/MatchManager")

	menu._select_player_count(1)
	menu._select_level("classic")
	var coordinator: PythonPolicyMatchCoordinator = menu.python_policy_coordinator
	for _frame in range(600):
		if coordinator.is_ready() and not menu.visible:
			break
		await process_frame
	if not _expect(
		coordinator.is_ready() and not menu.visible,
		"Python client did not become ready after arena selection.",
	):
		return

	for _frame in range(120):
		if manager.match_state == MatchManager.MatchState.ACTIVE:
			break
		await physics_frame
	var remote := player.cpu_controller.active_brain as RemoteBrain
	if not _expect(
		coordinator.is_ready()
		and coordinator.geometry_ready
		and remote != null
		and manager.match_state == MatchManager.MatchState.ACTIVE
		and not paused,
		(
			"Python readiness did not start the remote match: ready=%s geometry=%s "
			+ "brain=%s match_state=%s paused=%s."
		)
		% [
			coordinator.is_ready(),
			coordinator.geometry_ready,
			player.cpu_controller.active_brain.get_class(),
			manager.match_state,
			paused,
		],
	):
		return

	for _frame in range(120):
		if player.cpu_controller.intents.horizontal == -1.0:
			break
		await physics_frame
	if not _expect(
		player.cpu_controller.active_brain is RemoteBrain
		and player.cpu_controller.intents.horizontal == -1.0,
		"The fake Python client action did not reach the bot during gameplay.",
	):
		return

	_child_pid = coordinator.child_pid
	menu._stop_python_policy()
	await coordinator.stop_and_wait()
	if not _expect(
		_child_pid > 0 and not OS.is_process_running(_child_pid),
		"Fake Python client did not exit after the live bridge disconnected.",
	):
		return

	var released_port := TCPServer.new()
	var released_error := released_port.listen(_bridge_port, "127.0.0.1")
	if released_error == OK:
		released_port.stop()
	if not _expect(
		released_error == OK,
		"Python bridge port was not released after stopping the match.",
	):
		return

	menu.open_menu()
	menu._select_player_count(1)
	menu._select_level("classic")
	for _frame in range(600):
		if (
			coordinator.is_ready()
			and not menu.visible
			and manager.match_state == MatchManager.MatchState.ACTIVE
		):
			break
		await process_frame
	if not _expect(
		coordinator.is_ready()
		and not menu.visible
		and manager.match_state == MatchManager.MatchState.ACTIVE,
		(
			"Python policy could not start a second match after cleanup: "
			+ "ready=%s visible=%s match_state=%s reason=%s."
		)
		% [
			coordinator.is_ready(),
			menu.visible,
			manager.match_state,
			coordinator.fallback_reason,
		],
	):
		return
	var second_pid := coordinator.child_pid
	menu._stop_python_policy()
	await coordinator.stop_and_wait()
	if not _expect(
		second_pid > 0 and not OS.is_process_running(second_pid),
		"Second Python child remained alive after returning to the menu.",
	):
		return

	menu.open_menu()
	menu._select_player_count(1)
	menu._select_level("classic")
	for _frame in range(600):
		if (
			coordinator.is_ready()
			and not menu.visible
			and manager.match_state == MatchManager.MatchState.ACTIVE
		):
			break
		await process_frame
	if not _expect(
		coordinator.is_ready()
		and not menu.visible
		and manager.match_state == MatchManager.MatchState.ACTIVE,
		"Python policy could not start a match before testing game exit.",
	):
		return
	var exiting_pid := coordinator.child_pid
	_main_scene.queue_free()
	_main_scene = null
	for _frame in range(120):
		if not _process_exists(exiting_pid):
			break
		await process_frame
	if not _expect(
		exiting_pid > 0 and not _process_exists(exiting_pid),
		"Python child remained alive after the game scene exited.",
	):
		return
	_cleanup_and_quit()


func _backup_settings() -> void:
	_had_original_settings = FileAccess.file_exists(POLICY_SETTINGS_PATH)
	if _had_original_settings:
		_original_settings = FileAccess.get_file_as_bytes(POLICY_SETTINGS_PATH)


func _process_exists(pid: int) -> bool:
	var output: Array[String] = []
	return OS.execute("/bin/kill", ["-0", str(pid)], output, true) == 0


func _ai_project_path() -> String:
	return ProjectSettings.globalize_path("res://").path_join(
		"../keepy-uppy-ai"
	).simplify_path()


func _write_test_settings() -> bool:
	var config := ConfigFile.new()
	config.set_value("python_policy", "enabled", true)
	config.set_value(
		"python_policy",
		"executable",
		ProjectSettings.globalize_path(FAKE_CLIENT_PATH),
	)
	config.set_value("python_policy", "ai_project_path", _ai_project_path())
	_bridge_port = 20000 + OS.get_process_id() % 30000
	config.set_value("python_policy", "bridge_port", _bridge_port)
	config.set_value("python_policy", "startup_timeout", 5.0)
	return config.save(POLICY_SETTINGS_PATH) == OK


func _cleanup_and_quit() -> void:
	if _cleanup_started:
		return
	_cleanup_started = true
	if is_instance_valid(_main_scene):
		var menu := _main_scene.get_node_or_null("PlayerCountMenu")
		if menu != null:
			menu._stop_python_policy()
			var coordinator: PythonPolicyMatchCoordinator = menu.python_policy_coordinator
			await coordinator.stop_and_wait()
		_main_scene.queue_free()
		await process_frame
	if _had_original_settings:
		var backup := FileAccess.open(POLICY_SETTINGS_PATH, FileAccess.WRITE)
		if backup == null:
			push_error("Could not restore the original Python policy configuration.")
			_failed = true
		else:
			backup.store_buffer(_original_settings)
			backup.close()
			if FileAccess.get_file_as_bytes(POLICY_SETTINGS_PATH) != _original_settings:
				push_error("Restored Python policy configuration does not match its backup.")
				_failed = true
	else:
		var absolute_path := ProjectSettings.globalize_path(POLICY_SETTINGS_PATH)
		if (
			FileAccess.file_exists(absolute_path)
			and DirAccess.remove_absolute(absolute_path) != OK
		):
			push_error("Could not remove temporary Python policy configuration.")
			_failed = true
	if not _failed:
		print("Python live client controlled the bot in the selected arena.")
	quit(1 if _failed else 0)
