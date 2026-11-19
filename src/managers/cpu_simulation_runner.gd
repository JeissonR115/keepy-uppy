extends Node

const DEFAULT_OPTIONS := {
	"port": 8765,
	"level": "classic",
	"speed": 1.0,
	"seed": 1,
	"mode": "cpu-vs-cpu",
}
const VALID_MODES := ["cpu-vs-cpu", "cpu-vs-scripted"]
const MAX_PHYSICS_TICKS_PER_SECOND := 1200

@onready var arena: Node = get_node("Arena")

var _bridge_server: CPUBridgeServer
var _previous_time_scale: float = 1.0
var _previous_physics_ticks_per_second: int = 60
var _base_time_scale: float = 1.0
var _base_physics_ticks_per_second: int = 60
var _episode_rng := RandomNumberGenerator.new()
var _match_manager: MatchManager
var _simulation_players: Array[PlayerController] = []
var _remote_player: PlayerController
var _pause_after_setup: bool = false
var _pending_reset_sequence: int = 0
var _pending_reset_seed: int = 0
var _pending_reset_level: String = ""
var _pending_step_sequence: int = 0
var _requested_step_count: int = 0
var _steps_remaining: int = 0
var _step_start_frame: int = 0
var _step_terminal_requested: bool = false
var _step_events: Array[Dictionary] = []


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var scoreboard := get_node_or_null("Arena/Scoreboard")
	if scoreboard != null:
		scoreboard.free()
	var simulation_arena := get_node_or_null("Arena")
	if simulation_arena != null:
		simulation_arena.process_mode = Node.PROCESS_MODE_PAUSABLE


func _ready() -> void:
	_previous_time_scale = Engine.time_scale
	_previous_physics_ticks_per_second = Engine.physics_ticks_per_second
	_base_time_scale = Engine.time_scale
	_base_physics_ticks_per_second = Engine.physics_ticks_per_second
	set_physics_process_priority(1000)
	var options := _parse_options(OS.get_cmdline_user_args())
	if options.is_empty():
		get_tree().quit(2)
		return
	_configure_simulation(options)


func _exit_tree() -> void:
	if _bridge_server != null:
		_bridge_server.stop()
	Engine.time_scale = _previous_time_scale
	Engine.physics_ticks_per_second = _previous_physics_ticks_per_second


func _on_round_started(_round_number: int, _server: CharacterBody2D) -> void:
	if _pending_reset_sequence != 0 and _match_manager.match_state == MatchManager.MatchState.ACTIVE:
		_set_player_physics_enabled(true)
		get_tree().paused = true
		var sequence := _pending_reset_sequence
		_pending_reset_sequence = 0
		_bridge_server.send_command_result(
			sequence,
			{
				"seed": _pending_reset_seed,
				"level": _pending_reset_level,
				"observation": CPUObservationBuilder.build_for(_remote_player),
			}
		)
	elif _pause_after_setup and _match_manager.match_state == MatchManager.MatchState.ACTIVE:
		_set_player_physics_enabled(true)
		_pause_after_setup = false
		get_tree().paused = true


func _physics_process(_delta: float) -> void:
	if _steps_remaining <= 0 or _pending_step_sequence == 0:
		return
	_steps_remaining -= 1
	if (
		_steps_remaining > 0
		and _match_manager.match_state != MatchManager.MatchState.COMPLETE
	):
		return
	_finish_step()


func _on_round_ended(
	point_winner: CharacterBody2D, player_1_score: int, player_2_score: int
) -> void:
	var faulting_player := _match_manager.round_faulting_player
	if is_instance_valid(faulting_player):
		_publish_episode_event(
			{
				"type": "fault",
				"reason": _match_manager.round_end_reason,
				"player": _player_id(faulting_player),
				"winner": _player_id(point_winner),
				"score": _score_snapshot(player_1_score, player_2_score),
			}
		)
	_publish_episode_event(
		{
			"type": "point",
			"reason": _match_manager.round_end_reason,
			"player": _player_id(faulting_player) if is_instance_valid(faulting_player) else "",
			"winner": _player_id(point_winner),
			"score": _score_snapshot(player_1_score, player_2_score),
		}
	)
	if _pending_step_sequence != 0:
		_step_terminal_requested = true
		call_deferred("_finish_step_after_terminal")


