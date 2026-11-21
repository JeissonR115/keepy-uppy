extends SceneTree

const CONFIG_SCRIPT := preload(
	"res://src/managers/python_policy_launcher_config.gd"
)
const TEST_SETTINGS_PATH := "user://keepy-python-policy-test.cfg"


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
	var missing := config.load_config()
	if not _expect(
		not missing.valid and missing.reason.contains("missing"),
		"A missing Python policy configuration was accepted.",
	):
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
	_remove_test_file()
	print("Python policy launcher configuration validation verified.")
	quit()


func _remove_test_file() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)
