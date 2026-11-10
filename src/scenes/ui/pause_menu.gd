class_name PauseMenu
extends Control

signal controls_requested
signal restart_confirmed

enum MenuScreen { HIDDEN, PAUSE, RESTART_CONFIRMATION, CONTROLS }

var current_screen: MenuScreen = MenuScreen.HIDDEN
var selected_index: int = 0
var pause_buttons: Array[Button] = []
var confirmation_buttons: Array[Button] = []
var pause_option_names: Array[String] = ["RESUME", "RESTART", "CONTROLS"]
var confirmation_option_names: Array[String] = ["YES, RESTART", "NO, GO BACK"]
var pause_panel: PanelContainer
var confirmation_panel: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_menu()
	visible = false


func _process(_delta: float) -> void:
	if current_screen != MenuScreen.PAUSE and current_screen != MenuScreen.RESTART_CONFIRMATION:
		return
	if Input.is_action_just_pressed(
		PlayerActionCatalog.action_name(
			PlayerActionCatalog.PLAYER_ONE_PREFIX, PlayerActionCatalog.ACTION_UP
		)
	):
		_move_selection(-1)
	elif Input.is_action_just_pressed(
		PlayerActionCatalog.action_name(
			PlayerActionCatalog.PLAYER_ONE_PREFIX, PlayerActionCatalog.ACTION_DOWN
		)
	):
		_move_selection(1)
	if Input.is_action_just_pressed(
		PlayerActionCatalog.action_name(
			PlayerActionCatalog.PLAYER_ONE_PREFIX, PlayerActionCatalog.ACTION_JUMP
		)
	):
		_activate_selection()
	elif Input.is_action_just_pressed(
		PlayerActionCatalog.action_name(
			PlayerActionCatalog.PLAYER_ONE_PREFIX, PlayerActionCatalog.ACTION_DASH
		)
	):
		_go_back()


func open_pause() -> void:
	if current_screen != MenuScreen.HIDDEN:
		return
	get_tree().paused = true
	current_screen = MenuScreen.PAUSE
	selected_index = 0
	_show_panel(pause_panel)
	_set_pause_selection()


func toggle_pause() -> void:
	if current_screen == MenuScreen.HIDDEN:
		open_pause()
	else:
		close_pause()


func close_pause() -> void:
	current_screen = MenuScreen.HIDDEN
	visible = false
	get_tree().paused = false


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
	var index := pause_option_names.find(option_name.to_upper())
	return pause_buttons[index] if index >= 0 else null


func get_confirmation_button(option_name: String) -> Button:
	var index := confirmation_option_names.find(option_name.to_upper())
	return confirmation_buttons[index] if index >= 0 else null


func _build_menu() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.015, 0.02, 0.04, 0.78)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	pause_panel = _make_panel("PausePanel", Vector2(158, 122))
	var pause_content := VBoxContainer.new()
	pause_content.add_theme_constant_override("separation", 4)
	pause_panel.add_child(pause_content)
	pause_content.add_child(_make_title("PAUSED"))
	for index in range(pause_option_names.size()):
		var option_index := index
		var button := _make_button(pause_option_names[index])
		button.pressed.connect(_on_pause_option_pressed.bind(option_index))
		pause_buttons.append(button)
		pause_content.add_child(button)
	pause_content.add_child(_make_hint("W/S SELECT   F CONFIRM   G/ESC BACK"))

	confirmation_panel = _make_panel("ConfirmationPanel", Vector2(186, 84))
	var confirmation_content := VBoxContainer.new()
	confirmation_content.add_theme_constant_override("separation", 5)
	confirmation_panel.add_child(confirmation_content)
	confirmation_content.add_child(_make_title("RESTART MATCH?"))
	var confirmation_row := HBoxContainer.new()
	confirmation_row.alignment = BoxContainer.ALIGNMENT_CENTER
	confirmation_row.add_theme_constant_override("separation", 6)
	confirmation_content.add_child(confirmation_row)
	for index in range(confirmation_option_names.size()):
		var option_index := index
		var button := _make_button(confirmation_option_names[index])
		button.custom_minimum_size = Vector2(77, 18)
		button.pressed.connect(_on_confirmation_pressed.bind(option_index))
		confirmation_buttons.append(button)
		confirmation_row.add_child(button)
	confirmation_content.add_child(_make_hint("G CANCEL   F CONFIRM"))

	add_child(pause_panel)
	add_child(confirmation_panel)


func _make_panel(panel_name: String, panel_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -panel_size.x / 2.0
	panel.offset_top = -panel_size.y / 2.0
	panel.offset_right = panel_size.x / 2.0
	panel.offset_bottom = panel_size.y / 2.0
	panel.add_theme_constant_override("margin_left", 8)
	panel.add_theme_constant_override("margin_right", 8)
	panel.add_theme_constant_override("margin_top", 6)
	panel.add_theme_constant_override("margin_bottom", 6)
	return panel


func _make_title(label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	return label


func _make_hint(label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 6)
	return label


func _make_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(132, 18)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 9)
	return button


func _show_panel(panel: Control) -> void:
	visible = true
	pause_panel.visible = panel == pause_panel
	confirmation_panel.visible = panel == confirmation_panel


func _move_selection(step: int) -> void:
	var count := pause_buttons.size() if current_screen == MenuScreen.PAUSE else confirmation_buttons.size()
	selected_index = posmod(selected_index + step, count)
	_set_active_selection()


func _set_pause_selection() -> void:
	_set_button_selection(pause_buttons, selected_index, pause_option_names)


func _set_confirmation_selection() -> void:
	_set_button_selection(confirmation_buttons, selected_index, confirmation_option_names)


func _set_active_selection() -> void:
	if current_screen == MenuScreen.PAUSE:
		_set_pause_selection()
	else:
		_set_confirmation_selection()


func _set_button_selection(buttons: Array[Button], index: int, option_names: Array[String]) -> void:
	for button_index in range(buttons.size()):
		var selected := button_index == index
		buttons[button_index].text = ("> " if selected else "  ") + option_names[button_index]
		if selected:
			buttons[button_index].grab_focus()


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
	if index == 0:
		current_screen = MenuScreen.HIDDEN
		visible = false
		get_tree().paused = false
		restart_confirmed.emit()
	else:
		_cancel_restart_confirmation()


func _cancel_restart_confirmation() -> void:
	current_screen = MenuScreen.PAUSE
	selected_index = 1
	_show_panel(pause_panel)
	_set_pause_selection()
