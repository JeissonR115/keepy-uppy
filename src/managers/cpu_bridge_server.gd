class_name CPUBridgeServer
extends Node

signal client_connected(session_id: String)
signal client_disconnected
signal command_received(command: String, payload: Dictionary, sequence: int)
signal action_received(action: CPUIntent, sequence: int)

const PROTOCOL_VERSION := 1
const MAX_MESSAGE_BYTES := 1_048_576
const ALLOWED_COMMANDS := [
	"reset",
	"step",
	"set_speed",
	"get_level_geometry",
	"load_nav_graph",
	"close",
]

var _server := TCPServer.new()
var _client: StreamPeerTCP
var _receive_buffer := PackedByteArray()
var _session_id: String = ""
var _last_command_sequence: int = 0
var _next_action_sequence: int = 1
var _pending_action_sequences: Dictionary = {}


func _ready() -> void:
	set_process(false)


func start(port: int) -> Error:
	if port < 1 or port > 65535:
		push_error("CPU bridge port must be between 1 and 65535.")
		return ERR_INVALID_PARAMETER
	if _server.is_listening():
		push_error("CPU bridge server is already listening.")
		return ERR_ALREADY_IN_USE
	var error := _server.listen(port, "127.0.0.1")
	if error != OK:
		push_error("Could not listen on CPU bridge port %d: %s" % [port, error_string(error)])
		return error
	_last_command_sequence = 0
	_next_action_sequence = 1
	_pending_action_sequences.clear()
	set_process(true)
	return OK


func stop() -> void:
	set_process(false)
	_server.stop()
	_close_client(false)


func is_client_connected() -> bool:
	return (
		_client != null
		and _client.get_status() == StreamPeerTCP.STATUS_CONNECTED
	)


func request_action(observation: Dictionary) -> int:
	if not is_client_connected():
		return -1
	var sequence := _next_action_sequence
	_next_action_sequence += 1
	_pending_action_sequences[sequence] = true
	if not _send_message(
		{
			"type": "observation",
			"protocol_version": PROTOCOL_VERSION,
			"session_id": _session_id,
			"sequence": sequence,
			"observation": observation,
		}
	):
		_pending_action_sequences.erase(sequence)
		return -1
	return sequence


func cancel_action_request(sequence: int) -> bool:
	return _pending_action_sequences.erase(sequence)


func send_command_result(sequence: int, result: Dictionary) -> bool:
	return _send_message(
		{
			"type": "command_result",
			"protocol_version": PROTOCOL_VERSION,
			"session_id": _session_id,
			"sequence": sequence,
			"ok": true,
			"result": result,
		}
	)


func send_episode_event(event: Dictionary) -> bool:
	return _send_message(
		{
			"type": "episode_event",
			"protocol_version": PROTOCOL_VERSION,
			"session_id": _session_id,
			"event": event,
		}
	)


func send_protocol_error(code: String, message: String, sequence: int = 0) -> bool:
	var error_message := {
		"type": "error",
		"protocol_version": PROTOCOL_VERSION,
		"session_id": _session_id,
		"code": code,
		"message": message,
	}
	if sequence > 0:
		error_message["sequence"] = sequence
	return _send_message(error_message)


func _process(_delta: float) -> void:
	_accept_client()
	if not is_client_connected():
		return
	var poll_error := _client.poll()
	if poll_error != OK:
		_handle_client_disconnect("Could not poll CPU bridge client: %s" % error_string(poll_error))
		return
	if _client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		_handle_client_disconnect("CPU bridge client disconnected.")
		return
	var available_bytes := _client.get_available_bytes()
	if available_bytes <= 0:
		return
	var read_result: Array = _client.get_data(available_bytes)
	if read_result[0] != OK:
		_handle_client_disconnect(
			"Could not read CPU bridge client data: %s" % error_string(read_result[0])
		)
		return
	_receive_buffer.append_array(read_result[1])
	_process_received_lines()
	if _receive_buffer.size() > MAX_MESSAGE_BYTES:
		send_protocol_error("message_too_large", "JSON line exceeds the 1 MiB protocol limit.")
		_handle_client_disconnect("CPU bridge message exceeded the size limit.")


