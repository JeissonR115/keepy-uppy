extends CanvasLayer

@onready var match_manager: Node = get_parent().get_node("MatchManager")
@onready var player_1_score_label: Label = $HUD/ScoreRow/Player1Score
@onready var player_2_score_label: Label = $HUD/ScoreRow/Player2Score
@onready var player_1_sets_label: Label = $HUD/SetScoreRow/Player1Sets
@onready var player_2_sets_label: Label = $HUD/SetScoreRow/Player2Sets
@onready var competitive_label: Label = $HUD/CompetitiveLabel
@onready var status_label: Label = $HUD/StatusLabel
@onready var controls_button: Button = $HUD/ControlsButton
@onready var control_settings: Control = $ControlSettings


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	controls_button.pressed.connect(_open_control_settings)
	match_manager.score_changed.connect(_on_score_changed)
	match_manager.set_score_changed.connect(_on_set_score_changed)
	match_manager.round_ended.connect(_on_round_ended)
	match_manager.set_ended.connect(_on_set_ended)
	match_manager.round_started.connect(_on_round_started)
	match_manager.match_ended.connect(_on_match_ended)
	match_manager.priority_changed.connect(_on_priority_changed)
	match_manager.coin_toss_completed.connect(_on_coin_toss_completed)
	_on_score_changed(match_manager.player_1_score, match_manager.player_2_score)
	_on_set_score_changed(match_manager.player_1_sets, match_manager.player_2_sets)
	_on_round_started(match_manager.round_number, match_manager.round_server)
	_refresh_competitive_state()


func _open_control_settings() -> void:
	control_settings.call("open")


func _on_score_changed(player_1_score: int, player_2_score: int) -> void:
	player_1_score_label.text = str(player_1_score)
	player_2_score_label.text = str(player_2_score)


func _on_set_score_changed(player_1_sets: int, player_2_sets: int) -> void:
	player_1_sets_label.text = str(player_1_sets)
	player_2_sets_label.text = str(player_2_sets)


func _on_round_ended(
	point_winner: CharacterBody2D,
	_player_1_score: int,
	_player_2_score: int
) -> void:
	status_label.text = "%s SCORES" % _player_name(point_winner)
	_refresh_competitive_state()


func _on_set_ended(
	set_winner: CharacterBody2D,
	player_1_sets: int,
	player_2_sets: int
) -> void:
	status_label.text = "%s TAKES SET %d" % [
		_player_name(set_winner),
		player_1_sets + player_2_sets
	]


func _on_round_started(round_number: int, server: CharacterBody2D) -> void:
	status_label.text = "ROUND %d" % round_number
	_refresh_competitive_state()


func _on_priority_changed(_player: CharacterBody2D) -> void:
	_refresh_competitive_state()


func _on_coin_toss_completed(_result: String, _first_server: CharacterBody2D) -> void:
	_refresh_competitive_state()


func _on_match_ended(winner: CharacterBody2D) -> void:
	status_label.text = "%s WINS" % _player_name(winner)


func _refresh_competitive_state() -> void:
	if not is_instance_valid(match_manager.priority_player) or not is_instance_valid(match_manager.next_server):
		return
	competitive_label.text = "%s | NEXT %s | PRI %s" % [
		match_manager.coin_toss_result,
		_player_name(match_manager.next_server),
		_player_name(match_manager.priority_player)
	]


func _player_name(player: CharacterBody2D) -> String:
	return "P1" if player == match_manager.player_1 else "P2"
