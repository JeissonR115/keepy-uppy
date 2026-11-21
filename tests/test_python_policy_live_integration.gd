extends SceneTree

const POLICY_SETTINGS_PATH := "user://python-policy.cfg"
const STARTUP_TIMEOUT := 20.0

var _original_settings: PackedByteArray
var _had_original_settings: bool = false
var _main_scene: Node
var _bridge_port: int = 0
var _failed: bool = false
var _cleanup_started: bool = false


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
		if coordinator.bridge_server != null:
			break
		await process_frame
	if not _expect(
		coordinator.bridge_server != null,
		"Godot did not create its live bridge for the configured Python client.",
	):
		return

	var received_actions: Array[CPUIntent] = []
	coordinator.bridge_server.action_received.connect(
		func(action: CPUIntent, _sequence: int) -> void:
			received_actions.append(action)
	)
	for _frame in range(1800):
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
		and manager.match_state == MatchManager.MatchState.ACTIVE
		and player.cpu_controller.active_brain is RemoteBrain,
		"Real Python client did not become the CPU brain: %s"
		% coordinator.fallback_reason,
	):
		return

	for _frame in range(1800):
		if not received_actions.is_empty():
			break
		await physics_frame
	if not _expect(
		not received_actions.is_empty(),
		"Real Python policy did not return a valid action to the game.",
	):
		return

	var original_turn := manager.expected_balloon_player
	var changed_turn := manager.player_1 if original_turn == manager.player_2 else manager.player_2
	manager.set_next_server(changed_turn)
	var changed_observation := CPUObservationBuilder.build_for(player)
	if not _expect(
		changed_observation.current_turn == changed_turn.input_prefix,
		"Godot observation did not include the changed balloon turn.",
	):
		return
	var action_count_before_turn_change := received_actions.size()
	for _frame in range(1800):
		if received_actions.size() > action_count_before_turn_change:
			break
		await physics_frame
	if not _expect(
		received_actions.size() > action_count_before_turn_change,
		"Python policy did not return an action after the balloon turn changed.",
	):
		return

	var child_pid := coordinator.child_pid
	menu._stop_python_policy()
	await coordinator.stop_and_wait()
	if not _expect(
		child_pid > 0 and not OS.is_process_running(child_pid),
		"Real Python client did not exit after the live bridge disconnected.",
	):
		return
	var released_port := TCPServer.new()
	var port_error := released_port.listen(_bridge_port, "127.0.0.1")
	if port_error == OK:
		released_port.stop()
	if not _expect(port_error == OK, "Live Python bridge did not release its port."):
		return
	_cleanup_and_quit()


func _write_test_settings() -> bool:
	var uv_executable := "uv"
	var config := ConfigFile.new()
	_bridge_port = 20000 + OS.get_process_id() % 30000
	config.set_value("python_policy", "enabled", true)
	config.set_value("python_policy", "executable", uv_executable)
	config.set_value(
		"python_policy",
		"ai_project_path",
		ProjectSettings.globalize_path("res://").path_join("../keepy-uppy-ai").simplify_path(),
	)
	config.set_value("python_policy", "bridge_port", _bridge_port)
	config.set_value("python_policy", "startup_timeout", STARTUP_TIMEOUT)
	return config.save(POLICY_SETTINGS_PATH) == OK


func _backup_settings() -> void:
	_had_original_settings = FileAccess.file_exists(POLICY_SETTINGS_PATH)
	if _had_original_settings:
		_original_settings = FileAccess.get_file_as_bytes(POLICY_SETTINGS_PATH)


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
		print("Real Python policy returned actions and handled a live turn change.")
	quit(1 if _failed else 0)
