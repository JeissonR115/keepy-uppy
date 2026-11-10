class_name PlayerCountMenu
extends CanvasLayer

@onready var player_2: PlayerController = get_parent().get_node("Arena/Player2")
@onready var match_manager: MatchManager = get_parent().get_node("Arena/MatchManager")
@onready var keyboard_navigator: MenuKeyboardNavigator = $KeyboardNavigator
@onready var menu_buttons: Array[Button] = [
	$Panel/MenuScroll/Margins/Content/OnePlayerButton,
	$Panel/MenuScroll/Margins/Content/TwoPlayersButton,
]

var selected_index: int = 0
var restart_match_on_selection: bool = false


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	keyboard_navigator.moved.connect(_move_selection)
	keyboard_navigator.confirmed.connect(_confirm_selection)
	for index in range(menu_buttons.size()):
		menu_buttons[index].pressed.connect(_select_player_count.bind(index + 1))
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


func _refresh_selection() -> void:
	menu_buttons[0].text = ("> " if selected_index == 0 else "  ") + "1 PLAYER  |  VS BOT"
	menu_buttons[1].text = ("> " if selected_index == 1 else "  ") + "2 PLAYERS"
	menu_buttons[selected_index].grab_focus()


func _move_selection(direction: int) -> void:
	if not visible:
		return
	selected_index = posmod(selected_index + direction, menu_buttons.size())
	_refresh_selection()


func _confirm_selection() -> void:
	if visible:
		_select_player_count(selected_index + 1)


func _select_player_count(player_count: int) -> void:
	player_2.bot_enabled = player_count == 1
	if restart_match_on_selection:
		restart_match_on_selection = false
		match_manager.restart_match()
	keyboard_navigator.enabled = false
	visible = false
	get_tree().paused = false
