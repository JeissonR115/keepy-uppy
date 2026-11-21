class_name PythonPolicyMatchCoordinator
extends Node

signal status_changed(reason: String)

const CONFIG_SCRIPT := preload("res://src/managers/python_policy_launcher_config.gd")
const GEOMETRY_EXPORTER := preload("res://src/managers/cpu_level_geometry_exporter.gd")

var bridge_server: CPUBridgeServer
var child_pid: int = -1
var config_result: Dictionary = {}
var level_manager: LevelManager
var player_2: PlayerController
var geometry_ready: bool = false
var active_level: String = ""
var fallback_reason: String = ""
var _stopping: bool = false


func start_for_match(
	arena_level_manager: LevelManager,
	bot_player: PlayerController,
) -> bool:
	stop()
	level_manager = arena_level_manager
	player_2 = bot_player
	active_level = str(level_manager.get_selected_arena().get("id"))
	var config := CONFIG_SCRIPT.new()
	config_result = config.load_config()
	if not bool(config_result.get("valid", false)):
		fallback_reason = str(config_result.get("reason", "Python policy unavailable"))
		status_changed.emit(fallback_reason)
		return false
	bridge_server = CPUBridgeServer.new()
	bridge_server.process_mode = Node.PROCESS_MODE_ALWAYS
	bridge_server.set_live_match_mode(true)
	add_child(bridge_server)
	bridge_server.command_received.connect(_on_command_received)
	bridge_server.client_connected.connect(_on_client_connected)
	bridge_server.client_disconnected.connect(_on_client_disconnected)
	var port := int(config_result.bridge_port)
	var error := bridge_server.start(port)
	if error != OK:
		fallback_reason = "Could not start the Python bridge on port %d." % port
		status_changed.emit(fallback_reason)
		stop()
		return false
	var args := CONFIG_SCRIPT.build_launch_args(
		config_result,
		"127.0.0.1",
		port,
		active_level,
	)
	child_pid = OS.create_process(str(config_result.executable), args)
	if child_pid <= 0:
		fallback_reason = "Could not launch the configured Python client."
		status_changed.emit(fallback_reason)
		stop()
		return false
	status_changed.emit("Starting Python CPU policy...")
	return await _wait_for_ready(float(config_result.startup_timeout))


func stop() -> void:
	if _stopping:
		return
	_stopping = true
	geometry_ready = false
	if bridge_server != null:
		bridge_server.stop()
		bridge_server.queue_free()
		bridge_server = null
	if child_pid > 0:
		var pid := child_pid
		var grace_timer := get_tree().create_timer(3.0)
		grace_timer.process_mode = Node.PROCESS_MODE_ALWAYS
		grace_timer.timeout.connect(
			func() -> void:
				if OS.is_process_running(pid):
					OS.kill(pid)
		)
		child_pid = -1
	_stopping = false


func is_ready() -> bool:
	return geometry_ready and bridge_server != null and bridge_server.is_client_connected()


func _wait_for_ready(timeout_seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if child_pid > 0 and not OS.is_process_running(child_pid) and not bridge_server.is_client_connected():
			fallback_reason = "Python client exited during startup."
			status_changed.emit(fallback_reason)
			stop()
			return false
		if is_ready():
			status_changed.emit("Python CPU policy connected.")
			return true
		await get_tree().process_frame
	fallback_reason = "Python policy startup timed out."
	status_changed.emit(fallback_reason)
	stop()
	return false


func _on_client_connected(_session_id: String) -> void:
	status_changed.emit("Python CPU policy connected; waiting for geometry.")


func _on_client_disconnected() -> void:
	if geometry_ready:
		status_changed.emit("Python CPU policy disconnected; using LocalBrain.")


func _on_command_received(command: String, payload: Dictionary, sequence: int) -> void:
	if command == "close":
		bridge_server.send_command_result(sequence, {})
		return
	if command == "get_level_geometry":
		var requested_level: String = str(payload.get("level", active_level))
		if requested_level != active_level:
			bridge_server.send_protocol_error(
				"invalid_payload",
				"Live bridge geometry level does not match the active arena.",
				sequence,
			)
			return
		var arena: ArenaData = level_manager.get_selected_arena()
		var geometry := GEOMETRY_EXPORTER.export_arena(arena)
		if geometry.is_empty():
			bridge_server.send_protocol_error(
				"geometry_unavailable",
				"Could not export the active arena geometry.",
				sequence,
			)
			return
		bridge_server.send_command_result(sequence, geometry)
		geometry_ready = true
		status_changed.emit("Python CPU geometry ready.")
		return
	bridge_server.send_protocol_error(
		"unsupported_in_live_mode",
		"Simulation-control command '%s' is unavailable in live match mode." % command,
		sequence,
	)
