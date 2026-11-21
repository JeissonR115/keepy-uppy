extends SceneTree

const CONFIG_SCRIPT := preload(
	"res://src/managers/python_policy_launcher_config.gd"
)
const TEST_SETTINGS_PATH := "user://keepy-python-policy-test.cfg"
const TEST_EXAMPLE_PATH := "user://keepy-python-policy-test.cfg.example"


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _run_test() -> void:
	_remove_test_file()
	var config := CONFIG_SCRIPT.new()
	config.settings_path = TEST_SETTINGS_PATH
	config.example_settings_path = TEST_EXAMPLE_PATH
	var missing := config.load_config()
	if not _expect(
		not missing.valid
		and missing.reason.contains("missing")
		and missing.reason.contains(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))
		and FileAccess.file_exists(TEST_EXAMPLE_PATH),
		"A missing Python policy configuration was accepted.",
	):
		return
	var example := ConfigFile.new()
	if not _expect(
		example.load(TEST_EXAMPLE_PATH) == OK
		and example.get_value("python_policy", "enabled", false)
		and example.get_value("python_policy", "executable", "").contains("absolute/path"),
		"Missing configuration did not generate an editable valid example file.",
	):
		return
	var manual_config := FileAccess.open(TEST_SETTINGS_PATH, FileAccess.WRITE)
	if not _expect(manual_config != null, "Could not create a manual config fixture."):
		return
	var manual_ai_project := ProjectSettings.globalize_path("res://").path_join(
		"../keepy-uppy-ai"
	).simplify_path()
	manual_config.store_string(
		"[python_policy]\n"
		+ "enabled=true\n"
		+ "executable=/usr/bin/python3\n"
		+ "ai_project_path=%s\n" % manual_ai_project
		+ "bridge_port=8766\n"
		+ "startup_timeout=5.0\n"
	)
	manual_config.close()
	var unquoted := config.load_config()
	if not _expect(
		not unquoted.valid and unquoted.reason.contains("Quote string values"),
		"Unquoted path values were not diagnosed with actionable guidance.",
	):
		return
	manual_config = FileAccess.open(TEST_SETTINGS_PATH, FileAccess.WRITE)
	if not _expect(manual_config != null, "Could not write a quoted config fixture."):
		return
	manual_config.store_string(
		"[python_policy]\n"
		+ "enabled=true\n"
		+ "executable=\"/usr/bin/python3\"\n"
		+ "ai_project_path=\"%s\"\n" % manual_ai_project
		+ "bridge_port=8766\n"
		+ "startup_timeout=5.0\n"
	)
	manual_config.close()
	var manually_written := config.load_config()
	if not _expect(manually_written.valid, "A quoted manual config could not be loaded."):
		return
	var invalid_port := config.validate({
		"enabled": true,
		"executable": "uv",
		"ai_project_path": "../keepy-uppy-ai",
		"bridge_port": 70000,
		"startup_timeout": 5.0,
	})
	if not _expect(
		not invalid_port.valid,
		"An out-of-range Python bridge port was accepted.",
	):
		return
	var invalid_timeout := config.validate({
		"enabled": true,
		"executable": "uv",
		"ai_project_path": "../keepy-uppy-ai",
		"bridge_port": 8766,
		"startup_timeout": 0.0,
	})
	if not _expect(
		not invalid_timeout.valid,
		"A zero startup timeout was accepted.",
	):
		return
	var ai_project := ProjectSettings.globalize_path("res://").path_join(
		"../keepy-uppy-ai"
	).simplify_path()
	var valid_project := DirAccess.dir_exists_absolute(ai_project)
	if not valid_project:
		print("Python policy config test: sibling project unavailable; path validation skipped.")
	else:
		var valid := config.validate({
			"enabled": true,
			"executable": "uv",
			"ai_project_path": "../keepy-uppy-ai",
			"bridge_port": 8766,
			"startup_timeout": 5.0,
		})
		if not _expect(valid.valid, "A valid Python policy config was rejected: %s" % valid.reason):
			return
		var saved := config.save_config(valid)
		if not _expect(saved.valid, "A valid Python policy config could not be saved."):
			return
		var reloaded := config.load_config()
		if not _expect(reloaded.valid and reloaded.bridge_port == 8766, "Saved Python policy config did not reload."):
			return
	var launch_args: Array[String] = config.build_launch_args({
		"ai_project_path": "/tmp/keepy-uppy-ai",
	}, "127.0.0.1", 8766, "classic")
	if not _expect(
		launch_args == [
			"run",
			"--project",
			"/tmp/keepy-uppy-ai",
			"run-live",
			"--host",
			"127.0.0.1",
			"--port",
			"8766",
			"--level",
			"classic",
		],
		"Python policy launch arguments were not a fixed safe argument vector.",
	):
		return
	var fake_pid := OS.create_process("/bin/true", launch_args)
	if not _expect(fake_pid > 0, "A fake executable launch did not start successfully."):
		return
	for _frame in range(10):
		if not OS.is_process_running(fake_pid):
			break
		await process_frame
	var missing_pid := OS.create_process(
		"/definitely/missing/python-policy-fake",
		launch_args,
	)
	for _frame in range(10):
		if missing_pid <= 0 or not OS.is_process_running(missing_pid):
			break
		await process_frame
	if not _expect(
		missing_pid <= 0 or not OS.is_process_running(missing_pid),
		"A missing executable launch did not report an error.",
	):
		return
	_remove_test_file()
	print("Python policy launcher configuration validation verified.")
	quit()


func _remove_test_file() -> void:
	for settings_path in [TEST_SETTINGS_PATH, TEST_EXAMPLE_PATH]:
		var absolute_path := ProjectSettings.globalize_path(settings_path)
		if FileAccess.file_exists(absolute_path):
			DirAccess.remove_absolute(absolute_path)
