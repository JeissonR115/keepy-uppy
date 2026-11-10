class_name Scoreboard
extends CanvasLayer

@onready var match_manager: MatchManager = get_parent().get_node("MatchManager")
@onready var player_1_score_label: Label = $HUD/ScoreRow/Player1Score
@onready var player_2_score_label: Label = $HUD/ScoreRow/Player2Score
@onready var player_1_sets_label: Label = $HUD/SetScoreRow/Player1Sets
@onready var player_2_sets_label: Label = $HUD/SetScoreRow/Player2Sets
@onready var competitive_label: Label = $HUD/CompetitiveLabel
@onready var status_label: Label = $HUD/StatusLabel
@onready var turn_label: Label = $HUD/TurnLabel
@onready var controls_button: Button = $HUD/ControlsButton
@onready var control_settings: ControlSettings = $ControlSettings
@onready var pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	controls_button.pressed.connect(pause_menu.open_pause)
	pause_menu.controls_requested.connect(_open_control_settings)
	pause_menu.restart_confirmed.connect(_restart_match)
	control_settings.returned_to_pause.connect(pause_menu.return_from_controls)
	match_manager.score_changed.connect(_on_score_changed)
	match_manager.set_score_changed.connect(_on_set_score_changed)
	match_manager.round_ended.connect(_on_round_ended)
	match_manager.set_ended.connect(_on_set_ended)
	match_manager.round_started.connect(_on_round_started)
	match_manager.match_ended.connect(_on_match_ended)
	match_manager.priority_changed.connect(_on_priority_changed)
	match_manager.coin_toss_completed.connect(_on_coin_toss_completed)
	match_manager.balloon_turn_changed.connect(_on_balloon_turn_changed)
	match_manager.downward_fault_replayed.connect(_on_downward_fault_replayed)
	_on_score_changed(match_manager.player_1_score, match_manager.player_2_score)
	_on_set_score_changed(match_manager.player_1_sets, match_manager.player_2_sets)
	_on_round_started(match_manager.round_number, match_manager.round_server)
	_on_balloon_turn_changed(match_manager.expected_balloon_player)
	_refresh_competitive_state()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_ESCAPE and key_event.physical_keycode != KEY_ESCAPE:
		return
	if control_settings.visible and not control_settings.captured_action.is_empty():
		control_settings.cancel_capture()
	elif control_settings.visible:
		control_settings.hide_for_pause_exit()
		pause_menu.close_pause()
	else:
		pause_menu.toggle_pause()
	get_viewport().set_input_as_handled()


func _open_control_settings() -> void:
	control_settings.open()


func _restart_match() -> void:
	match_manager.restart_match()


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


func _on_balloon_turn_changed(player: CharacterBody2D) -> void:
	turn_label.text = "%s: TOUCH BALLOON" % _player_name(player)
	var player_prefix := (
		PlayerActionCatalog.PLAYER_ONE_PREFIX
		if player == match_manager.player_1
		else PlayerActionCatalog.PLAYER_TWO_PREFIX
	)
	turn_label.add_theme_color_override("font_color", PlayerActionCatalog.player_color(player_prefix))


func _on_downward_fault_replayed(player: CharacterBody2D, point_deducted: bool) -> void:
	if point_deducted:
		status_label.text = "%s DOWN FAULT AGAIN: -1" % _player_name(player)
	else:
		status_label.text = "%s DOWN HIT: REPLAY" % _player_name(player)


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
