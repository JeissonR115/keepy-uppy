class_name PythonPolicyLauncherConfig
extends RefCounted

const SETTINGS_PATH := "user://python-policy.cfg"
const EXAMPLE_SETTINGS_PATH := "user://python-policy.cfg.example"
const SETTINGS_SECTION := "python_policy"
const EXAMPLE_SETTINGS_CONTENT := (
	"[python_policy]\n"
	+ "enabled=true\n"
	+ "executable=\"/absolute/path/to/uv\"\n"
	+ "ai_project_path=\"/absolute/path/to/keepy-uppy-ai\"\n"
	+ "bridge_port=8766\n"
	+ "startup_timeout=5.0\n"
)

var settings_path: String = SETTINGS_PATH
var example_settings_path: String = EXAMPLE_SETTINGS_PATH


func load_config() -> Dictionary:
	var config := ConfigFile.new()
	var load_error := config.load(settings_path)
	if load_error == ERR_FILE_NOT_FOUND:
		return _missing_configuration()
	if load_error != OK:
		return _unreadable_configuration(load_error)
	if not config.has_section_key(SETTINGS_SECTION, "enabled"):
		return _invalid("Python policy configuration is missing the enabled setting.")
	if typeof(config.get_value(SETTINGS_SECTION, "enabled", false)) != TYPE_BOOL:
		return _invalid("Python policy enabled setting must be boolean.")
	var enabled := bool(config.get_value(SETTINGS_SECTION, "enabled"))
	var executable: String = str(config.get_value(SETTINGS_SECTION, "executable", ""))
	var ai_project_path: String = str(config.get_value(SETTINGS_SECTION, "ai_project_path", ""))
	var port: Variant = config.get_value(SETTINGS_SECTION, "bridge_port", 8766)
	var startup_timeout: Variant = config.get_value(SETTINGS_SECTION, "startup_timeout", 5.0)
	if not enabled:
		return {"valid": false, "reason": "Python policy is disabled.", "enabled": false}
	return validate({
		"enabled": enabled,
		"executable": executable,
		"ai_project_path": ai_project_path,
		"bridge_port": port,
		"startup_timeout": startup_timeout,
	})


func validate(candidate: Dictionary) -> Dictionary:
	if typeof(candidate.get("enabled", false)) != TYPE_BOOL:
		return _invalid("Python policy enabled setting must be boolean.")
	if not bool(candidate.get("enabled", false)):
		return {"valid": false, "reason": "Python policy is disabled.", "enabled": false}
	var executable: String = str(candidate.get("executable", "")).strip_edges()
	if executable.is_empty():
		return _invalid("Python policy executable is missing.")
	if executable.contains("/") or executable.contains("\\"):
		var executable_path := ProjectSettings.globalize_path(executable)
		if not FileAccess.file_exists(executable_path):
			return _invalid("Python policy executable was not found.")
	var ai_project_path: String = str(candidate.get("ai_project_path", "")).strip_edges()
	if ai_project_path.is_empty():
		return _invalid("Python AI project path is missing.")
	var resolved_project: String = ai_project_path
	if not resolved_project.is_absolute_path():
		resolved_project = (
			ProjectSettings.globalize_path("res://").path_join(resolved_project)
		).simplify_path()
	else:
		resolved_project = resolved_project.simplify_path()
	if not DirAccess.dir_exists_absolute(resolved_project):
		return _invalid("Python AI project path was not found.")
	if not FileAccess.file_exists(resolved_project.path_join("pyproject.toml")):
		return _invalid("Python AI project is missing pyproject.toml.")
	var port: Variant = candidate.get("bridge_port")
	if typeof(port) != TYPE_INT or int(port) < 1 or int(port) > 65535:
		return _invalid("Python bridge port must be an integer between 1 and 65535.")
	var startup_timeout: Variant = candidate.get("startup_timeout")
	if (
		typeof(startup_timeout) != TYPE_INT
		and typeof(startup_timeout) != TYPE_FLOAT
	):
		return _invalid("Python startup timeout must be numeric.")
	if not is_finite(float(startup_timeout)) or float(startup_timeout) <= 0.0:
		return _invalid("Python startup timeout must be positive.")
	return {
		"valid": true,
		"reason": "",
		"enabled": true,
		"executable": executable,
		"ai_project_path": resolved_project,
		"bridge_port": int(port),
		"startup_timeout": float(startup_timeout),
	}


func save_config(candidate: Dictionary) -> Dictionary:
	var result := validate(candidate)
	if not result.valid:
		return result
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, "enabled", true)
	config.set_value(SETTINGS_SECTION, "executable", result.executable)
	config.set_value(SETTINGS_SECTION, "ai_project_path", result.ai_project_path)
	config.set_value(SETTINGS_SECTION, "bridge_port", result.bridge_port)
	config.set_value(SETTINGS_SECTION, "startup_timeout", result.startup_timeout)
	var error := config.save(settings_path)
	if error != OK:
		return _invalid("Could not save Python policy configuration.")
	return result


static func build_launch_args(
	config_result: Dictionary,
	host: String,
	port: int,
	level: String,
) -> Array[String]:
	return [
		"run",
		"--project",
		str(config_result.ai_project_path),
		"run-live",
		"--host",
		host,
		"--port",
		str(port),
		"--level",
		level,
	]


func _invalid(reason: String) -> Dictionary:
	return {"valid": false, "reason": reason, "enabled": false}


func _missing_configuration() -> Dictionary:
	var expected_path := ProjectSettings.globalize_path(settings_path)
	var example_path := ProjectSettings.globalize_path(example_settings_path)
	var example_error := _create_example_config()
	var reason := "Python policy configuration is missing. Expected file: %s." % expected_path
	if example_error.is_empty():
		reason += " Edit %s and save it as python-policy.cfg." % example_path
	else:
		reason += " Could not create the example at %s: %s" % [example_path, example_error]
	push_warning(reason)
	return _invalid(reason)


func _unreadable_configuration(load_error: Error) -> Dictionary:
	var config_path := ProjectSettings.globalize_path(settings_path)
	var example_path := ProjectSettings.globalize_path(example_settings_path)
	var example_error := _create_example_config()
	var reason := "Python policy configuration at %s could not be read: %s." % [
		config_path,
		error_string(load_error),
	]
	if load_error == ERR_PARSE_ERROR:
		reason += " Quote string values such as executable and ai_project_path."
	if example_error.is_empty():
		reason += " Use the example at %s." % example_path
	else:
		reason += " Could not create the example at %s: %s" % [example_path, example_error]
	push_warning(reason)
	return _invalid(reason)


func _create_example_config() -> String:
	if FileAccess.file_exists(example_settings_path):
		return ""
	var example := FileAccess.open(example_settings_path, FileAccess.WRITE)
	if example == null:
		return error_string(FileAccess.get_open_error())
	var write_succeeded := example.store_string(EXAMPLE_SETTINGS_CONTENT)
	example.close()
	if not write_succeeded:
		return "The example file was not written completely."
	return ""
