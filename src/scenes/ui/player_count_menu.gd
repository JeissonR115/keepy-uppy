class_name PlayerCountMenu
extends CanvasLayer

const MENU_PANEL_SIZE := Vector2(196.0, 104.0)
const MENU_BUTTON_SIZE := Vector2(168.0, 20.0)

var selected_index: int = 0
var menu_buttons: Array[Button] = []
var player_2: PlayerController


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	player_2 = get_parent().get_node("Arena/Player2")
	get_tree().paused = true
	_build_menu()


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		return

	var up_action := PlayerActionCatalog.action_name(
		PlayerActionCatalog.PLAYER_ONE_PREFIX, PlayerActionCatalog.ACTION_UP
	)
	var down_action := PlayerActionCatalog.action_name(
		PlayerActionCatalog.PLAYER_ONE_PREFIX, PlayerActionCatalog.ACTION_DOWN
	)
	var confirm_action := PlayerActionCatalog.action_name(
		PlayerActionCatalog.PLAYER_ONE_PREFIX, PlayerActionCatalog.ACTION_JUMP
	)
	if _matches_menu_key(key_event, up_action, KEY_W):
		selected_index = posmod(selected_index - 1, menu_buttons.size())
		_refresh_selection()
	elif _matches_menu_key(key_event, down_action, KEY_S):
		selected_index = posmod(selected_index + 1, menu_buttons.size())
		_refresh_selection()
	elif _matches_menu_key(key_event, confirm_action, KEY_F):
		_select_player_count(selected_index + 1)
	get_viewport().set_input_as_handled()


func _matches_menu_key(event: InputEventKey, action_name: String, default_key: int) -> bool:
	return (
		event.is_action_pressed(action_name)
		or event.physical_keycode == default_key
		or event.keycode == default_key
	)


func _build_menu() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.035, 0.047, 0.078, 0.94)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -MENU_PANEL_SIZE.x / 2.0
	panel.offset_top = -MENU_PANEL_SIZE.y / 2.0
	panel.offset_right = MENU_PANEL_SIZE.x / 2.0
	panel.offset_bottom = MENU_PANEL_SIZE.y / 2.0
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)

	var title := Label.new()
	title.text = "KEEPY UPPY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "SELECT PLAYERS"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 8)
	content.add_child(subtitle)

	for index in 2:
		var button := Button.new()
		button.custom_minimum_size = MENU_BUTTON_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 9)
		button.pressed.connect(_select_player_count.bind(index + 1))
		content.add_child(button)
		menu_buttons.append(button)

	_refresh_selection()


func _refresh_selection() -> void:
	menu_buttons[0].text = ("> " if selected_index == 0 else "  ") + "1 PLAYER  |  VS BOT"
	menu_buttons[1].text = ("> " if selected_index == 1 else "  ") + "2 PLAYERS"


func _select_player_count(player_count: int) -> void:
	player_2.bot_enabled = player_count == 1
	visible = false
	get_tree().paused = false
