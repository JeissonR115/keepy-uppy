class_name PauseMenu
extends Control

signal controls_requested
signal player_count_requested

enum MenuScreen { HIDDEN, PAUSE, CONTROLS }

const PAUSE_OPTIONS: Array[String] = ["RESUME", "RESTART", "CONTROLS"]

@onready var keyboard_menu: KeyboardMenu = $KeyboardMenu
@onready var pause_panel: PanelContainer = $PausePanel
@onready var pause_buttons: Array[Button] = [
	$PausePanel/Content/OptionsScroll/Margins/Options/ResumeButton,
	$PausePanel/Content/OptionsScroll/Margins/Options/RestartButton,
	$PausePanel/Content/OptionsScroll/Margins/Options/ControlsButton,
]

var current_screen: MenuScreen = MenuScreen.HIDDEN
var selected_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	keyboard_menu.item_activated.connect(_on_item_activated)
	keyboard_menu.selection_changed.connect(_on_selection_changed)
	keyboard_menu.cancelled.connect(_go_back)
	for index in range(pause_buttons.size()):
		pause_buttons[index].pressed.connect(_on_pause_option_pressed.bind(index))
	pause_panel.visible = false
	_set_pause_selection(0)


func open_pause() -> void:
	if current_screen != MenuScreen.HIDDEN:
		return
	get_tree().paused = true
	current_screen = MenuScreen.PAUSE
	pause_panel.visible = true
	keyboard_menu.activate(0)


func toggle_pause() -> void:
	if current_screen == MenuScreen.HIDDEN:
		open_pause()
	else:
		close_pause()


func close_pause() -> void:
	current_screen = MenuScreen.HIDDEN
	keyboard_menu.deactivate()
	visible = false
	get_tree().paused = false


func open_controls() -> void:
	if current_screen != MenuScreen.PAUSE:
		return
	current_screen = MenuScreen.CONTROLS
	keyboard_menu.deactivate()
	visible = false
	controls_requested.emit()


func return_from_controls() -> void:
	current_screen = MenuScreen.PAUSE
	visible = true
	pause_panel.visible = true
	keyboard_menu.activate(2)


func is_open() -> bool:
	return current_screen != MenuScreen.HIDDEN


func get_pause_button(option_name: String) -> Button:
	var index := PAUSE_OPTIONS.find(option_name.to_upper())
	return pause_buttons[index] if index >= 0 else null


func _on_item_activated(index: int) -> void:
	if index >= 0 and index < pause_buttons.size():
		_on_pause_option_pressed(index)


func _on_selection_changed(index: int) -> void:
	_set_pause_selection(index)


func _set_pause_selection(index: int) -> void:
	selected_index = index
	for button_index in range(pause_buttons.size()):
		pause_buttons[button_index].text = ("> " if button_index == selected_index else "  ") + PAUSE_OPTIONS[button_index]


func _go_back() -> void:
	if current_screen == MenuScreen.PAUSE:
		close_pause()


func _on_pause_option_pressed(index: int) -> void:
	match index:
		0:
			close_pause()
		1:
			current_screen = MenuScreen.HIDDEN
			keyboard_menu.deactivate()
			visible = false
			player_count_requested.emit()
		2:
			open_controls()
