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
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	).pressed.emit()
	main_scene.get_node("PlayerCountMenu")._select_level("classic")
	await process_frame
	await physics_frame

	var arena: Node = main_scene.get_node("Arena")
	var player: PlayerController = arena.get_node("Player2")
	var manager: MatchManager = arena.get_node("MatchManager")
	var cpu: CPUController = player.get_node("CPUController")
	player.bot_enabled = true
	manager.match_state = MatchManager.MatchState.ACTIVE
	manager.accepting_gameplay_input = true
	manager.expected_balloon_player = player
	player.set_physics_process(false)

	var server := CPUBridgeServer.new()
	root.add_child(server)
	var port := 30000 + OS.get_process_id() % 20000
	if not _expect(server.start(port) == OK, "Remote brain test server did not start."):
		return
	var client := StreamPeerTCP.new()
	if not _expect(
		client.connect_to_host("127.0.0.1", port) == OK,
		"Remote brain test client could not begin connecting."
	):
		return
	var connected := false
	for _frame in range(60):
		client.poll()
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED and server.is_client_connected():
			connected = true
			break
		await process_frame
	if not _expect(connected, "Remote brain test client did not connect."):
		return
	var hello := await _read_message(client)
	if not _expect(hello.get("type") == "hello", "Remote brain server omitted its hello."):
		return

	cpu.use_remote_brain(server, 0.05)
	var remote := cpu.active_brain as RemoteBrain
	var fallback_reasons: Array[String] = []
	remote.fallback_activated.connect(
		func(reason: String) -> void: fallback_reasons.append(reason)
	)
	cpu.update_decision(1.0 / 60.0)
	var first_observation := await _read_message(client)
	var first_sequence := int(first_observation.get("sequence", 0))
	var observation_data: Dictionary = first_observation.get("observation", {})
	var players: Dictionary = observation_data.get("players", {})
	var player_1_data: Dictionary = players.get("player_1", {})
	var player_2_data: Dictionary = players.get("player_2", {})
	var balloon_data: Dictionary = observation_data.get("balloon", {})
	if not _expect(
		first_observation.get("type") == "observation"
		and player_1_data.has("position")
		and player_1_data.has("wall_contact")
		and player_1_data.has("dash_cooldown")
		and player_1_data.has("stamina")
		and player_2_data.has("velocity")
		and balloon_data.has("waiting_for_first_touch")
		and observation_data.has("current_turn")
		and observation_data.has("score")
		and observation_data.has("level")
		and first_sequence > 0,
		"Remote brain did not receive the required sequenced game observation."
	):
		return
	var session_id := str(hello.get("session_id", ""))

	_send_action(client, session_id, first_sequence, _valid_action())
	for _frame in range(3):
		await process_frame
	cpu.update_decision(1.0 / 60.0)
	if not _expect(
		cpu.intents.horizontal == 0.5
		and cpu.intents.jump
		and cpu.intents.dash
		and cpu.intents.down
		and cpu.intents.grab,
		"Remote CPU intent was not applied to the controller."
	):
		return

	var second_observation := await _read_message(client)
	var stale_sequence := int(second_observation.get("sequence", 0))
	if not _expect(
		second_observation.get("type") == "observation" and stale_sequence > first_sequence,
		"Remote brain did not request its next observation."
	):
		return
	await create_timer(0.08).timeout
	cpu.update_decision(1.0 / 60.0)
	if not _expect(
		not fallback_reasons.is_empty()
		and fallback_reasons.back().contains("timed out")
		and cpu.active_brain == remote
		and remote.local_brain.state != CPUBrain.State.INACTIVE,
		"Timed out remote action did not fall back to LocalBrain."
	):
		return

	var third_observation := await _read_message(client)
	if not _expect(
		third_observation.get("type") == "observation",
		"Remote brain did not resume requesting actions after a timeout."
	):
		return
	_send_action(client, session_id, stale_sequence, _valid_action())
	var stale_error := await _read_message(client)
	if not _expect(
		stale_error.get("type") == "error"
		and stale_error.get("code") == "invalid_sequence",
		"Late action was not discarded after timeout."
	):
		return

	var current_sequence := int(third_observation.get("sequence", 0))
	_send_action(client, session_id, current_sequence, _valid_action())
	for _frame in range(3):
		await process_frame
	cpu.update_decision(1.0 / 60.0)
	client.disconnect_from_host()
	player.set_physics_process(true)
	for _frame in range(5):
		await physics_frame
	if not _expect(
		fallback_reasons.back().contains("disconnected")
		and player.is_physics_processing(),
		"Remote disconnect stopped CPU fallback or player physics."
	):
		return

	server.stop()
	server.queue_free()
	main_scene.queue_free()
	await process_frame
	print("Remote CPU action, timeout, stale-response rejection, and disconnect fallback verified.")
	quit()


func _valid_action() -> Dictionary:
	return {
		"horizontal": 0.5,
		"jump": true,
		"dash": true,
		"dash_direction": {"x": 1.0, "y": -1.0},
		"down": true,
		"grab": true,
	}


func _send_action(
	client: StreamPeerTCP, session_id: String, sequence: int, action: Dictionary
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
				push_error("Remote brain test client could not read from server.")
				return {}
			buffer.append_array(read_result[1])
			var newline_index := buffer.find(10)
			if newline_index >= 0:
				var message: Variant = JSON.parse_string(
					buffer.slice(0, newline_index).get_string_from_utf8()
				)
				return message if message is Dictionary else {}
		await process_frame
	push_error("Timed out while waiting for a remote brain server message.")
	return {}
