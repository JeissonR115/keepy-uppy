class_name PlayerCountMenu
extends CanvasLayer

signal controls_requested

const PLAYER_COUNT_OPTIONS: Array[String] = [
	"1 PLAYER  |  VS BOT",
	"2 PLAYERS",
	"KEYBOARD CONTROLS",
]
const LEVEL_OPTIONS: Array[String] = [
	"CLASSIC COURT  320x180",
	"SKY TOWERS  640x360",
	"ANCIENT RUINS  800x450",
	"BACK",
]
const LEVEL_IDS: Array[String] = ["classic", "sky", "ruins"]

@onready var player_2: PlayerController = get_parent().get_node("Arena/Player2")
@onready var match_manager: MatchManager = get_parent().get_node("Arena/MatchManager")
@onready var level_manager: LevelManager = get_parent().get_node("Arena/LevelManager")
@onready var keyboard_navigator: MenuKeyboardNavigator = $KeyboardNavigator
@onready var audio_manager: Node = get_node("/root/AudioManager")
@onready var player_panel: PanelContainer = $Panel
@onready var level_panel: PanelContainer = $LevelPanel
@onready var menu_buttons: Array[Button] = [
	$Panel/MenuScroll/Margins/Content/OnePlayerButton,
	$Panel/MenuScroll/Margins/Content/TwoPlayersButton,
	$Panel/MenuScroll/Margins/Content/ControlsButton,
]
@onready var level_buttons: Array[Button] = [
	$LevelPanel/Content/ClassicButton,
	$LevelPanel/Content/SkyTowersButton,
	$LevelPanel/Content/AncientRuinsButton,
	$LevelPanel/Content/BackButton,
]

var selected_index: int = 0
var showing_levels: bool = false


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	audio_manager.call("play_menu_music")
	keyboard_navigator.moved.connect(_move_selection)
	keyboard_navigator.confirmed.connect(_confirm_selection)
	keyboard_navigator.cancelled.connect(_cancel_level_selection)
	for index in range(menu_buttons.size()):
		if index < 2:
			menu_buttons[index].pressed.connect(_select_player_count.bind(index + 1))
		else:
			menu_buttons[index].pressed.connect(_open_controls)
	for index in range(LEVEL_IDS.size()):
		level_buttons[index].pressed.connect(_select_level.bind(LEVEL_IDS[index]))
	level_buttons.back().pressed.connect(_cancel_level_selection)
	level_panel.visible = false
	visible = true
	get_tree().paused = true
	_refresh_selection()
	keyboard_navigator.enabled = true


func open_menu() -> void:
	audio_manager.call("play_menu_music")
	showing_levels = false
	player_panel.visible = true
	level_panel.visible = false
	selected_index = 0
	_refresh_selection()
	visible = true
	keyboard_navigator.enabled = true
	get_tree().paused = true


func suspend_menu() -> void:
	visible = false
	keyboard_navigator.enabled = false


func resume_menu() -> void:
	showing_levels = false
	player_panel.visible = true
	level_panel.visible = false
	visible = true
	keyboard_navigator.enabled = true
	_refresh_selection()
	get_tree().paused = true


func _refresh_selection() -> void:
	if showing_levels:
		MenuNavigationUtils.update_button_selection(
			level_buttons, LEVEL_OPTIONS, selected_index
		)
	else:
		MenuNavigationUtils.update_button_selection(
			menu_buttons, PLAYER_COUNT_OPTIONS, selected_index
		)


func _move_selection(direction: int) -> void:
	if not visible:
		return
	var buttons: Array[Button] = level_buttons if showing_levels else menu_buttons
	selected_index = MenuNavigationUtils.wrap_index(
		selected_index + direction, buttons.size()
	)
	_refresh_selection()


func _confirm_selection() -> void:
	if not visible:
		return
	if showing_levels:
		if selected_index < LEVEL_IDS.size():
			_select_level(LEVEL_IDS[selected_index])
		else:
			_cancel_level_selection()
	elif selected_index < 2:
		_select_player_count(selected_index + 1)
	else:
		_open_controls()


func _open_controls() -> void:
	if not visible:
		return
	audio_manager.call("play", "menu_select")
	suspend_menu()
	controls_requested.emit()


func _select_player_count(player_count: int) -> void:
	audio_manager.call("play", "menu_select")
	player_2.bot_enabled = player_count == 1
	showing_levels = true
	selected_index = 0
	player_panel.visible = false
	level_panel.visible = true
	_refresh_selection()


func _select_level(level_id: String) -> void:
	if not visible or not showing_levels:
		return
	audio_manager.call("play", "menu_select")
	level_manager.select_level(level_id)
	match_manager.restart_match()
	audio_manager.call("play_match_music")
	showing_levels = false
	keyboard_navigator.enabled = false
	visible = false
	get_tree().paused = false


func _cancel_level_selection() -> void:
	if not visible or not showing_levels:
		return
	audio_manager.call("play", "menu_select")
	showing_levels = false
	selected_index = 0
	player_panel.visible = true
	level_panel.visible = false
	_refresh_selection()
