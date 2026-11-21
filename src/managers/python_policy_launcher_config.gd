class_name PythonPolicyLauncherConfig
extends RefCounted

const SETTINGS_PATH := "user://python-policy.cfg"
const SETTINGS_SECTION := "python_policy"

var settings_path: String = SETTINGS_PATH


func load_config() -> Dictionary:
	var config := ConfigFile.new()
	var load_error := config.load(settings_path)
	if load_error == ERR_FILE_NOT_FOUND:
		return _invalid("Python policy configuration is missing.")
	if load_error != OK:
		return _invalid("Python policy configuration could not be read.")
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
