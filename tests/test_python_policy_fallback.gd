extends SceneTree

const LOCAL_BRAIN := preload("res://src/models/player/local_brain.gd")
const POLICY_SETTINGS_PATH := "user://python-policy.cfg"
const EXAMPLE_SETTINGS_PATH := "user://python-policy.cfg.example"
const FALSE_EXECUTABLE := "/usr/bin/false"

var _original_settings: PackedByteArray
var _had_original_settings: bool = false
var _original_example_settings: PackedByteArray
var _had_original_example_settings: bool = false
var _main_scene: Node
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
	var cases: Array[Dictionary] = [
		{
			"mode": "missing",
			"reason": "configuration is missing",
		},
		{
			"mode": "invalid_executable",
			"reason": "executable was not found",
		},
		{
			"mode": "client_exits",
			"reason": "exited during startup",
		},
		{
			"mode": "startup_timeout",
			"reason": "startup timed out",
		},
	]
	for test_case in cases:
		if not await _run_case(test_case):
			return
	_cleanup_and_quit()


func _run_case(test_case: Dictionary) -> bool:
	if not _configure_case(str(test_case.mode)):
		return _expect(false, "Could not configure Python fallback test case.")
	_main_scene = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(_main_scene)
	await process_frame

	var menu: PlayerCountMenu = _main_scene.get_node("PlayerCountMenu")
	var player: PlayerController = _main_scene.get_node("Arena/Player2")
	var manager: MatchManager = _main_scene.get_node("Arena/MatchManager")
	menu._select_player_count(1)
	menu._select_level("classic")
	for _frame in range(600):
		if not menu.visible and manager.match_state == MatchManager.MatchState.ACTIVE:
			break
		await process_frame

	var status_label: Label = _main_scene.get_node("Arena/Scoreboard/HUD/StatusLabel")
	if not _expect(
		not menu.visible
		and manager.match_state == MatchManager.MatchState.ACTIVE
		and manager.accepting_gameplay_input
		and not paused,
		"Local fallback did not start a playable match for %s." % test_case.mode,
	):
		return false
	if not _expect(
		player.bot_enabled and player.cpu_controller.active_brain is LOCAL_BRAIN,
		"Python startup failure did not leave the bot on LocalBrain for %s."
		% test_case.mode,
	):
		return false
	if not _expect(
		status_label.text.to_lower().contains(str(test_case.reason)),
		"Fallback status did not explain %s: %s"
		% [test_case.mode, status_label.text],
	):
		return false

	menu._stop_python_policy()
	var coordinator: PythonPolicyMatchCoordinator = menu.python_policy_coordinator
	await coordinator.stop_and_wait()
	_main_scene.queue_free()
	_main_scene = null
	await process_frame
	return true


func _configure_case(mode: String) -> bool:
	var absolute_path := ProjectSettings.globalize_path(POLICY_SETTINGS_PATH)
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)
	if mode == "missing":
		return true

	var executable := FALSE_EXECUTABLE
	if mode == "invalid_executable":
		executable = "/definitely/missing/python-policy-client"
	elif mode == "startup_timeout":
		executable = ProjectSettings.globalize_path(
			"res://tests/fakes/idle_live_policy_client.py"
		)
	var config := ConfigFile.new()
	config.set_value("python_policy", "enabled", true)
	config.set_value("python_policy", "executable", executable)
	config.set_value(
		"python_policy",
		"ai_project_path",
		ProjectSettings.globalize_path("res://").path_join("../keepy-uppy-ai").simplify_path(),
	)
	config.set_value("python_policy", "bridge_port", 20000 + OS.get_process_id() % 30000)
	config.set_value(
		"python_policy",
		"startup_timeout",
		0.2 if mode == "startup_timeout" else 5.0,
	)
	return config.save(POLICY_SETTINGS_PATH) == OK


func _backup_settings() -> void:
	_had_original_settings = FileAccess.file_exists(POLICY_SETTINGS_PATH)
	if _had_original_settings:
		_original_settings = FileAccess.get_file_as_bytes(POLICY_SETTINGS_PATH)
	_had_original_example_settings = FileAccess.file_exists(EXAMPLE_SETTINGS_PATH)
	if _had_original_example_settings:
		_original_example_settings = FileAccess.get_file_as_bytes(EXAMPLE_SETTINGS_PATH)


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
	if _had_original_example_settings:
		var example_backup := FileAccess.open(EXAMPLE_SETTINGS_PATH, FileAccess.WRITE)
		if example_backup == null:
			push_error("Could not restore the original Python policy example.")
			_failed = true
		else:
			example_backup.store_buffer(_original_example_settings)
			example_backup.close()
			if FileAccess.get_file_as_bytes(EXAMPLE_SETTINGS_PATH) != _original_example_settings:
				push_error("Restored Python policy example does not match its backup.")
				_failed = true
	else:
		var example_absolute_path := ProjectSettings.globalize_path(EXAMPLE_SETTINGS_PATH)
		if (
			FileAccess.file_exists(example_absolute_path)
			and DirAccess.remove_absolute(example_absolute_path) != OK
		):
			push_error("Could not remove temporary Python policy example.")
			_failed = true
	if not _failed:
		print("Python startup failures preserve playable LocalBrain matches.")
	quit(1 if _failed else 0)
