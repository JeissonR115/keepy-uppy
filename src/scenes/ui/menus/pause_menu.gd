class_name PauseMenu
extends CanvasLayer

signal opened
signal closed
signal controls_requested
signal player_count_requested

enum MenuScreen { HIDDEN, PAUSE, RESTART_CONFIRMATION, CONTROLS }

const PAUSE_LAYER := 127
const PAUSE_OPTIONS: Array[String] = ["RESUME", "RESTART", "CONTROLS"]
const CONFIRMATION_OPTIONS: Array[String] = ["YES, RESTART", "NO, GO BACK"]

@onready var pause_panel: PanelContainer = $PausePanel
@onready var confirmation_panel: PanelContainer = $ConfirmationPanel
@onready var pause_buttons: Array[Button] = [
	$PausePanel/Content/Options/ResumeButton,
	$PausePanel/Content/Options/RestartButton,
	$PausePanel/Content/Options/ControlsButton,
]
@onready var confirmation_buttons: Array[Button] = [
	$ConfirmationPanel/Content/Options/ConfirmButton,
	$ConfirmationPanel/Content/Options/CancelButton,
]
@onready var audio_manager: Node = get_node("/root/AudioManager")

var current_screen: MenuScreen = MenuScreen.HIDDEN
var selected_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = PAUSE_LAYER
	for index in range(pause_buttons.size()):
		pause_buttons[index].pressed.connect(_on_pause_option_pressed.bind(index))
	for index in range(confirmation_buttons.size()):
		confirmation_buttons[index].pressed.connect(_on_confirmation_pressed.bind(index))
	_set_pause_selection()
	visible = false


func _process(_delta: float) -> void:
	if current_screen != MenuScreen.PAUSE and current_screen != MenuScreen.RESTART_CONFIRMATION:
		return
	var direction := MenuNavigationUtils.just_pressed_direction()
	if current_screen == MenuScreen.PAUSE and direction.y != 0:
		_move_selection(direction.y)
	elif current_screen == MenuScreen.RESTART_CONFIRMATION and direction.x != 0:
		_move_selection(direction.x)
	if MenuNavigationUtils.is_player_one_action_just_pressed(PlayerActionCatalog.ACTION_JUMP):
		_activate_selection()
	elif MenuNavigationUtils.is_player_one_action_just_pressed(PlayerActionCatalog.ACTION_DASH):
		_go_back()


func open_pause() -> void:
	if current_screen != MenuScreen.HIDDEN:
		return
	layer = PAUSE_LAYER
	get_tree().paused = true
	current_screen = MenuScreen.PAUSE
	selected_index = 0
	_show_panel(pause_panel)
	_set_pause_selection()
	opened.emit()


func toggle_pause() -> void:
	if current_screen == MenuScreen.HIDDEN:
		open_pause()
	else:
		close_pause()


func close_pause() -> void:
	if current_screen == MenuScreen.HIDDEN:
		return
	current_screen = MenuScreen.HIDDEN
	visible = false
	get_tree().paused = false
	closed.emit()


func open_controls() -> void:
	if current_screen != MenuScreen.PAUSE:
		return
	current_screen = MenuScreen.CONTROLS
	visible = false
	controls_requested.emit()


func return_from_controls() -> void:
	current_screen = MenuScreen.PAUSE
	selected_index = 2
	get_tree().paused = true
	_show_panel(pause_panel)
	_set_pause_selection()


func is_open() -> bool:
	return current_screen != MenuScreen.HIDDEN


func get_pause_button(option_name: String) -> Button:
	var index := PAUSE_OPTIONS.find(option_name.to_upper())
	return pause_buttons[index] if index >= 0 else null


func get_confirmation_button(option_name: String) -> Button:
	var index := CONFIRMATION_OPTIONS.find(option_name.to_upper())
	return confirmation_buttons[index] if index >= 0 else null


func _show_panel(panel: Control) -> void:
	visible = true
	pause_panel.visible = panel == pause_panel
	confirmation_panel.visible = panel == confirmation_panel


func _move_selection(step: int) -> void:
	var buttons := pause_buttons if current_screen == MenuScreen.PAUSE else confirmation_buttons
	selected_index = MenuNavigationUtils.wrap_index(
		selected_index + step, buttons.size()
	)
	_set_active_selection()


func _set_pause_selection() -> void:
	MenuNavigationUtils.update_button_selection(pause_buttons, PAUSE_OPTIONS, selected_index)


func _set_confirmation_selection() -> void:
	MenuNavigationUtils.update_button_selection(
		confirmation_buttons, CONFIRMATION_OPTIONS, selected_index
	)


func _set_active_selection() -> void:
	if current_screen == MenuScreen.PAUSE:
		_set_pause_selection()
	else:
		_set_confirmation_selection()


func _activate_selection() -> void:
	if current_screen == MenuScreen.PAUSE:
		_on_pause_option_pressed(selected_index)
	elif current_screen == MenuScreen.RESTART_CONFIRMATION:
		_on_confirmation_pressed(selected_index)


func _go_back() -> void:
	if current_screen == MenuScreen.RESTART_CONFIRMATION:
		_cancel_restart_confirmation()
	elif current_screen == MenuScreen.PAUSE:
		close_pause()


func _on_pause_option_pressed(index: int) -> void:
	audio_manager.call("play", "menu_select")
	match index:
		0:
			close_pause()
		1:
			current_screen = MenuScreen.RESTART_CONFIRMATION
			selected_index = 1
			_show_panel(confirmation_panel)
			_set_confirmation_selection()
		2:
			open_controls()


func _on_confirmation_pressed(index: int) -> void:
	audio_manager.call("play", "menu_select")
	if index == 0:
		current_screen = MenuScreen.HIDDEN
		visible = false
		player_count_requested.emit()
	else:
		_cancel_restart_confirmation()


func _cancel_restart_confirmation() -> void:
	current_screen = MenuScreen.PAUSE
	selected_index = 1
	_show_panel(pause_panel)
	_set_pause_selection()
