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
		"Episode event test client could not begin connecting."
	):
		return
	var connected := false
	for _frame in range(120):
		client.poll()
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			connected = true
			break
		await process_frame
	if not _expect(connected, "Episode event test client did not connect."):
		return
	var hello := await _read_message(client)
	if not _expect(hello.get("type") == "hello", "Episode event server omitted its hello."):
		return
	var session_id := str(hello.get("session_id", ""))
	var command_sequence := 1
	_send_command(client, session_id, command_sequence, "reset", {"seed": 12, "level": "classic"})
	await _await_command_result(client, command_sequence)
	command_sequence += 1

	var manager := simulation.get_node("Arena/MatchManager") as MatchManager
	manager.round_intermission = 10.0
	_send_command(client, session_id, command_sequence, "step", {"n": 10})
	await _await_observation(client, session_id)
	manager.match_state = MatchManager.MatchState.ROUND_OVER
	manager.round_end_reason = "ball_grounded"
	manager.round_has_valid_contact = true
	manager.last_valid_toucher = manager.player_1
	manager.round_faulting_player = null
	manager._finish_round()
	var point_event := await _read_episode_event(client)
	var point_step_result := await _await_command_result(client, command_sequence)
	if not _expect(
		point_event.get("type") == "point"
		and point_event.get("reason") == "ball_grounded"
		and point_event.get("winner") == "player_1"
		and point_event.get("score", {}).get("points", {}).get("player_1") == 1,
		"Point event omitted its reason, winner, or score."
	):
		return
	var step_events: Array = point_step_result.get("events", [])
	if not _expect(
		point_step_result.get("episode_ended") == true
		and point_step_result.get("steps") < 10
		and step_events.size() == 1
		and step_events[0].get("type") == "point",
		"step(n) did not stop at and return its terminal point event."
	):
		return
	command_sequence += 1

	command_sequence = await _reset(client, session_id, command_sequence)
	manager.match_state = MatchManager.MatchState.ROUND_OVER
	manager.round_end_reason = "out_of_turn_contact"
	manager.round_faulting_player = manager.player_2
	manager.round_has_valid_contact = false
	manager._finish_round()
	var fault_event := await _read_episode_event(client)
	var fault_point_event := await _read_episode_event(client)
	if not _expect(
		fault_event.get("type") == "fault"
		and fault_event.get("reason") == "out_of_turn_contact"
		and fault_event.get("player") == "player_2"
		and fault_event.get("winner") == "player_1"
		and fault_point_event.get("type") == "point",
		"Fault event did not identify the offending player and point winner."
	):
		return

	command_sequence = await _reset(client, session_id, command_sequence)
	manager.match_state = MatchManager.MatchState.ACTIVE
	manager.player_2_score = 2
	manager.consecutive_downward_fault_player = manager.player_2
	manager.consecutive_downward_fault_count = 1
	manager._resolve_downward_hit_fault(manager.player_2)
	var replay_event := await _read_episode_event(client)
	if not _expect(
		replay_event.get("type") == "downward_fault_replay"
		and replay_event.get("reason") == "downward_hit"
		and replay_event.get("player") == "player_2"
		and replay_event.get("winner") == "player_1"
		and replay_event.get("point_deducted") == true
		and replay_event.get("score", {}).get("points", {}).get("player_2") == 1,
		"Downward-hit replay event omitted its penalty or resulting score."
	):
		return

	command_sequence = await _reset(client, session_id, command_sequence)
	manager.target_score = 1
	manager.sets_to_win = 3
	manager.player_1_score = 0
	manager.player_2_score = 0
	manager.round_server = manager.player_2
	manager.round_has_valid_contact = false
	manager.round_faulting_player = null
	manager.round_end_reason = "ground_before_valid_contact"
	manager.match_state = MatchManager.MatchState.ROUND_OVER
	manager._finish_round()
	var set_point_event := await _read_episode_event(client)
	var set_event := await _read_episode_event(client)
	if not _expect(
		set_point_event.get("type") == "point"
		and set_event.get("type") == "set"
		and set_event.get("reason") == "score_target_reached"
		and set_event.get("winner") == "player_1"
		and set_event.get("score", {}).get("sets", {}).get("player_1") == 1,
		"Set event did not follow its point with the updated set score."
	):
		return

	command_sequence = await _reset(client, session_id, command_sequence)
	manager.target_score = 1
	manager.sets_to_win = 1
	manager.player_1_score = 0
	manager.player_2_score = 0
	manager.player_1_sets = 0
	manager.player_2_sets = 0
	manager.round_server = manager.player_2
	manager.round_has_valid_contact = false
	manager.round_faulting_player = null
	manager.round_end_reason = "ground_before_valid_contact"
	manager.match_state = MatchManager.MatchState.ROUND_OVER
	manager._finish_round()
	var match_point_event := await _read_episode_event(client)
	var match_set_event := await _read_episode_event(client)
	var match_event := await _read_episode_event(client)
	if not _expect(
		match_point_event.get("type") == "point"
		and match_set_event.get("type") == "set"
		and match_event.get("type") == "match"
		and match_event.get("reason") == "sets_target_reached"
		and match_event.get("winner") == "player_1",
		"Match event did not report the completed set and winner."
	):
		return

	_send_command(client, session_id, command_sequence, "close", {})
	await _await_command_result(client, command_sequence)
	client.disconnect_from_host()
	simulation.queue_free()
	await process_frame
	print("Point, fault, downward replay, set, and match events verified.")
	quit()


func _reset(client: StreamPeerTCP, session_id: String, sequence: int) -> int:
	_send_command(client, session_id, sequence, "reset", {"seed": 12, "level": "classic"})
	await _await_command_result(client, sequence)
	return sequence + 1


func _await_command_result(client: StreamPeerTCP, sequence: int) -> Dictionary:
	for _frame in range(1200):
		var message := await _read_message(client)
		if message.get("type") == "command_result" and message.get("sequence") == sequence:
			return message.get("result", {})
		if message.get("type") == "error":
			push_error("Bridge returned error %s: %s" % [message.get("code"), message.get("message")])
			quit(1)
			return {}
	push_error("Timed out waiting for command result %d." % sequence)
	quit(1)
	return {}


func _read_episode_event(client: StreamPeerTCP) -> Dictionary:
	for _frame in range(1200):
		var message := await _read_message(client)
		if message.get("type") == "episode_event":
			return message.get("event", {})
	push_error("Timed out waiting for an episode event.")
	quit(1)
	return {}


func _await_observation(client: StreamPeerTCP, session_id: String) -> void:
	for _frame in range(1200):
		var message := await _read_message(client)
		if message.get("type") == "observation":
			client.put_data(
				(
					JSON.stringify(
						{
							"type": "action",
							"session_id": session_id,
							"sequence": int(message.get("sequence", 0)),
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
					+ "\n"
				).to_utf8_buffer()
			)
			return
		if message.get("type") == "error":
			push_error("Bridge returned error %s: %s" % [message.get("code"), message.get("message")])
			quit(1)
			return
	push_error("Timed out waiting for a step observation.")
	quit(1)


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
				push_error("Episode event test could not read from server.")
				quit(1)
				return {}
			_client_buffer.append_array(read_result[1])
		await process_frame
	push_error("Timed out waiting for an episode event message.")
	quit(1)
	return {}
