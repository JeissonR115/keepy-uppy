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
		"Movement probe test client could not begin connecting."
	):
		return
	var connected := false
	for _frame in range(120):
		client.poll()
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			connected = true
			break
		await process_frame
	if not _expect(connected, "Movement probe test client did not connect."):
		return
	var hello := await _read_message(client)
	if not _expect(hello.get("type") == "hello", "Movement probe server omitted its hello."):
		return
	var session_id := str(hello.get("session_id", ""))
	var command_sequence := 1
	_send_command(
		client, session_id, command_sequence, "reset", {"seed": 91, "level": "classic"}
	)
	await _await_command_result(client, session_id, command_sequence)
	command_sequence += 1

	var active_arena := simulation.get_node("Arena")
	var manager := active_arena.get_node("MatchManager") as MatchManager
	var balloon := active_arena.get_node("Balloon") as BalloonController
	var active_player := active_arena.get_node("Player1") as PlayerController
	var original_match_state := manager.match_state
	var original_player_position := active_player.global_position
	var original_balloon_position := balloon.global_position
	var original_balloon_velocity := balloon.linear_velocity
	var original_player_1_score := manager.player_1_score
	var original_player_2_score := manager.player_2_score

	_send_command(
		client,
		session_id,
		command_sequence,
		"probe_movement",
		{
			"movement": "jump",
			"level": "classic",
			"start_position": {"x": 160.0, "y": 152.0},
			"horizontal": 0.0,
		}
	)
	var jump_result := await _await_command_result(client, session_id, command_sequence)
	if not _expect(
		jump_result.get("movement") == "jump"
		and jump_result.get("action_started") == true
		and jump_result.get("landed") == true
		and jump_result.get("physics_frames_elapsed") > 0
		and jump_result.get("landing_position") is Dictionary,
		"Jump probe did not start or return a landing position."
	):
		return
	command_sequence += 1

	_send_command(
		client,
		session_id,
		command_sequence,
		"probe_movement",
		{
			"movement": "dash",
			"level": "classic",
			"start_position": {"x": 80.0, "y": 152.0},
			"direction": {"x": 1.0, "y": -1.0},
		}
	)
	var dash_result := await _await_command_result(client, session_id, command_sequence)
	if not _expect(
		dash_result.get("movement") == "dash"
		and dash_result.get("action_started") == true
		and dash_result.get("landed") == true
		and dash_result.get("landing_position") is Dictionary,
		"Dash probe did not start or return a landing position."
	):
		return
	command_sequence += 1

	if not _expect(
		manager.match_state == original_match_state
		and manager.player_1_score == original_player_1_score
		and manager.player_2_score == original_player_2_score
		and active_player.global_position.is_equal_approx(original_player_position)
		and balloon.global_position.is_equal_approx(original_balloon_position)
		and balloon.linear_velocity.is_equal_approx(original_balloon_velocity),
		"Isolated movement probes changed the active match, player, or balloon."
	):
		return

	_send_command(client, session_id, command_sequence, "close", {})
	await _await_command_result(client, session_id, command_sequence)
	client.disconnect_from_host()
	simulation.queue_free()
	await process_frame
	print("Jump and dash probes land using isolated physics without changing the active match.")
	quit()


func _await_command_result(
	client: StreamPeerTCP, session_id: String, sequence: int
) -> Dictionary:
	for _frame in range(2400):
		var message := await _read_message(client)
		if message.get("type") == "observation":
			_send_action(client, session_id, int(message.get("sequence", 0)))
		elif message.get("type") == "command_result" and message.get("sequence") == sequence:
			return message.get("result", {})
		elif message.get("type") == "error":
			push_error(
				"Movement probe bridge returned %s: %s"
				% [message.get("code"), message.get("message")]
			)
			quit(1)
			return {}
	push_error("Timed out waiting for movement probe command result %d." % sequence)
	quit(1)
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
	for _frame in range(2400):
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
				push_error("Movement probe test could not read from server.")
				quit(1)
				return {}
			_client_buffer.append_array(read_result[1])
		await process_frame
	push_error("Timed out waiting for a movement probe message.")
	quit(1)
	return {}
