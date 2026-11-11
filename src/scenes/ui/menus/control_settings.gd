class_name ControlSettings
extends Control

signal returned_to_menu

@onready var settings_manager: ControlSettingsManager = get_node("../../../ControlSettingsManager")
@onready var player_columns: HBoxContainer = $SettingsPanel/Content/ActionScroll/ActionMargins/Columns
@onready var status_label: Label = $SettingsPanel/Content/StatusLabel
@onready var cancel_button: Button = $SettingsPanel/Content/Buttons/CancelButton
@onready var reset_button: Button = $SettingsPanel/Content/Buttons/ResetButton
@onready var close_button: Button = $SettingsPanel/Content/Buttons/CloseButton
@onready var audio_manager: Node = get_node("/root/AudioManager")
var action_buttons: Dictionary = {}
var captured_action: String = ""
var was_paused_before_open: bool = false
var focus_order: Array[Button] = []
var focused_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_populate_action_columns()
	visible = false


func _process(_delta: float) -> void:
	if not visible:
		return
	if not captured_action.is_empty():
		if MenuNavigationUtils.is_player_one_action_just_pressed(
			PlayerActionCatalog.ACTION_DASH
		):
			_cancel_capture()
		return
	var direction := MenuNavigationUtils.just_pressed_direction()
	if direction.x != 0:
		_move_focus_horizontally(direction.x)
	elif direction.y != 0:
		_move_focus(MenuNavigationUtils.linear_step(direction))
	if MenuNavigationUtils.is_player_one_action_just_pressed(PlayerActionCatalog.ACTION_JUMP):
		_activate_focused_control()
	elif MenuNavigationUtils.is_player_one_action_just_pressed(PlayerActionCatalog.ACTION_DASH):
		close()


func open() -> void:
	was_paused_before_open = get_tree().paused
	get_tree().paused = true
	_refresh_action_buttons()
	status_label.text = "Select an action to change its key."
	visible = true
	focused_index = 0
	_focus_control()


func close() -> void:
	_cancel_capture()
	visible = false
	if was_paused_before_open:
		get_tree().paused = true
		call_deferred("_emit_returned_to_pause")
	else:
		get_tree().paused = false


func _emit_returned_to_pause() -> void:
	returned_to_menu.emit()


func cancel_capture() -> void:
	_cancel_capture()


func hide_for_pause_exit() -> void:
	_cancel_capture()
	visible = false


func get_action_button(action_name: String) -> Button:
	return action_buttons.get(action_name) as Button


func _populate_action_columns() -> void:
	for player_data: Dictionary in PlayerActionCatalog.PLAYERS:
		player_columns.add_child(_create_player_column(player_data))

	cancel_button.pressed.connect(_cancel_capture)
	cancel_button.pressed.connect(_play_menu_select)
	cancel_button.focus_entered.connect(_on_control_focus_entered.bind(cancel_button))
	focus_order.append(cancel_button)
	reset_button.pressed.connect(_restore_defaults)
	reset_button.pressed.connect(_play_menu_select)
	reset_button.focus_entered.connect(_on_control_focus_entered.bind(reset_button))
	focus_order.append(reset_button)
	close_button.pressed.connect(close)
	close_button.pressed.connect(_play_menu_select)
	close_button.focus_entered.connect(_on_control_focus_entered.bind(close_button))
	focus_order.append(close_button)


func _create_player_column(player_data: Dictionary) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 1)
	var heading := Label.new()
	heading.text = player_data.heading
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", player_data.color)
	heading.add_theme_font_size_override("font_size", 9)
	column.add_child(heading)

	for action_data: Dictionary in player_data.actions:
		var action_name: String = PlayerActionCatalog.action_name(player_data.prefix, action_data.suffix)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		column.add_child(row)

		var action_label := Label.new()
		action_label.text = action_data.label
		action_label.add_theme_font_size_override("font_size", 8)
		action_label.custom_minimum_size = Vector2(42, 12)
		row.add_child(action_label)

		var binding_button := _make_button("", Vector2(80, 12))
		binding_button.name = "ActionButton_%s" % action_name
		binding_button.add_theme_color_override("font_color", player_data.color)
		binding_button.pressed.connect(_begin_capture.bind(action_name))
		binding_button.pressed.connect(_play_menu_select)
		binding_button.focus_entered.connect(_on_control_focus_entered.bind(binding_button))
		row.add_child(binding_button)
		action_buttons[action_name] = binding_button
		focus_order.append(binding_button)
	return column


