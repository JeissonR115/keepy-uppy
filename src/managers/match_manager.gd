class_name MatchManager
extends Node

signal priority_changed(player: CharacterBody2D)
signal opening_server_selected(player: CharacterBody2D)
signal score_changed(player_1_score: int, player_2_score: int)
signal set_score_changed(player_1_sets: int, player_2_sets: int)
signal round_ended(point_winner: CharacterBody2D, player_1_score: int, player_2_score: int)
signal set_ended(set_winner: CharacterBody2D, player_1_sets: int, player_2_sets: int)
signal set_won(
	set_winner: CharacterBody2D,
	player_1_set_score: int,
	player_2_set_score: int,
	player_1_sets: int,
	player_2_sets: int
)
signal round_started(round_number: int, server: CharacterBody2D)
signal match_ended(winner: CharacterBody2D)
signal coin_toss_completed(result: String, first_server: CharacterBody2D)
signal balloon_turn_changed(player: CharacterBody2D)
signal downward_fault_replayed(player: CharacterBody2D, point_deducted: bool)

@export var normal_push_strength: float = 30.0
@export var priority_push_strength: float = 90.0
@export var non_priority_dash_push_strength: float = 60.0
@export var priority_dash_push_strength: float = 180.0
@export var max_push_speed: float = 320.0
@export_range(1, 99) var target_score: int = 5
@export_range(1, 99) var sets_to_win: int = 3
@export_range(-1, 1, 1) var coin_toss_override: int = -1
@export_range(-1, 2147483647, 1) var match_seed_override: int = -1
@export_range(0.0, 10.0, 0.1) var round_intermission: float = 1.5
@export var player_1_spawn_position: Vector2 = Vector2(72, 144)
@export var player_2_spawn_position: Vector2 = Vector2(248, 144)
@export var balloon_spawn_offset: float = 30.0

@onready var player_1: CharacterBody2D = $"../Player1"
@onready var player_2: CharacterBody2D = $"../Player2"
@onready var balloon: BalloonController = $"../Balloon"
@onready var audio_manager: Node = get_node("/root/AudioManager")

enum MatchState { ACTIVE, ROUND_OVER, COMPLETE }

var match_state: MatchState = MatchState.ACTIVE
var match_seed: int = 0
var player_1_score: int = 0
var player_2_score: int = 0
var player_1_sets: int = 0
var player_2_sets: int = 0
var round_number: int = 1
var coin_toss_result: String = ""
var round_server: CharacterBody2D
var next_server: CharacterBody2D
var expected_balloon_player: CharacterBody2D
var priority_player: CharacterBody2D
var last_valid_toucher: CharacterBody2D
var round_has_valid_contact: bool = false
var match_winner: CharacterBody2D
var round_faulting_player: CharacterBody2D
var pending_expected_player: CharacterBody2D
var pending_normal_hits: Array[CharacterBody2D] = []
var pending_dash_rescues: Array[CharacterBody2D] = []
var round_replay_requested: bool = false
var consecutive_downward_fault_player: CharacterBody2D
var consecutive_downward_fault_count: int = 0


func _ready() -> void:
	balloon.player_hit.connect(register_normal_hit)
	balloon.dash_rescued.connect(register_dash_rescue)
	balloon.ground_touched.connect(_on_ground_touched)
	player_1.player_bumped.connect(_on_player_bumped)
	player_2.player_bumped.connect(_on_player_bumped)
	_start_new_match()


func restart_match() -> void:
	_start_new_match()


func _start_new_match() -> void:
	audio_manager.call("play_gameplay_event", "match_start")
	match_state = MatchState.ACTIVE
	player_1_score = 0
	player_2_score = 0
	player_1_sets = 0
	player_2_sets = 0
	round_number = 1
	match_winner = null
	round_has_valid_contact = false
	round_faulting_player = null
	round_replay_requested = false
	consecutive_downward_fault_player = null
	consecutive_downward_fault_count = 0
	pending_normal_hits.clear()
	pending_dash_rescues.clear()
	pending_expected_player = null
	player_1.reset_for_round(player_1_spawn_position)
	player_2.reset_for_round(player_2_spawn_position)
	var toss_value := randi_range(0, 1) if coin_toss_override < 0 else coin_toss_override
	coin_toss_result = "HEADS" if toss_value == 0 else "TAILS"
	match_seed = (
		randi()
		if match_seed_override < 0
		else match_seed_override
	)
	var opening_player := player_1 if toss_value == 0 else player_2
	set_next_server(opening_player)
	balloon.reset_round(_balloon_spawn_for(opening_player), true)
	score_changed.emit(player_1_score, player_2_score)
	set_score_changed.emit(player_1_sets, player_2_sets)
	coin_toss_completed.emit(coin_toss_result, opening_player)
	round_started.emit(round_number, round_server)


