class_name PlayerCountMenu
extends CanvasLayer

signal controls_requested

const PLAYER_COUNT_OPTIONS: Array[String] = [
	"1 PLAYER  |  VS BOT",
	"2 PLAYERS",
	"KEYBOARD CONTROLS",
]

@onready var player_2: PlayerController = get_parent().get_node("Arena/Player2")
@onready var match_manager: MatchManager = get_parent().get_node("Arena/MatchManager")
@onready var keyboard_navigator: MenuKeyboardNavigator = $KeyboardNavigator
@onready var menu_buttons: Array[Button] = [
	$Panel/MenuScroll/Margins/Content/OnePlayerButton,
	$Panel/MenuScroll/Margins/Content/TwoPlayersButton,
	$Panel/MenuScroll/Margins/Content/ControlsButton,
]

var selected_index: int = 0
var restart_match_on_selection: bool = false


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	keyboard_navigator.moved.connect(_move_selection)
	keyboard_navigator.confirmed.connect(_confirm_selection)
	for index in range(menu_buttons.size()):
		if index < 2:
			menu_buttons[index].pressed.connect(_select_player_count.bind(index + 1))
		else:
			menu_buttons[index].pressed.connect(_open_controls)
	visible = true
	get_tree().paused = true
	_refresh_selection()
	keyboard_navigator.enabled = true


func open_menu() -> void:
	selected_index = 0
	_refresh_selection()
	restart_match_on_selection = true
	visible = true
	keyboard_navigator.enabled = true
	get_tree().paused = true


func suspend_menu() -> void:
	visible = false
	keyboard_navigator.enabled = false


func resume_menu() -> void:
	visible = true
	keyboard_navigator.enabled = true
	_refresh_selection()
	get_tree().paused = true


func _refresh_selection() -> void:
	MenuNavigationUtils.update_button_selection(
		menu_buttons, PLAYER_COUNT_OPTIONS, selected_index
	)


func _move_selection(direction: int) -> void:
	if not visible:
		return
	selected_index = MenuNavigationUtils.wrap_index(
		selected_index + direction, menu_buttons.size()
	)
	_refresh_selection()


func _confirm_selection() -> void:
	if visible and selected_index < 2:
		_select_player_count(selected_index + 1)
	elif visible:
		_open_controls()


func _open_controls() -> void:
	if not visible:
		return
	suspend_menu()
	controls_requested.emit()


func _select_player_count(player_count: int) -> void:
	player_2.bot_enabled = player_count == 1
	if restart_match_on_selection:
		restart_match_on_selection = false
		match_manager.restart_match()
	keyboard_navigator.enabled = false
	visible = false
	get_tree().paused = false