func _make_button(button_text: String, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = minimum_size
	button.add_theme_font_size_override("font_size", 8)
	button.focus_mode = Control.FOCUS_ALL
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(0.1, 0.12, 0.18, 1.0)
	focus_style.border_color = Color(1.0, 0.84, 0.32, 1.0)
	focus_style.set_border_width_all(1)
	button.add_theme_stylebox_override("focus", focus_style)
	return button


func _begin_capture(action_name: String) -> void:
	captured_action = action_name
	status_label.text = "Press a new key for %s. Esc cancels." % action_name.replace("_", " ").to_upper()
	cancel_button.disabled = false


func _unhandled_key_input(event: InputEvent) -> void:
	if captured_action.is_empty() or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_ESCAPE:
		_cancel_capture()
		get_viewport().set_input_as_handled()
		return

	var result: Dictionary = settings_manager.try_set_binding(captured_action, key_event)
	if not result.valid:
		status_label.text = result.reason
		get_viewport().set_input_as_handled()
		return

	var completed_action := captured_action
	captured_action = ""
	_refresh_action_button(completed_action)
	status_label.text = "%s is now %s." % [
		completed_action.replace("_", " ").to_upper(),
		_binding_text(completed_action),
	]
	get_viewport().set_input_as_handled()


func _cancel_capture() -> void:
	if captured_action.is_empty():
		return
	captured_action = ""
	status_label.text = "Capture cancelled. The previous key is unchanged."


func _move_focus(step: int) -> void:
	focused_index = MenuNavigationUtils.wrap_index(
		focused_index + step, focus_order.size()
	)
	_focus_control()


func _move_focus_horizontally(step: int) -> void:
	if focus_order.is_empty():
		return
	var focused_button := focus_order[focused_index]
	for action_name: String in action_buttons:
		if action_buttons[action_name] != focused_button:
			continue
		var current_player := PlayerActionCatalog.PLAYER_ONE_PREFIX
		var other_player := PlayerActionCatalog.PLAYER_TWO_PREFIX
		if action_name.begins_with("%s_" % PlayerActionCatalog.PLAYER_TWO_PREFIX):
			current_player = PlayerActionCatalog.PLAYER_TWO_PREFIX
			other_player = PlayerActionCatalog.PLAYER_ONE_PREFIX
		var action_suffix := action_name.trim_prefix("%s_" % current_player)
		var other_button := action_buttons.get(
			PlayerActionCatalog.action_name(other_player, action_suffix)
		) as Button
		if other_button == null:
			return
		focused_index = focus_order.find(other_button)
		_focus_control()
		return

	_move_focus(step)


func _focus_control() -> void:
	if focus_order.is_empty():
		return
	MenuNavigationUtils.focus_control(focus_order[focused_index])


func _activate_focused_control() -> void:
	if focus_order.is_empty():
		return
	focus_order[focused_index].emit_signal("pressed")


func _on_control_focus_entered(button: Button) -> void:
	var index := focus_order.find(button)
	if index >= 0:
		focused_index = index


func _restore_defaults() -> void:
	var result: Dictionary = settings_manager.restore_default_bindings()
	if result.valid:
		_refresh_action_buttons()
		status_label.text = "Default controls restored."
	else:
		status_label.text = result.reason


func _refresh_action_buttons() -> void:
	for action_name: String in action_buttons:
		_refresh_action_button(action_name)


func _refresh_action_button(action_name: String) -> void:
	var button := action_buttons.get(action_name) as Button
	if button != null:
		button.text = _binding_text(action_name)


func _binding_text(action_name: String) -> String:
	var event: InputEventKey = settings_manager.get_binding_event(action_name)
	return "UNBOUND" if event == null else event.as_text()


func _play_menu_select() -> void:
	audio_manager.call("play", "menu_select")
