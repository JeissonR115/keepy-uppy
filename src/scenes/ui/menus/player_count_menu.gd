class_name PlayerCountMenu
extends CanvasLayer

const MENU_PANEL_SIZE := Vector2(196.0, 104.0)
const MENU_BUTTON_SIZE := Vector2(152.0, 20.0)

var selected_index: int = 0
var menu_buttons: Array[Button] = []
var player_2: PlayerController
var match_manager: MatchManager
var restart_match_on_selection: bool = false
var keyboard_navigator: MenuKeyboardNavigator
var menu_scroll: ScrollContainer


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	player_2 = get_parent().get_node("Arena/Player2")
	match_manager = get_parent().get_node("Arena/MatchManager")
	keyboard_navigator = MenuKeyboardNavigator.new()
	add_child(keyboard_navigator)
	keyboard_navigator.moved.connect(_move_selection)
	keyboard_navigator.confirmed.connect(_confirm_selection)
	get_tree().paused = true
	_build_menu()
	keyboard_navigator.enabled = true


func open_menu() -> void:
	selected_index = 0
	_refresh_selection()
	restart_match_on_selection = true
	visible = true
	keyboard_navigator.enabled = true
	get_tree().paused = true


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

	menu_scroll = ScrollContainer.new()
	menu_scroll.name = "MenuScroll"
	menu_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.follow_focus = true
	panel.add_child(menu_scroll)
	var menu_margins := MarginContainer.new()
	menu_margins.add_theme_constant_override("margin_left", 6)
	menu_margins.add_theme_constant_override("margin_right", 6)
	menu_margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_scroll.add_child(menu_margins)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	menu_margins.add_child(content)

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
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 9)
		button.pressed.connect(_select_player_count.bind(index + 1))
		content.add_child(button)
		menu_buttons.append(button)

	_refresh_selection()


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
