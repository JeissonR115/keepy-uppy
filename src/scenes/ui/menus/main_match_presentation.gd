extends CanvasLayer

const COIN_DURATION := 1.7
const COIN_FRAME_INTERVAL := 0.11
const COIN_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/Animations/coin/1.png"),
	preload("res://assets/sprites/Animations/coin/2.png"),
	preload("res://assets/sprites/Animations/coin/3.png"),
	preload("res://assets/sprites/Animations/coin/4.png"),
]
@onready var match_manager: MatchManager = get_parent().get_node("Arena/MatchManager")
@onready var toss_panel: Control = $TossPanel
@onready var coin_image: TextureRect = $TossPanel/Content/Coin
@onready var player_1_label: Label = $TossPanel/Content/PlayerLabels/Player1
@onready var player_2_label: Label = $TossPanel/Content/PlayerLabels/Player2

var toss_elapsed := 0.0
var toss_active := false
var expected_player: CharacterBody2D
var turn_arrow: Polygon2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	match_manager.opening_presentation_gate_enabled = DisplayServer.get_name() != "headless"
	match_manager.coin_toss_completed.connect(_on_coin_toss_completed)
	match_manager.balloon_turn_changed.connect(_on_balloon_turn_changed)
	match_manager.round_started.connect(_on_round_started)
	match_manager.round_ended.connect(_on_round_ended)
	match_manager.set_ended.connect(_on_set_ended)
	match_manager.match_ended.connect(_on_match_ended)
	toss_panel.visible = false
	if match_manager.opening_presentation_gate_enabled:
		turn_arrow = Polygon2D.new()
		turn_arrow.name = "TurnArrow"
		turn_arrow.polygon = PackedVector2Array([
			Vector2(-4.0, 0.0),
			Vector2(4.0, 0.0),
			Vector2(0.0, 6.0),
		])
		turn_arrow.z_index = 20
		turn_arrow.visible = false
		get_parent().get_node("Arena").add_child(turn_arrow)


func _process(delta: float) -> void:
	if toss_active:
		toss_elapsed += delta
		var frame_index := int(floor(toss_elapsed / COIN_FRAME_INTERVAL)) % COIN_FRAMES.size()
		coin_image.texture = COIN_FRAMES[frame_index]
		if toss_elapsed >= COIN_DURATION:
			_finish_coin_presentation()
	if turn_arrow == null:
		return
	var rally_active := (
		match_manager.match_state == MatchManager.MatchState.ACTIVE
		and match_manager.round_has_valid_contact
		and is_instance_valid(expected_player)
	)
	turn_arrow.visible = rally_active
	if rally_active:
		var bob := sin(Time.get_ticks_msec() / 220.0) * 1.5
		turn_arrow.global_position = expected_player.global_position + Vector2(0.0, -26.0 + bob)


func _on_coin_toss_completed(_result: String, first_server: CharacterBody2D) -> void:
	var player_1_starts := first_server == match_manager.player_1
	player_1_label.modulate = Color.WHITE if player_1_starts else Color(1.0, 1.0, 1.0, 0.35)
	player_2_label.modulate = Color.WHITE if not player_1_starts else Color(1.0, 1.0, 1.0, 0.35)
	player_1_label.add_theme_color_override(
		"font_color", PlayerActionCatalog.player_color(PlayerActionCatalog.PLAYER_ONE_PREFIX)
	)
	player_2_label.add_theme_color_override(
		"font_color", PlayerActionCatalog.player_color(PlayerActionCatalog.PLAYER_TWO_PREFIX)
	)
	expected_player = first_server
	_update_turn_arrow_color()
	if not match_manager.opening_presentation_gate_enabled:
		match_manager.release_opening_presentation()
		return
	toss_active = true
	toss_elapsed = 0.0
	coin_image.texture = COIN_FRAMES[0]
	toss_panel.visible = true


func _finish_coin_presentation() -> void:
	if not toss_active:
		return
	toss_active = false
	coin_image.texture = COIN_FRAMES.back()
	toss_panel.visible = false
	match_manager.release_opening_presentation()


func _on_balloon_turn_changed(player: CharacterBody2D) -> void:
	expected_player = player
	_update_turn_arrow_color()


func _on_round_started(_round_number: int, server: CharacterBody2D) -> void:
	expected_player = server
	_update_turn_arrow_color()


func _update_turn_arrow_color() -> void:
	if turn_arrow == null or not is_instance_valid(expected_player):
		return
	var player_controller := expected_player as PlayerController
	if player_controller == null:
		push_error("MainMatchPresentation: turn cue received a non-player character.")
		return
	turn_arrow.color = PlayerActionCatalog.player_color(player_controller.input_prefix)


func _on_round_ended(
	_point_winner: CharacterBody2D,
	_player_1_score: int,
	_player_2_score: int
) -> void:
	if turn_arrow != null:
		turn_arrow.visible = false


func _on_set_ended(
	_set_winner: CharacterBody2D,
	_player_1_sets: int,
	_player_2_sets: int
) -> void:
	if turn_arrow != null:
		turn_arrow.visible = false


func _on_match_ended(_winner: CharacterBody2D) -> void:
	if turn_arrow != null:
		turn_arrow.visible = false