func _accept_client() -> void:
	if not _server.is_listening() or not _server.is_connection_available():
		return
	var incoming := _server.take_connection()
	if is_client_connected():
		incoming.disconnect_from_host()
		return
	_client = incoming
	_client.set_no_delay(true)
	_receive_buffer.clear()
	_session_id = "%d-%d" % [Time.get_ticks_usec(), get_instance_id()]
	_last_command_sequence = 0
	_next_action_sequence = 1
	_pending_action_sequences.clear()
	if not _send_message(
		{
			"type": "hello",
			"protocol_version": PROTOCOL_VERSION,
			"session_id": _session_id,
		}
	):
		return
	client_connected.emit(_session_id)


func _process_received_lines() -> void:
	while true:
		var newline_index := _receive_buffer.find(10)
		if newline_index < 0:
			return
		if newline_index > MAX_MESSAGE_BYTES:
			send_protocol_error("message_too_large", "JSON line exceeds the 1 MiB protocol limit.")
			_handle_client_disconnect("CPU bridge message exceeded the size limit.")
			return
		var line_bytes := _receive_buffer.slice(0, newline_index)
		_receive_buffer = _receive_buffer.slice(newline_index + 1)
		if line_bytes.is_empty():
			send_protocol_error("empty_message", "JSON lines must not be empty.")
			continue
		_handle_line(line_bytes.get_string_from_utf8())


func _handle_line(line: String) -> void:
	var parser := JSON.new()
	if parser.parse(line) != OK:
		send_protocol_error("malformed_json", "Message is not valid JSON.")
		return
	var message: Variant = parser.data
	if not message is Dictionary:
		send_protocol_error("invalid_message", "A protocol message must be a JSON object.")
		return
	if not _has_valid_session(message):
		return
	var message_type: Variant = message.get("type")
	if typeof(message_type) != TYPE_STRING:
		send_protocol_error("invalid_message", "Message field 'type' must be a string.")
		return
	match message_type:
		"command":
			_handle_command(message)
		"action":
			_handle_action(message)
		_:
			send_protocol_error("unknown_message_type", "Unsupported message type.")


func _has_valid_session(message: Dictionary) -> bool:
	if typeof(message.get("session_id")) != TYPE_STRING:
		send_protocol_error("invalid_session", "Message must include the active session_id.")
		return false
	if message["session_id"] != _session_id:
		send_protocol_error("invalid_session", "Message session_id does not match this connection.")
		return false
	return true


func _handle_command(message: Dictionary) -> void:
	var sequence: Variant = message.get("sequence")
	if not _is_integer(sequence) or int(sequence) <= _last_command_sequence:
		send_protocol_error(
			"invalid_sequence",
			"Command sequence must be an integer greater than the previous command sequence.",
			int(sequence) if _is_number(sequence) else 0
		)
		return
	var command_sequence := int(sequence)
	var command: Variant = message.get("command")
	if typeof(command) != TYPE_STRING or not ALLOWED_COMMANDS.has(command):
		send_protocol_error(
			"unknown_command", "Command name is missing or unsupported.", command_sequence
		)
		return
	var payload: Variant = message.get("payload", {})
	if not payload is Dictionary:
		send_protocol_error(
			"invalid_payload", "Command payload must be a JSON object.", command_sequence
		)
		return
	var validation_error := _validate_command_payload(command, payload)
	if not validation_error.is_empty():
		send_protocol_error("invalid_payload", validation_error, command_sequence)
		return
	_last_command_sequence = command_sequence
	if command == "reset":
		payload["seed"] = int(payload["seed"])
	if command == "step":
		payload["n"] = int(payload["n"])
	command_received.emit(command, payload, command_sequence)