func _on_downward_fault_replayed(
	faulting_player: CharacterBody2D, point_deducted: bool
) -> void:
	_publish_episode_event(
		{
			"type": "downward_fault_replay",
			"reason": _match_manager.round_end_reason,
			"player": _player_id(faulting_player),
			"winner": _player_id(_match_manager.next_server) if point_deducted else "",
			"point_deducted": point_deducted,
			"score": _score_snapshot(
				_match_manager.player_1_score, _match_manager.player_2_score
			),
		}
	)


func _on_set_ended(
	set_winner: CharacterBody2D, player_1_sets: int, player_2_sets: int
) -> void:
	_publish_episode_event(
		{
			"type": "set",
			"reason": "score_target_reached",
			"player": _player_id(set_winner),
			"winner": _player_id(set_winner),
			"score": {
				"points": {
					"player_1": _match_manager.player_1_score,
					"player_2": _match_manager.player_2_score,
				},
				"sets": {
					"player_1": player_1_sets,
					"player_2": player_2_sets,
				},
			},
		}
	)


func _on_match_ended(winner: CharacterBody2D) -> void:
	_publish_episode_event(
		{
			"type": "match",
			"reason": "sets_target_reached",
			"player": _player_id(winner),
			"winner": _player_id(winner),
			"score": _score_snapshot(
				_match_manager.player_1_score, _match_manager.player_2_score
			),
		}
	)


func _finish_step_after_terminal() -> void:
	if _pending_step_sequence != 0 and _step_terminal_requested:
		_finish_step()


func _finish_step() -> void:
	if _pending_step_sequence == 0:
		return
	get_tree().paused = true
	var completed_steps := _requested_step_count - _steps_remaining
	var elapsed_frames := Engine.get_physics_frames() - _step_start_frame
	var terminal := (
		_step_terminal_requested
		or _match_manager.match_state == MatchManager.MatchState.COMPLETE
	)
	var sequence := _pending_step_sequence
	var events := _step_events.duplicate(true)
	_pending_step_sequence = 0
	_requested_step_count = 0
	_steps_remaining = 0
	_step_terminal_requested = false
	_step_events.clear()
	_bridge_server.send_command_result(
		sequence,
		{
			"steps": completed_steps,
			"physics_frames_elapsed": elapsed_frames,
			"complete": _match_manager.match_state == MatchManager.MatchState.COMPLETE,
			"episode_ended": terminal,
			"events": events,
			"observation": CPUObservationBuilder.build_for(_remote_player),
		}
	)


func _publish_episode_event(event: Dictionary) -> void:
	if _pending_step_sequence != 0:
		_step_events.append(event.duplicate(true))
	if _bridge_server != null:
		_bridge_server.send_episode_event(event)


func _score_snapshot(player_1_score: int, player_2_score: int) -> Dictionary:
	return {
		"points": {
			"player_1": player_1_score,
			"player_2": player_2_score,
		},
		"sets": {
			"player_1": _match_manager.player_1_sets,
			"player_2": _match_manager.player_2_sets,
		},
	}


