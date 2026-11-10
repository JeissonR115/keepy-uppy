extends CanvasLayer

@onready var match_manager: Node = get_parent().get_node("MatchManager")
@onready var player_1_score_label: Label = $HUD/ScoreRow/Player1Score
@onready var player_2_score_label: Label = $HUD/ScoreRow/Player2Score
@onready var status_label: Label = $HUD/StatusLabel


func _ready() -> void:
	match_manager.score_changed.connect(_on_score_changed)
	match_manager.round_ended.connect(_on_round_ended)
	match_manager.round_started.connect(_on_round_started)
	match_manager.match_ended.connect(_on_match_ended)
	_on_score_changed(match_manager.player_1_score, match_manager.player_2_score)
	_on_round_started(match_manager.round_number, match_manager.round_server)


func _on_score_changed(player_1_score: int, player_2_score: int) -> void:
	player_1_score_label.text = str(player_1_score)
	player_2_score_label.text = str(player_2_score)


func _on_round_ended(
	point_winner: CharacterBody2D,
	_player_1_score: int,
	_player_2_score: int
) -> void:
	status_label.text = "%s SCORES" % _player_name(point_winner)


func _on_round_started(round_number: int, server: CharacterBody2D) -> void:
	status_label.text = "ROUND %d - %s SERVES" % [round_number, _player_name(server)]


func _on_match_ended(winner: CharacterBody2D) -> void:
	status_label.text = "%s WINS" % _player_name(winner)


func _player_name(player: CharacterBody2D) -> String:
	return "P1" if player == match_manager.player_1 else "P2"
