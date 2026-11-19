extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _run_test() -> void:
	var server := CPUBridgeServer.new()
	root.add_child(server)
	var port := 20000 + OS.get_process_id() % 30000
	if not _expect(server.start(port) == OK, "CPU bridge server did not start on loopback."):
		return

	var client := StreamPeerTCP.new()
	if not _expect(
		client.connect_to_host("127.0.0.1", port) == OK,
		"Test client could not begin a loopback connection."
	):
		return
	var connected := false
	for _frame in range(60):
		client.poll()
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED and server.is_client_connected():
			connected = true
			break
		await process_frame
	if not _expect(connected, "Test client did not connect to the CPU bridge server."):
		return

	var hello := await _read_message(client)
	if not _expect(
		hello.get("type") == "hello" and hello.get("protocol_version") == 1,
		"Server did not send a versioned hello message."
	):
		return
	var session_id: String = hello.get("session_id", "")
	if not _expect(not session_id.is_empty(), "Server hello did not include a session id."):
		return

	var received_commands: Array[Dictionary] = []
	var received_actions: Array[Dictionary] = []
	server.command_received.connect(
		func(command: String, payload: Dictionary, sequence: int) -> void:
			received_commands.append(
				{"command": command, "payload": payload, "sequence": sequence}
			)
	)
	server.action_received.connect(
		func(action: CPUIntent, sequence: int) -> void:
			received_actions.append({"action": action, "sequence": sequence})
	)

	_send_command(client, "wrong-session", 1, "step", {"n": 2})
	var invalid_session_error := await _read_message(client)
	if not _expect(
			invalid_session_error.get("code") == "invalid_session"
			and received_commands.is_empty(),
			"Message with a different session id was not rejected."
	):
			return

	client.put_data("{bad json}\n".to_utf8_buffer())
	var malformed_error := await _read_message(client)
	if not _expect(
		malformed_error.get("type") == "error"
		and malformed_error.get("code") == "malformed_json",
		"Malformed JSON did not receive an explicit protocol error."
	):
		return

	_send_command(client, session_id, 1, "step", {"n": 0})
	var invalid_payload_error := await _read_message(client)
	if not _expect(
		invalid_payload_error.get("code") == "invalid_payload",
		"Invalid command payload did not receive an explicit error."
	):
		return

	_send_command(client, session_id, 1, "step", {"n": 2})
	for _frame in range(3):
		await process_frame
	if not _expect(
		received_commands.size() == 1
		and received_commands[0]["command"] == "step"
		and received_commands[0]["payload"]["n"] == 2,
		"Valid command was not delivered to the simulation."
	):
		return
	server.send_command_result(1, {"accepted": true})
	var command_result := await _read_message(client)
	if not _expect(
		command_result.get("type") == "command_result"
		and command_result.get("sequence") == 1
		and command_result.get("ok") == true,
		"Command result was not sent with its sequence."
	):
		return

	var action_sequence := server.request_action({"tick": 10})
	var observation := await _read_message(client)
	if not _expect(
		action_sequence == 1
		and observation.get("type") == "observation"
		and observation.get("sequence") == action_sequence,
		"Action request did not send a sequenced observation."
	):
		return

	_send_action(client, session_id, action_sequence - 1, _valid_action())
	var stale_error := await _read_message(client)
	if not _expect(
		stale_error.get("code") == "invalid_sequence" and received_actions.is_empty(),
		"Stale action sequence was not rejected."
	):
		return

	var invalid_action := _valid_action()
	invalid_action.erase("grab")
	_send_action(client, session_id, action_sequence, invalid_action)
	var invalid_action_error := await _read_message(client)
	if not _expect(
		invalid_action_error.get("code") == "invalid_action" and received_actions.is_empty(),
		"Action with missing fields was not rejected atomically."
	):
		return

	_send_action(client, session_id, action_sequence, _valid_action())
	for _frame in range(3):
		await process_frame
	if not _expect(
		received_actions.size() == 1
		and received_actions[0]["sequence"] == action_sequence
		and received_actions[0]["action"].down,
		"Valid action was not parsed and emitted."
	):
		return

	_send_command(client, session_id, 1, "close", {})
	var duplicate_sequence_error := await _read_message(client)
	if not _expect(
		duplicate_sequence_error.get("code") == "invalid_sequence",
		"Duplicate command sequence was not rejected."
	):
		return

	server.stop()
	client.disconnect_from_host()
	server.queue_free()
	await process_frame
	print("CPU bridge loopback framing, validation, sessions, and sequence checks verified.")
	quit()


func _valid_action() -> Dictionary:
	return {
		"horizontal": 1.0,
		"jump": false,
		"dash": true,
		"dash_direction": {"x": 1.0, "y": -1.0},
		"down": true,
		"grab": false,
	}


func _send_command(
	client: StreamPeerTCP,
	session_id: String,
	sequence: int,
	command: String,
	payload: Dictionary
) -> void:
	client.put_data(
		(
			JSON.stringify(
				{
					"type": "command",
					"session_id": session_id,
					"sequence": sequence,
					"command": command,
					"payload": payload,
				}
			)
			+ "\n"
		).to_utf8_buffer()
	)


func _send_action(
	client: StreamPeerTCP,
	session_id: String,
	sequence: int,
	action: Dictionary
) -> void:
	client.put_data(
		(
			JSON.stringify(
				{
					"type": "action",
					"session_id": session_id,
					"sequence": sequence,
					"action": action,
				}
			)
			+ "\n"
		).to_utf8_buffer()
	)


func _read_message(client: StreamPeerTCP) -> Dictionary:
	var buffer := PackedByteArray()
	for _frame in range(120):
		client.poll()
		var available_bytes := client.get_available_bytes()
		if available_bytes > 0:
			var read_result: Array = client.get_data(available_bytes)
			if read_result[0] != OK:
				push_error("Test client could not read from CPU bridge.")
				return {}
			buffer.append_array(read_result[1])
			var newline_index := buffer.find(10)
			if newline_index >= 0:
				var line := buffer.slice(0, newline_index).get_string_from_utf8()
				var message: Variant = JSON.parse_string(line)
				return message if message is Dictionary else {}
		await process_frame
	push_error("Timed out while waiting for CPU bridge response.")
	return {}