func _validate_command_payload(command: String, payload: Dictionary) -> String:
	match command:
		"reset":
			if not _is_integer(payload.get("seed")):
				return "reset requires an integer seed."
			if not _is_nonempty_string(payload.get("level")):
				return "reset requires a non-empty level id."
		"step":
			if not _is_integer(payload.get("n")) or int(payload["n"]) <= 0:
				return "step requires a positive integer n."
		"set_speed":
			if not _is_number(payload.get("speed")) or not is_finite(float(payload["speed"])):
				return "set_speed requires a finite numeric speed."
			if float(payload["speed"]) <= 0.0:
				return "set_speed speed must be positive."
		"get_level_geometry":
			if payload.has("level") and not _is_nonempty_string(payload["level"]):
				return "get_level_geometry level must be a non-empty string when provided."
		"load_nav_graph":
			if not payload.get("graph") is Dictionary:
				return "load_nav_graph requires a graph object."
		"close":
			pass
	return ""


func _handle_action(message: Dictionary) -> void:
	var sequence: Variant = message.get("sequence")
	if (
		not _is_integer(sequence)
		or not _pending_action_sequences.has(int(sequence))
	):
		send_protocol_error(
			"invalid_sequence",
			"Action sequence does not match the outstanding observation.",
			int(sequence) if _is_number(sequence) else 0
		)
		return
	var action_sequence := int(sequence)
	var action_data: Variant = message.get("action")
	if not action_data is Dictionary:
		send_protocol_error("invalid_action", "Action must be a JSON object.", action_sequence)
		return
	var validation_error := _validate_action(action_data)
	if not validation_error.is_empty():
		send_protocol_error("invalid_action", validation_error, action_sequence)
		return
	var action := CPUIntent.new()
	action.horizontal = float(action_data["horizontal"])
	action.jump = action_data["jump"]
	action.dash = action_data["dash"]
	action.dash_direction = Vector2(
		float(action_data["dash_direction"]["x"]),
		float(action_data["dash_direction"]["y"])
	)
	action.down = action_data["down"]
	action.grab = action_data["grab"]
	_pending_action_sequences.erase(action_sequence)
	action_received.emit(action, action_sequence)


func _validate_action(action: Dictionary) -> String:
	for key in ["horizontal", "jump", "dash", "dash_direction", "down", "grab"]:
		if not action.has(key):
			return "Action is missing required field '%s'." % key
	if not _is_number(action["horizontal"]) or not is_finite(float(action["horizontal"])):
		return "Action horizontal must be finite numeric input."
	if absf(float(action["horizontal"])) > 1.0:
		return "Action horizontal must be between -1 and 1."
	for key in ["jump", "dash", "down", "grab"]:
		if typeof(action[key]) != TYPE_BOOL:
			return "Action field '%s' must be boolean." % key
	var direction: Variant = action["dash_direction"]
	if not direction is Dictionary or not direction.has("x") or not direction.has("y"):
		return "Action dash_direction must contain numeric x and y."
	if (
		not _is_number(direction["x"])
		or not _is_number(direction["y"])
		or not is_finite(float(direction["x"]))
		or not is_finite(float(direction["y"]))
	):
		return "Action dash_direction values must be finite numbers."
	return ""


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _is_integer(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	return (
		typeof(value) == TYPE_FLOAT
		and is_finite(value)
		and is_equal_approx(float(value), roundf(float(value)))
	)


func _is_nonempty_string(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and not value.strip_edges().is_empty()


func _send_message(message: Dictionary) -> bool:
	if not is_client_connected():
		return false
	var data := (JSON.stringify(message) + "\n").to_utf8_buffer()
	var error := _client.put_data(data)
	if error != OK:
		_handle_client_disconnect("Could not write CPU bridge response: %s" % error_string(error))
		return false
	return true


func _handle_client_disconnect(message: String) -> void:
	push_warning(message)
	_close_client(true)


func _close_client(notify: bool) -> void:
	var had_client := _client != null
	if _client != null:
		_client.disconnect_from_host()
	_client = null
	_receive_buffer.clear()
	_session_id = ""
	_pending_action_sequences.clear()
	if notify and had_client:
		client_disconnected.emit()