func _player_id(player: CharacterBody2D) -> String:
	if not is_instance_valid(player):
		return ""
	var controller := player as PlayerController
	return controller.input_prefix if controller != null else str(player.name)


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var options := DEFAULT_OPTIONS.duplicate()
	var index := 0
	while index < arguments.size():
		var argument := arguments[index]
		if not argument.begins_with("--"):
			_report_invalid_argument("Unexpected argument '%s'." % argument)
			return {}
		var option := argument.trim_prefix("--")
		var separator_index := option.find("=")
		var key: String
		var value: String
		if separator_index >= 0:
			key = option.substr(0, separator_index)
			value = option.substr(separator_index + 1)
		else:
			key = option
			index += 1
			if index >= arguments.size():
				_report_invalid_argument("Option '--%s' requires a value." % key)
				return {}
			value = arguments[index]
		if value.is_empty():
			_report_invalid_argument("Option '--%s' requires a non-empty value." % key)
			return {}
		match key:
			"port", "seed":
				if not value.is_valid_int():
					_report_invalid_argument("Option '--%s' must be an integer." % key)
					return {}
				options[key] = int(value)
			"level", "mode":
				options[key] = value
			"speed":
				if not value.is_valid_float() or not is_finite(float(value)):
					_report_invalid_argument("Option '--speed' must be a finite number.")
					return {}
				options[key] = float(value)
			_:
				_report_invalid_argument("Unknown option '--%s'." % key)
				return {}
		index += 1

	if options["port"] < 1 or options["port"] > 65535:
		_report_invalid_argument("Port must be between 1 and 65535.")
		return {}
	if options["speed"] <= 0.0:
		_report_invalid_argument("Speed must be positive.")
		return {}
	if options["level"].strip_edges().is_empty():
		_report_invalid_argument("Level id must not be empty.")
		return {}
	if not VALID_MODES.has(options["mode"]):
		_report_invalid_argument(
			"Mode must be one of: %s." % ", ".join(VALID_MODES)
		)
		return {}
	return options


func _configure_simulation(options: Dictionary) -> void:
	var level_manager := arena.get_node("LevelManager") as LevelManager
	if not level_manager.select_arena(options["level"]):
		_report_invalid_argument("Unknown or unavailable level '%s'." % options["level"])
		return

	var player_1 := arena.get_node("Player1") as PlayerController
	var player_2 := arena.get_node("Player2") as PlayerController
	_simulation_players = [player_1, player_2]
	_match_manager = arena.get_node("MatchManager") as MatchManager
	_remote_player = player_2
	_match_manager.round_started.connect(_on_round_started)
	_match_manager.round_ended.connect(_on_round_ended)
	_match_manager.downward_fault_replayed.connect(_on_downward_fault_replayed)
	_match_manager.set_ended.connect(_on_set_ended)
	_match_manager.match_ended.connect(_on_match_ended)
	player_1.bot_enabled = true
	player_2.bot_enabled = true
	_match_manager.match_seed_override = options["seed"]
	_episode_rng.seed = options["seed"]
	_match_manager.coin_toss_override = _episode_rng.randi_range(0, 1)
	var speed_result := _apply_speed(options["speed"])
	if speed_result.is_empty():
		_report_invalid_argument(
			"Speed exceeds the supported physics tick range (maximum %d)." %
			MAX_PHYSICS_TICKS_PER_SECOND
		)
		return

	_bridge_server = CPUBridgeServer.new()
	_bridge_server.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_bridge_server)
	_bridge_server.command_received.connect(_on_command_received)
	var server_error := _bridge_server.start(options["port"])
	if server_error != OK:
		get_tree().quit(2)
		return

	var cpu_2 := player_2.get_node("CPUController") as CPUController
	if options["mode"] == "cpu-vs-scripted":
		cpu_2.set_brain(ScriptedPlayerBrain.new(player_2))
	else:
		cpu_2.use_remote_brain(_bridge_server)

	_pause_after_setup = true
	_set_player_physics_enabled(false)
	_match_manager.restart_match()
	_normalize_player_physics_state()
	options["speed"] = speed_result["speed"]
	print("CPU simulation ready: {mode} level={level} seed={seed} port={port} speed={speed}".format(options))


