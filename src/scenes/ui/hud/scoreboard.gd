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
@onready var winner_overlay: Control = $WinnerOverlay
@onready var winner_label: Label = $WinnerOverlay/WinnerPanel/Content/WinnerLabel
@onready var winner_ok_button: Button = $WinnerOverlay/WinnerPanel/Content/OkButton
@onready var player_count_menu: PlayerCountMenu = get_node("../../PlayerCountMenu")
var winner_navigator: MenuKeyboardNavigator
var set_result_panel: PanelContainer
var set_result_label: Label
var set_result_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	winner_navigator = MenuKeyboardNavigator.new()
	add_child(winner_navigator)
	winner_navigator.confirmed.connect(_return_to_player_count_menu)
	winner_navigator.cancelled.connect(_return_to_player_count_menu)
	controls_button.pressed.connect(pause_menu.open_pause)
	winner_ok_button.pressed.connect(_return_to_player_count_menu)
	pause_menu.controls_requested.connect(_open_control_settings)
	pause_menu.player_count_requested.connect(_open_player_count_menu)
	control_settings.returned_to_pause.connect(pause_menu.return_from_controls)
	match_manager.score_changed.connect(_on_score_changed)
	match_manager.set_score_changed.connect(_on_set_score_changed)
	match_manager.round_ended.connect(_on_round_ended)
	match_manager.set_ended.connect(_on_set_ended)
	match_manager.set_won.connect(_on_set_won)
	match_manager.round_started.connect(_on_round_started)
	match_manager.match_ended.connect(_on_match_ended)
	match_manager.priority_changed.connect(_on_priority_changed)
	match_manager.coin_toss_completed.connect(_on_coin_toss_completed)
	match_manager.balloon_turn_changed.connect(_on_balloon_turn_changed)
	match_manager.downward_fault_replayed.connect(_on_downward_fault_replayed)
	match_manager.balloon.contact_visualized.connect(_on_balloon_contact_visualized)
	_build_set_result_panel()
	_on_score_changed(match_manager.player_1_score, match_manager.player_2_score)
	_on_set_score_changed(match_manager.player_1_sets, match_manager.player_2_sets)
	_on_round_started(match_manager.round_number, match_manager.round_server)
	_on_balloon_turn_changed(match_manager.expected_balloon_player)
	_refresh_competitive_state()


func _input(event: InputEvent) -> void:
	if player_count_menu.visible or winner_overlay.visible:
		return
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


func _open_player_count_menu() -> void:
	player_count_menu.open_menu()


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


func _on_set_won(
	set_winner: CharacterBody2D,
	player_1_set_score: int,
	player_2_set_score: int,
	player_1_sets: int,
	player_2_sets: int
) -> void:
	var winning_score := player_1_set_score if set_winner == match_manager.player_1 else player_2_set_score
	var losing_score := player_2_set_score if set_winner == match_manager.player_1 else player_1_set_score
	set_result_label.text = "%s WINS SET  %d - %d\nSETS  %d - %d" % [
		_player_name(set_winner),
		winning_score,
		losing_score,
		player_1_sets,
		player_2_sets
	]
	set_result_panel.visible = true
	set_result_panel.modulate.a = 1.0
	if set_result_tween != null and set_result_tween.is_running():
		set_result_tween.kill()
	set_result_tween = create_tween()
	set_result_tween.tween_interval(1.2)
	set_result_tween.tween_property(set_result_panel, "modulate:a", 0.0, 0.6)
	set_result_tween.tween_callback(func() -> void: set_result_panel.visible = false)


func _build_set_result_panel() -> void:
	set_result_panel = PanelContainer.new()
	set_result_panel.name = "SetResultPanel"
	set_result_panel.visible = false
	set_result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_result_panel.anchor_left = 0.5
	set_result_panel.anchor_top = 0.5
	set_result_panel.anchor_right = 0.5
	set_result_panel.anchor_bottom = 0.5
	set_result_panel.offset_left = -74.0
	set_result_panel.offset_top = -20.0
	set_result_panel.offset_right = 74.0
	set_result_panel.offset_bottom = 20.0
	set_result_label = Label.new()
	set_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	set_result_label.add_theme_font_size_override("font_size", 8)
	set_result_panel.add_child(set_result_label)
	add_child(set_result_panel)


func _on_balloon_contact_visualized(player: CharacterBody2D, balloon_position: Vector2) -> void:
	var direction := (balloon_position - player.global_position).normalized()
	if direction.is_zero_approx():
		direction = Vector2.UP
	if player is PlayerController:
		(player as PlayerController).show_touch_pixel(player.global_position + direction * 6.0)
	match_manager.balloon.show_contact_pixel(balloon_position - direction * 7.0)


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
	winner_label.text = "%s WINS" % _player_name(winner)
	winner_overlay.visible = true
	winner_ok_button.grab_focus()
	winner_navigator.enabled = true
	get_tree().paused = true


func _return_to_player_count_menu() -> void:
	if not winner_overlay.visible:
		return
	winner_navigator.enabled = false
	winner_overlay.visible = false
	player_count_menu.open_menu()


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
