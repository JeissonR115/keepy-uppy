extends SceneTree

var _client_buffer := PackedByteArray()


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _run_test() -> void:
	var port := 20000 + OS.get_process_id() % 30000
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--port="):
			port = int(argument.trim_prefix("--port="))

	var simulation: Node = load("res://src/scenes/simulation/cpu_simulation.tscn").instantiate()
	root.add_child(simulation)
	var client := StreamPeerTCP.new()
	if not _expect(
		client.connect_to_host("127.0.0.1", port) == OK,
		"Simulation control test could not begin connecting."
	):
		return
	var connected := false
	for _frame in range(120):
		client.poll()
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			connected = true
			break
		await process_frame
	if not _expect(connected, "Simulation control test client did not connect."):
		return
	var hello := await _read_message(client)
	if not _expect(hello.get("type") == "hello", "Simulation server omitted its hello."):
		return
	var session_id := str(hello.get("session_id", ""))
	var command_sequence := 1

	_send_command(client, session_id, command_sequence, "reset", {"seed": 42, "level": "classic"})
	var first_reset := await _await_command_result(client, session_id, command_sequence)
	if not _expect(
		first_reset.get("seed") == 42
		and first_reset.get("level") == "classic"
		and first_reset.has("observation"),
		"Reset did not return the reproducible initial observation."
	):
		return
	var first_observation: Dictionary = first_reset["observation"]
	command_sequence += 1

	_send_command(client, session_id, command_sequence, "step", {"n": 3})
	var step_result := await _await_command_result(client, session_id, command_sequence)
	if not _expect(
		step_result.get("steps") == 3 and step_result.get("physics_frames_elapsed") == 3,
		"step(n) did not advance exactly n fixed physics frames."
	):
		return
	var first_step_observation: Dictionary = step_result["observation"].duplicate(true)
	command_sequence += 1

	_send_command(client, session_id, command_sequence, "reset", {"seed": 42, "level": "classic"})
	var repeated_reset := await _await_command_result(client, session_id, command_sequence)
	var repeated_observation: Dictionary = repeated_reset.get("observation", {})
	first_observation.erase("tick")
	repeated_observation.erase("tick")
	if not _expect(
		first_observation == repeated_observation,
		"Reset with the same seed and level produced a different initial state."
	):
		return
	command_sequence += 1

	_send_command(client, session_id, command_sequence, "step", {"n": 3})
	var repeated_step := await _await_command_result(client, session_id, command_sequence)
	var repeated_step_observation: Dictionary = repeated_step.get("observation", {}).duplicate(true)
	first_step_observation.erase("tick")
	repeated_step_observation.erase("tick")
	if not _expect(
		repeated_step.get("physics_frames_elapsed") == 3
		and first_step_observation == repeated_step_observation,
		"Same-seed episodes with the same actions produced different states."
	):
		return
	command_sequence += 1

	_send_command(client, session_id, command_sequence, "set_speed", {"speed": 2.0})
	var speed_result := await _await_command_result(client, session_id, command_sequence)
	if not _expect(
		speed_result.get("physics_ticks_per_second") == 120
		and is_equal_approx(float(speed_result.get("physics_delta", 0.0)), 1.0 / 60.0),
		"Simulation speed changed the fixed physics delta."
	):
		return
	command_sequence += 1

	_send_command(client, session_id, command_sequence, "step", {"n": 4})
	var fast_step := await _await_command_result(client, session_id, command_sequence)
	if not _expect(
		fast_step.get("steps") == 4 and fast_step.get("physics_frames_elapsed") == 4,
		"Accelerated simulation did not preserve the requested physics step count."
	):
		return
	command_sequence += 1

	_send_command(client, session_id, command_sequence, "close", {})
	var close_result := await _await_command_result(client, session_id, command_sequence)
	if not _expect(close_result.get("closed") == true, "Close command was not acknowledged."):
		return

	client.disconnect_from_host()
	simulation.queue_free()
	await process_frame
	print("Episode reset, fixed-step control, speed scaling, repeatability, and close verified.")
	quit()


func _await_command_result(
	client: StreamPeerTCP, session_id: String, sequence: int
) -> Dictionary:
	for _frame in range(1200):
		var message := await _read_message(client)
		if message.get("type") == "observation":
			_send_action(client, session_id, int(message.get("sequence", 0)))
		elif message.get("type") == "command_result" and message.get("sequence") == sequence:
			return message.get("result", {})
		elif message.get("type") == "error":
			push_error("Simulation bridge returned %s: %s" % [message.get("code"), message.get("message")])
			return {}
	push_error("Timed out waiting for simulation command result %d." % sequence)
	return {}


func _send_command(
	client: StreamPeerTCP,
	session_id: String,
	sequence: int,
	command: String,
	payload: Dictionary
) -> void:
	_send_message(
		client,
		{
			"type": "command",
			"session_id": session_id,
			"sequence": sequence,
			"command": command,
			"payload": payload,
		}
	)


func _send_action(client: StreamPeerTCP, session_id: String, sequence: int) -> void:
	_send_message(
		client,
		{
			"type": "action",
			"session_id": session_id,
			"sequence": sequence,
			"action": {
				"horizontal": 0.0,
				"jump": false,
				"dash": false,
				"dash_direction": {"x": 0.0, "y": 0.0},
				"down": false,
				"grab": false,
			},
		}
	)


func _send_message(client: StreamPeerTCP, message: Dictionary) -> void:
	client.put_data((JSON.stringify(message) + "\n").to_utf8_buffer())


func _read_message(client: StreamPeerTCP) -> Dictionary:
	for _frame in range(1200):
		var newline_index := _client_buffer.find(10)
		if newline_index >= 0:
			var line := _client_buffer.slice(0, newline_index).get_string_from_utf8()
			_client_buffer = _client_buffer.slice(newline_index + 1)
			var message: Variant = JSON.parse_string(line)
			return message if message is Dictionary else {}
		client.poll()
		var available_bytes := client.get_available_bytes()
		if available_bytes > 0:
			var read_result: Array = client.get_data(available_bytes)
			if read_result[0] != OK:
				push_error("Simulation control test could not read from server.")
				return {}
			_client_buffer.append_array(read_result[1])
		await process_frame
	push_error("Timed out waiting for a simulation bridge message.")
	return {}
