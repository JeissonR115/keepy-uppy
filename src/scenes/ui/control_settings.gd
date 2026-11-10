extends Control

signal returned_to_pause

const PLAYER_ACTIONS: Array[Dictionary] = [
	{
		"heading": "PLAYER 1",
		"prefix": "player_1",
		"color": Color(0.290196, 0.764706, 0.843137),
	},
	{
		"heading": "PLAYER 2",
		"prefix": "player_2",
		"color": Color(1.0, 0.584314, 0.427451),
	},
]
const ACTION_LABELS: Dictionary = {
	"left": "LEFT",
	"right": "RIGHT",
	"up": "UP",
	"down": "DOWN",
	"jump": "JUMP",
	"dash": "DASH",
	"accelerate": "BOOST",
}

var settings_manager: Node
var action_buttons: Dictionary = {}
var captured_action: String = ""
var was_paused_before_open: bool = false
var status_label: Label
var cancel_button: Button
var focus_order: Array[Button] = []
var focused_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_manager = get_node("/root/Main/ControlSettingsManager")
	_build_screen()
	visible = false


func _process(_delta: float) -> void:
	if not visible:
		return
	if not captured_action.is_empty():
		if Input.is_action_just_pressed("player_1_dash"):
			_cancel_capture()
		return
	if Input.is_action_just_pressed("player_1_up"):
		_move_focus(-1)
	elif Input.is_action_just_pressed("player_1_down"):
		_move_focus(1)
	if Input.is_action_just_pressed("player_1_jump"):
		_activate_focused_control()
	elif Input.is_action_just_pressed("player_1_dash"):
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
	returned_to_pause.emit()


func cancel_capture() -> void:
	_cancel_capture()


func hide_for_pause_exit() -> void:
	_cancel_capture()
	visible = false


func get_action_button(action_name: String) -> Button:
	return action_buttons.get(action_name) as Button


func _build_screen() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.015, 0.02, 0.04, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -151.0
	panel.offset_top = -81.0
	panel.offset_right = 151.0
	panel.offset_bottom = 81.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	panel.add_child(content)

	var title := Label.new()
	title.text = "KEYBOARD CONTROLS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 10)
	content.add_child(title)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 8)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(columns)
	for player_data: Dictionary in PLAYER_ACTIONS:
		columns.add_child(_build_player_column(player_data))

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Select an action to change its key."
	status_label.add_theme_font_size_override("font_size", 8)
	status_label.custom_minimum_size = Vector2(0, 12)
	status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	status_label.clip_text = true
	content.add_child(status_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 5)
	content.add_child(buttons)

	cancel_button = _make_button("CANCEL CAPTURE", Vector2(87, 14))
	cancel_button.pressed.connect(_cancel_capture)
	cancel_button.focus_entered.connect(_on_control_focus_entered.bind(cancel_button))
	buttons.add_child(cancel_button)
	focus_order.append(cancel_button)

	var reset_button := _make_button("RESTORE DEFAULTS", Vector2(91, 14))
	reset_button.pressed.connect(_restore_defaults)
	reset_button.focus_entered.connect(_on_control_focus_entered.bind(reset_button))
	buttons.add_child(reset_button)
	focus_order.append(reset_button)

	var close_button := _make_button("BACK", Vector2(45, 14))
	close_button.pressed.connect(close)
	close_button.focus_entered.connect(_on_control_focus_entered.bind(close_button))
	buttons.add_child(close_button)
	focus_order.append(close_button)


func _build_player_column(player_data: Dictionary) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 1)
	var heading := Label.new()
	heading.text = player_data.heading
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", player_data.color)
	heading.add_theme_font_size_override("font_size", 9)
	column.add_child(heading)

	for action_suffix: String in ACTION_LABELS:
		var action_name: String = "%s_%s" % [player_data.prefix, action_suffix]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		column.add_child(row)

		var action_label := Label.new()
		action_label.text = ACTION_LABELS[action_suffix]
		action_label.add_theme_font_size_override("font_size", 8)
		action_label.custom_minimum_size = Vector2(42, 12)
		row.add_child(action_label)

		var binding_button := _make_button("", Vector2(88, 12))
		binding_button.name = "ActionButton_%s" % action_name
		binding_button.add_theme_color_override("font_color", player_data.color)
		binding_button.pressed.connect(_begin_capture.bind(action_name))
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

	var result: Dictionary = settings_manager.call(
		"try_set_binding",
		captured_action,
		key_event
	)
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
	focused_index = posmod(focused_index + step, focus_order.size())
	_focus_control()


func _focus_control() -> void:
	if focus_order.is_empty():
		return
	focus_order[focused_index].grab_focus()


func _activate_focused_control() -> void:
	if focus_order.is_empty():
		return
	focus_order[focused_index].emit_signal("pressed")


func _on_control_focus_entered(button: Button) -> void:
	var index := focus_order.find(button)
	if index >= 0:
		focused_index = index


func _restore_defaults() -> void:
	var result: Dictionary = settings_manager.call("restore_default_bindings")
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
	var event: InputEventKey = settings_manager.call("get_binding_event", action_name)
	return "UNBOUND" if event == null else event.as_text()
