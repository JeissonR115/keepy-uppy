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

	_send_command(
		client, session_id, command_sequence, "get_level_geometry", {"level": "sky-towers"}
	)
	var geometry := await _await_command_result(client, session_id, command_sequence)
	if not _expect(
		geometry.get("level") == "sky-towers"
		and geometry.get("bounds", {}).get("size", {}).get("x") == 480.0
		and geometry.get("bounds", {}).get("size", {}).get("y") == 270.0
		and geometry.get("platforms", []).size() > 0
		and geometry.get("movement_constants", {}).get("GRAVITY")
		== PlayerMovementConstants.GRAVITY,
		"Geometry command did not return the requested arena and its movement data."
	):
		return
	command_sequence += 1

	_send_command(
		client,
		session_id,
		command_sequence,
		"load_nav_graph",
		{
			"graph": {
				"schema_version": 1,
				"level": "classic",
				"nodes": [
					{"id": 1, "position": {"x": 248.0, "y": 144.0}},
					{"id": 2, "position": {"x": 232.0, "y": 144.0}},
					{"id": 3, "position": {"x": 200.0, "y": 110.0}},
					{"id": 4, "position": {"x": 160.0, "y": 110.0}},
					{"id": 5, "position": {"x": 120.0, "y": 148.0}},
					{"id": 6, "position": {"x": 80.0, "y": 110.0}},
				],
				"edges": [
					{"from": 1, "to": 2, "action": "WALK", "cost": 1.0, "bidirectional": true},
					{"from": 2, "to": 3, "action": "JUMP", "cost": 1.2},
					{"from": 3, "to": 4, "action": "DASH", "cost": 0.9},
					{"from": 4, "to": 5, "action": "DROP", "cost": 1.1},
					{"from": 5, "to": 6, "action": "WALL_JUMP", "cost": 1.8},
					{"from": 1, "to": 6, "action": "WALK", "cost": 20.0},
				],
			}
		}
	)
	var graph_result := await _await_command_result(client, session_id, command_sequence)
	if not _expect(
		graph_result.get("loaded") == true
		and graph_result.get("level") == "classic"
		and graph_result.get("node_count") == 6
		and graph_result.get("edge_count") == 7,
		"load_nav_graph did not return the validated graph summary."
	):
		return
	command_sequence += 1

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
	_send_command(
		client,
		session_id,
		command_sequence,
		"set_nav_route",
		{"level": "classic", "start_node": 1, "destination_node": 6}
	)
	var route_result := await _await_command_result(client, session_id, command_sequence)
	var overlay := simulation.get_node_or_null("Arena/NavGraphOverlay") as Node2D
	var returned_route: Array = route_result.get("route_node_ids", [])
	var overlay_route: PackedInt64Array = overlay.get("route") if overlay != null else PackedInt64Array()
	var expected_route := PackedInt64Array([1, 2, 3, 4, 5, 6])
	var returned_route_matches := returned_route.size() == expected_route.size()
	if returned_route_matches:
		for route_index in range(expected_route.size()):
			if int(returned_route[route_index]) != expected_route[route_index]:
				returned_route_matches = false
				break
	if not _expect(
		returned_route_matches
		and overlay != null
		and overlay.visible
		and overlay_route == expected_route,
		"set_nav_route did not activate the requested route and debug overlay."
	):
		return
	command_sequence += 1

	_send_command(client, session_id, command_sequence, "step", {"n": 10})
	var step_result := await _await_command_result(client, session_id, command_sequence)
	if not _expect(
		step_result.get("steps") == 10
		and step_result.get("physics_frames_elapsed") == 10
		and float(step_result.get("observation", {}).get("players", {}).get("player_2", {}).get("position", {}).get("x", 248.0)) < 248.0,
		"CPU route did not move toward its next node during fixed physics steps."
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

	_send_command(
		client,
		session_id,
		command_sequence,
		"set_nav_route",
		{"level": "classic", "start_node": 1, "destination_node": 6}
	)
	var repeated_route := await _await_command_result(client, session_id, command_sequence)
	var repeated_route_ids: Array = repeated_route.get("route_node_ids", [])
	var repeated_route_matches := repeated_route_ids.size() == expected_route.size()
	if repeated_route_matches:
		for route_index in range(expected_route.size()):
			if int(repeated_route_ids[route_index]) != expected_route[route_index]:
				repeated_route_matches = false
				break
	if not _expect(
		repeated_route_matches,
		"Same-seed reset could not restore the same navigation route."
	):
		return
	command_sequence += 1

	_send_command(client, session_id, command_sequence, "step", {"n": 10})
	var repeated_step := await _await_command_result(client, session_id, command_sequence)
	var repeated_step_observation: Dictionary = repeated_step.get("observation", {}).duplicate(true)
	first_step_observation.erase("tick")
	repeated_step_observation.erase("tick")
	if not _expect(
		repeated_step.get("physics_frames_elapsed") == 10
		and first_step_observation == repeated_step_observation,
		"Same-seed episodes with the same route produced different states."
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

	_send_command(client, session_id, command_sequence, "reset", {"seed": 42, "level": "sky-towers"})
	var sky_reset := await _await_command_result(client, session_id, command_sequence)
	if not _expect(
		sky_reset.get("level") == "sky-towers"
		and overlay != null
		and not overlay.visible
		and overlay.get("graph") == null,
		"Switching arenas left the previous level's navigation graph visible."
	):
		return
	command_sequence += 1

	_send_command(
		client,
		session_id,
		command_sequence,
		"load_nav_graph",
		{
			"graph": {
				"schema_version": 1,
				"level": "sky-towers",
				"nodes": [
					{"id": 10, "position": {"x": 80.0, "y": 120.0}},
					{"id": 11, "position": {"x": 120.0, "y": 120.0}},
				],
				"edges": [
					{"from": 10, "to": 11, "action": "WALK", "cost": 1.0},
				],
			}
		}
	)
	var sky_graph_result := await _await_command_result(client, session_id, command_sequence)
	var sky_overlay_graph: NavGraph = overlay.get("graph") if overlay != null else null
	if not _expect(
		sky_graph_result.get("level") == "sky-towers"
		and overlay != null
		and overlay.visible
		and sky_overlay_graph != null
		and sky_overlay_graph.level_id == "sky-towers",
		"Loading the sky-towers graph did not update the active overlay."
	):
		return
	command_sequence += 1

	_send_command(client, session_id, command_sequence, "reset", {"seed": 42, "level": "classic"})
	var classic_reset := await _await_command_result(client, session_id, command_sequence)
	var classic_overlay_graph: NavGraph = overlay.get("graph") if overlay != null else null
	if not _expect(
		classic_reset.get("level") == "classic"
		and overlay != null
		and overlay.visible
		and classic_overlay_graph != null
		and classic_overlay_graph.level_id == "classic",
		"Returning to classic did not restore its level-specific navigation graph."
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