func _on_command_received(command: String, payload: Dictionary, sequence: int) -> void:
	match command:
		"reset":
			_reset_episode(int(payload["seed"]), payload["level"], sequence)
		"step":
			_begin_step(int(payload["n"]), sequence)
		"set_speed":
			var speed_result := _apply_speed(float(payload["speed"]))
			if speed_result.is_empty():
				_bridge_server.send_protocol_error(
					"invalid_payload",
					"Requested speed exceeds the supported physics tick range.",
					sequence
				)
			else:
				_bridge_server.send_command_result(sequence, speed_result)
		"close":
			_bridge_server.send_command_result(sequence, {"closed": true})
			call_deferred("_stop_bridge_after_ack")
		_:
			_bridge_server.send_protocol_error(
				"unsupported_command",
				"Command '%s' is not available in this simulation build." % command,
				sequence
			)


func _reset_episode(seed_value: int, level_id: String, sequence: int) -> void:
	if _pending_reset_sequence != 0 or _pending_step_sequence != 0:
		_bridge_server.send_protocol_error(
			"simulation_busy", "Cannot reset while another simulation operation is active.", sequence
		)
		return
	var level_manager := arena.get_node("LevelManager") as LevelManager
	if not level_manager.select_arena(level_id):
		_bridge_server.send_protocol_error(
			"invalid_level", "Unknown or unavailable level '%s'." % level_id, sequence
		)
		return
	_episode_rng.seed = seed_value
	_match_manager.match_seed_override = seed_value
	_match_manager.coin_toss_override = _episode_rng.randi_range(0, 1)
	_pending_reset_sequence = sequence
	_pending_reset_seed = seed_value
	_pending_reset_level = level_id
	_step_events.clear()
	_step_terminal_requested = false
	_pause_after_setup = false
	get_tree().paused = false
	_set_player_physics_enabled(false)
	_match_manager.restart_match()
	_normalize_player_physics_state()


func _begin_step(step_count: int, sequence: int) -> void:
	if _pending_reset_sequence != 0 or _pending_step_sequence != 0:
		_bridge_server.send_protocol_error(
			"simulation_busy", "Another simulation operation is still active.", sequence
		)
		return
	if _match_manager.match_state == MatchManager.MatchState.COMPLETE:
		_bridge_server.send_command_result(
			sequence,
			{
				"steps": 0,
				"complete": true,
				"episode_ended": true,
				"events": [],
				"observation": CPUObservationBuilder.build_for(_remote_player),
			}
		)
		return
	_pending_step_sequence = sequence
	_requested_step_count = step_count
	_steps_remaining = step_count
	_step_start_frame = Engine.get_physics_frames()
	_step_events.clear()
	_step_terminal_requested = false
	get_tree().paused = false


func _apply_speed(speed: float) -> Dictionary:
	var target_ticks := roundi(float(_base_physics_ticks_per_second) * speed)
	if (
		not is_finite(speed)
		or speed <= 0.0
		or target_ticks < 1
		or target_ticks > MAX_PHYSICS_TICKS_PER_SECOND
	):
		return {}
	Engine.physics_ticks_per_second = target_ticks
	Engine.time_scale = (
		_base_time_scale
		* float(target_ticks)
		/ float(_base_physics_ticks_per_second)
	)
	return {
		"speed": float(target_ticks) / float(_base_physics_ticks_per_second),
		"physics_ticks_per_second": target_ticks,
		"physics_delta": Engine.time_scale / float(target_ticks),
	}


func _stop_bridge() -> void:
	_bridge_server.stop()


func _stop_bridge_after_ack() -> void:
	await get_tree().process_frame
	_stop_bridge()


func _set_player_physics_enabled(enabled: bool) -> void:
	for player: PlayerController in _simulation_players:
		player.set_physics_process(enabled)


func _normalize_player_physics_state() -> void:
	for player: PlayerController in _simulation_players:
		var spawn_position := player.global_position
		player.velocity = Vector2.UP
		player.move_and_slide()
		player.global_position = spawn_position
		player.velocity = Vector2.ZERO


func _report_invalid_argument(message: String) -> void:
	push_error("CPU simulation configuration error: %s" % message)
	get_tree().quit(2)