func _process(_delta: float) -> void:
	if match_state == MatchState.ACTIVE:
		resolve_pending_contacts()


func set_next_server(player: CharacterBody2D) -> void:
	if player != player_1 and player != player_2:
		push_error("Next server must be one of the two match players.")
		return
	next_server = player
	round_server = player
	last_valid_toucher = player
	expected_balloon_player = player
	balloon_turn_changed.emit(expected_balloon_player)
	opening_server_selected.emit(player)
	_set_priority(player)


func register_normal_hit(player: CharacterBody2D) -> void:
	if match_state == MatchState.ACTIVE and not pending_normal_hits.has(player):
		if pending_expected_player == null:
			pending_expected_player = expected_balloon_player
		pending_normal_hits.append(player)


func register_dash_rescue(player: CharacterBody2D, _direction: Vector2) -> void:
	if match_state == MatchState.ACTIVE and not pending_dash_rescues.has(player):
		if pending_expected_player == null:
			pending_expected_player = expected_balloon_player
		pending_dash_rescues.append(player)


func resolve_pending_contacts() -> void:
	if pending_expected_player == null:
		return
	var all_candidates: Array[CharacterBody2D] = []
	all_candidates.append_array(pending_normal_hits)
	all_candidates.append_array(pending_dash_rescues)
	var offending_player: CharacterBody2D
	for candidate: CharacterBody2D in all_candidates:
		if candidate != pending_expected_player:
			offending_player = candidate
			break
	if offending_player != null and match_state == MatchState.ACTIVE:
		_resolve_fault(offending_player)
		return

	var selected_player := pending_expected_player
	var selected_contact_type := BalloonController.ContactType.DASH_RESCUE \
		if pending_dash_rescues.has(selected_player) else BalloonController.ContactType.NORMAL
	var contact_result: Dictionary = balloon.apply_pending_contact(
		selected_player, selected_contact_type
	)
	if not contact_result.is_empty():
		var resulting_velocity: Vector2 = contact_result["resulting_velocity"]
		if resulting_velocity.y > 0.0 and match_state == MatchState.ACTIVE:
			_resolve_downward_hit_fault(selected_player)
			return
		round_has_valid_contact = true
	_set_priority(selected_player)
	last_valid_toucher = selected_player
	expected_balloon_player = _opponent_of(selected_player)
	balloon_turn_changed.emit(expected_balloon_player)
	_clear_pending_contacts()


func _clear_pending_contacts() -> void:
	pending_dash_rescues.clear()
	pending_normal_hits.clear()
	pending_expected_player = null
	balloon.clear_pending_contacts()


func _resolve_fault(faulting_player: CharacterBody2D) -> void:
	if match_state != MatchState.ACTIVE:
		return
	consecutive_downward_fault_player = null
	consecutive_downward_fault_count = 0
	match_state = MatchState.ROUND_OVER
	round_faulting_player = faulting_player
	_clear_pending_contacts()
	call_deferred("_finish_round")


func _resolve_downward_hit_fault(faulting_player: CharacterBody2D) -> void:
	if match_state != MatchState.ACTIVE:
		return
	if consecutive_downward_fault_player == faulting_player:
		consecutive_downward_fault_count += 1
	else:
		consecutive_downward_fault_player = faulting_player
		consecutive_downward_fault_count = 1

	var point_deducted := consecutive_downward_fault_count >= 2
	if point_deducted:
		if faulting_player == player_1:
			player_1_score = maxi(player_1_score - 1, 0)
		else:
			player_2_score = maxi(player_2_score - 1, 0)
		score_changed.emit(player_1_score, player_2_score)
		consecutive_downward_fault_player = null
		consecutive_downward_fault_count = 0
		next_server = _opponent_of(faulting_player)
	else:
		next_server = round_server

	match_state = MatchState.ROUND_OVER
	round_faulting_player = faulting_player
	round_replay_requested = true
	_clear_pending_contacts()
	downward_fault_replayed.emit(faulting_player, point_deducted)
	call_deferred("_finish_round")


func _balloon_spawn_for(player: CharacterBody2D) -> Vector2:
	return player.global_position + Vector2.UP * balloon_spawn_offset


func _set_priority(player: CharacterBody2D) -> void:
	if priority_player == player:
		return
	if is_instance_valid(priority_player):
		priority_player.set_priority_indicator(false)
	priority_player = player
	priority_player.set_priority_indicator(true)
	priority_changed.emit(player)


