extends Node

signal priority_changed(player: CharacterBody2D)
signal opening_server_selected(player: CharacterBody2D)
signal score_changed(player_1_score: int, player_2_score: int)
signal set_score_changed(player_1_sets: int, player_2_sets: int)
signal round_ended(point_winner: CharacterBody2D, player_1_score: int, player_2_score: int)
signal set_ended(set_winner: CharacterBody2D, player_1_sets: int, player_2_sets: int)
signal round_started(round_number: int, server: CharacterBody2D)
signal match_ended(winner: CharacterBody2D)
signal coin_toss_completed(result: String, first_server: CharacterBody2D)

@export var normal_push_strength: float = 30.0
@export var priority_push_strength: float = 90.0
@export var non_priority_dash_push_strength: float = 60.0
@export var priority_dash_push_strength: float = 180.0
@export var max_push_speed: float = 320.0
@export_range(1, 99) var target_score: int = 5
@export_range(1, 99) var sets_to_win: int = 3
@export_range(-1, 1, 1) var coin_toss_override: int = -1
@export_range(0.0, 10.0, 0.1) var round_intermission: float = 1.5
@export var player_1_spawn_position: Vector2 = Vector2(72, 144)
@export var player_2_spawn_position: Vector2 = Vector2(248, 144)
@export var balloon_spawn_position: Vector2 = Vector2(160, 48)

@onready var player_1: CharacterBody2D = $"../Player1"
@onready var player_2: CharacterBody2D = $"../Player2"
@onready var balloon: RigidBody2D = $"../Balloon"

enum MatchState { ACTIVE, ROUND_OVER, COMPLETE }

var match_state: MatchState = MatchState.ACTIVE
var player_1_score: int = 0
var player_2_score: int = 0
var player_1_sets: int = 0
var player_2_sets: int = 0
var round_number: int = 1
var coin_toss_result: String = ""
var round_server: CharacterBody2D
var next_server: CharacterBody2D
var priority_player: CharacterBody2D
var last_valid_toucher: CharacterBody2D
var match_winner: CharacterBody2D
var pending_normal_hits: Array[CharacterBody2D] = []
var pending_dash_rescues: Array[CharacterBody2D] = []


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
	match_state = MatchState.ACTIVE
	player_1_score = 0
	player_2_score = 0
	player_1_sets = 0
	player_2_sets = 0
	round_number = 1
	match_winner = null
	pending_normal_hits.clear()
	pending_dash_rescues.clear()
	player_1.reset_for_round(player_1_spawn_position)
	player_2.reset_for_round(player_2_spawn_position)
	balloon.reset_round(balloon_spawn_position)
	var toss_value := randi_range(0, 1) if coin_toss_override < 0 else coin_toss_override
	coin_toss_result = "HEADS" if toss_value == 0 else "TAILS"
	var opening_player := player_1 if toss_value == 0 else player_2
	set_next_server(opening_player)
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
	opening_server_selected.emit(player)
	_set_priority(player)


func register_normal_hit(player: CharacterBody2D) -> void:
	if match_state == MatchState.ACTIVE and not pending_normal_hits.has(player):
		pending_normal_hits.append(player)


func register_dash_rescue(player: CharacterBody2D, _direction: Vector2) -> void:
	if match_state == MatchState.ACTIVE and not pending_dash_rescues.has(player):
		pending_dash_rescues.append(player)


func resolve_pending_contacts() -> void:
	var candidates := pending_dash_rescues if not pending_dash_rescues.is_empty() else pending_normal_hits
	var selected_player: CharacterBody2D
	if candidates.size() == 1:
		selected_player = candidates[0]
	elif candidates.size() > 1:
		for candidate: CharacterBody2D in candidates:
			if candidate != priority_player:
				selected_player = candidate
				break
	if selected_player != null:
		_set_priority(selected_player)
		last_valid_toucher = selected_player

	pending_dash_rescues.clear()
	pending_normal_hits.clear()


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
	match_state = MatchState.ROUND_OVER
	call_deferred("_finish_round")


func _finish_round() -> void:
	resolve_pending_contacts()
	var point_winner := _opponent_of(
		last_valid_toucher if last_valid_toucher != null else round_server
	)
	if point_winner == player_1:
		player_1_score += 1
	else:
		player_2_score += 1
	next_server = point_winner
	score_changed.emit(player_1_score, player_2_score)
	round_ended.emit(point_winner, player_1_score, player_2_score)

	if player_1_score >= target_score or player_2_score >= target_score:
		if point_winner == player_1:
			player_1_sets += 1
		else:
			player_2_sets += 1
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
	last_valid_toucher = null
	pending_normal_hits.clear()
	pending_dash_rescues.clear()
	player_1.reset_for_round(player_1_spawn_position)
	player_2.reset_for_round(player_2_spawn_position)
	balloon.reset_round(balloon_spawn_position)
	match_state = MatchState.ACTIVE
	set_next_server(next_server)
	round_started.emit(round_number, round_server)


func _opponent_of(player: CharacterBody2D) -> CharacterBody2D:
	return player_2 if player == player_1 else player_1


func _on_player_bumped(
	player: CharacterBody2D,
	opponent: CharacterBody2D,
	while_dashing: bool
) -> void:
	if player != player_1:
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
