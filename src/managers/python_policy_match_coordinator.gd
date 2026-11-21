class_name PythonPolicyMatchCoordinator
extends Node

signal status_changed(reason: String)
signal connection_state_changed(active: bool)
signal shutdown_completed

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
var _shutdown_pid: int = -1
var _shutdown_in_progress: bool = false


func start_for_match(
	arena_level_manager: LevelManager,
	bot_player: PlayerController,
) -> bool:
	await stop_and_wait()
	fallback_reason = ""
	connection_state_changed.emit(false)
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
		await stop_and_wait()
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
		await stop_and_wait()
		return false
	status_changed.emit("Starting Python CPU policy...")
	return await _wait_for_ready(float(config_result.startup_timeout))


func reconnect_for_match() -> bool:
	if level_manager == null or not is_instance_valid(level_manager):
		status_changed.emit("Python policy has no active match to reconnect.")
		connection_state_changed.emit(false)
		return false
	if player_2 == null or not is_instance_valid(player_2):
		status_changed.emit("Python policy has no active bot to reconnect.")
		connection_state_changed.emit(false)
		return false
	var ready := await start_for_match(level_manager, player_2)
	if ready:
		player_2.cpu_controller.use_remote_brain(bridge_server, 0.25)
		connection_state_changed.emit(true)
	else:
		player_2.cpu_controller.use_local_brain()
		connection_state_changed.emit(false)
	return ready


func stop() -> void:
	geometry_ready = false
	_close_bridge()
	if child_pid <= 0 or _shutdown_in_progress:
		return
	_shutdown_pid = child_pid
	child_pid = -1
	if not is_inside_tree():
		_kill_child(_shutdown_pid)
		_shutdown_pid = -1
		return
	_shutdown_in_progress = true
	call_deferred("_wait_for_child_shutdown", _shutdown_pid)


func stop_and_wait() -> void:
	if not _shutdown_in_progress:
		stop()
	if _shutdown_in_progress:
		await shutdown_completed


func stop_immediately() -> void:
	geometry_ready = false
	_close_bridge()
	var pid := child_pid if child_pid > 0 else _shutdown_pid
	child_pid = -1
	_shutdown_pid = -1
	_shutdown_in_progress = false
	if pid > 0:
		_kill_child(pid)


func _close_bridge() -> void:
	if bridge_server == null:
		return
	bridge_server.stop()
	bridge_server.queue_free()
	bridge_server = null


func _wait_for_child_shutdown(pid: int) -> void:
	var graceful_deadline := Time.get_ticks_msec() + 3000
	while OS.is_process_running(pid) and Time.get_ticks_msec() < graceful_deadline:
		await get_tree().process_frame
	if OS.is_process_running(pid):
		_kill_child(pid)
	var termination_deadline := Time.get_ticks_msec() + 1000
	while OS.is_process_running(pid) and Time.get_ticks_msec() < termination_deadline:
		await get_tree().process_frame
	if OS.is_process_running(pid):
		child_pid = pid
		fallback_reason = "Python client process %d did not exit after termination." % pid
		status_changed.emit(fallback_reason)
		push_error(fallback_reason)
	_shutdown_pid = -1
	_shutdown_in_progress = false
	shutdown_completed.emit()


func _kill_child(pid: int) -> void:
	if not OS.is_process_running(pid):
		return
	var error := OS.kill(pid)
	if error != OK and OS.is_process_running(pid):
		push_error("Could not terminate Python client process %d: %s" % [pid, error_string(error)])


func is_ready() -> bool:
	return geometry_ready and bridge_server != null and bridge_server.is_client_connected()


func _wait_for_ready(timeout_seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if child_pid > 0 and not OS.is_process_running(child_pid) and not bridge_server.is_client_connected():
			fallback_reason = "Python client exited during startup."
			status_changed.emit(fallback_reason)
			await stop_and_wait()
			return false
		if is_ready():
			status_changed.emit("Python CPU policy connected.")
			connection_state_changed.emit(true)
			return true
		await get_tree().process_frame
	fallback_reason = "Python policy startup timed out."
	status_changed.emit(fallback_reason)
	await stop_and_wait()
	return false


func _on_client_connected(_session_id: String) -> void:
	status_changed.emit("Python CPU policy connected; waiting for geometry.")


func _on_client_disconnected() -> void:
	geometry_ready = false
	connection_state_changed.emit(false)
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