func _on_ground_touched() -> void:
	if match_state != MatchState.ACTIVE:
		return
	resolve_pending_contacts()
	if match_state != MatchState.ACTIVE:
		return
	if not round_has_valid_contact:
		next_server = round_server
		match_state = MatchState.ROUND_OVER
		round_replay_requested = true
		call_deferred("_finish_round")
		return
	consecutive_downward_fault_player = null
	consecutive_downward_fault_count = 0
	match_state = MatchState.ROUND_OVER
	call_deferred("_finish_round")


func _finish_round() -> void:
	if round_replay_requested:
		round_replay_requested = false
		await get_tree().create_timer(round_intermission).timeout
		if match_state == MatchState.ROUND_OVER:
			_restart_point()
		return
	consecutive_downward_fault_player = null
	consecutive_downward_fault_count = 0
	var point_winner: CharacterBody2D
	if is_instance_valid(round_faulting_player):
		point_winner = _opponent_of(round_faulting_player)
	elif is_instance_valid(last_valid_toucher):
		point_winner = last_valid_toucher
	else:
		point_winner = round_server
	if point_winner == player_1:
		player_1_score += 1
	else:
		player_2_score += 1
	next_server = point_winner
	score_changed.emit(player_1_score, player_2_score)
	round_ended.emit(point_winner, player_1_score, player_2_score)
	audio_manager.call("play_gameplay_event", _player_audio_event("laugh", point_winner))

	if player_1_score >= target_score or player_2_score >= target_score:
		var completed_set_player_1_score := player_1_score
		var completed_set_player_2_score := player_2_score
		if point_winner == player_1:
			player_1_sets += 1
		else:
			player_2_sets += 1
		set_won.emit(
			point_winner,
			completed_set_player_1_score,
			completed_set_player_2_score,
			player_1_sets,
			player_2_sets
		)
		audio_manager.call(
			"play_gameplay_event", _player_audio_event("set_new", point_winner)
		)
		player_1_score = 0
		player_2_score = 0
		score_changed.emit(player_1_score, player_2_score)
		set_score_changed.emit(player_1_sets, player_2_sets)
		set_ended.emit(point_winner, player_1_sets, player_2_sets)
		if player_1_sets >= sets_to_win or player_2_sets >= sets_to_win:
			match_state = MatchState.COMPLETE
			match_winner = point_winner
			match_ended.emit(match_winner)
			return

	await get_tree().create_timer(round_intermission).timeout
	if match_state == MatchState.ROUND_OVER:
		_start_next_round()


func _start_next_round() -> void:
	round_number += 1
	_restart_point()


func _restart_point() -> void:
	round_faulting_player = null
	round_replay_requested = false
	round_has_valid_contact = false
	_clear_pending_contacts()
	pending_normal_hits.clear()
	pending_dash_rescues.clear()
	player_1.reset_for_round(player_1_spawn_position)
	player_2.reset_for_round(player_2_spawn_position)
	match_state = MatchState.ACTIVE
	set_next_server(next_server)
	balloon.reset_round(_balloon_spawn_for(round_server), true)
	round_started.emit(round_number, round_server)


func _opponent_of(player: CharacterBody2D) -> CharacterBody2D:
	return player_2 if player == player_1 else player_1


func _player_audio_event(prefix: String, player: CharacterBody2D) -> String:
	var player_index := 1 if player == player_1 else 2
	return "%s_p%d" % [prefix, player_index]


func _on_player_bumped(
	player: CharacterBody2D,
	opponent: CharacterBody2D,
	while_dashing: bool
) -> void:
	var player_2_controller := player_2 as PlayerController
	if player != player_1 and player != player_2:
		return
	if player == player_2 and not while_dashing:
		return
	if player == player_1 and player_2_controller.bot_enabled and not while_dashing:
		return
	if (
		player == player_2
		and player_2_controller.bot_enabled
		and (match_state != MatchState.ACTIVE or expected_balloon_player != player)
	):
		return

	var is_priority_player := player == priority_player
	var push_strength: float
	if while_dashing:
		push_strength = priority_dash_push_strength if is_priority_player else non_priority_dash_push_strength
	else:
		push_strength = priority_push_strength if is_priority_player else normal_push_strength

	var push_direction := signf(opponent.global_position.x - player.global_position.x)
	if is_zero_approx(push_direction):
		push_direction = 1.0
	opponent.velocity.x = clampf(
		opponent.velocity.x + push_direction * push_strength,
		-max_push_speed,
		max_push_speed
	)
