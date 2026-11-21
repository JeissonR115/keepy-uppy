class_name PlayerCountMenu
extends CanvasLayer

signal controls_requested
signal audio_settings_requested

const PLAYER_COUNT_OPTIONS: Array[String] = [
	"1 PLAYER  |  VS BOT",
	"2 PLAYERS",
	"TEST CPU",
	"KEYBOARD CONTROLS",
	"AUDIO SETTINGS",
]
const TEST_CPU_BRAIN_SCRIPT := preload("res://src/models/player/test_cpu_brain.gd")
const NAV_GRAPH_OVERLAY_SCRIPT := preload("res://src/models/player/nav_graph_overlay.gd")
const CPU_DEBUG_PANEL_SCRIPT := preload("res://src/scenes/ui/debug/cpu_debug_panel.gd")
const CPU_TEST_DEBUG_CONTROLLER_SCRIPT := preload("res://src/managers/cpu_test_debug_controller.gd")

@onready var player_2: PlayerController = get_parent().get_node("Arena/Player2")
@onready var match_manager: MatchManager = get_parent().get_node("Arena/MatchManager")
@onready var level_manager: LevelManager = get_parent().get_node("Arena/LevelManager")
@onready var keyboard_navigator: MenuKeyboardNavigator = $KeyboardNavigator
@onready var audio_manager: Node = get_node("/root/AudioManager")
@onready var player_panel: PanelContainer = $Panel
@onready var level_panel: PanelContainer = $LevelPanel
@onready var arena_list: VBoxContainer = $LevelPanel/Content/SelectionRow/ArenaScroll/ArenaList
@onready var arena_preview: TextureRect = $LevelPanel/Content/SelectionRow/ArenaDetails/DetailsContent/ArenaPreview
@onready var preview_fallback: Label = $LevelPanel/Content/SelectionRow/ArenaDetails/DetailsContent/PreviewFallback
@onready var arena_name_label: Label = $LevelPanel/Content/SelectionRow/ArenaDetails/DetailsContent/ArenaName
@onready var arena_metadata_label: Label = $LevelPanel/Content/SelectionRow/ArenaDetails/DetailsContent/ArenaMetadata
@onready var arena_description_label: Label = $LevelPanel/Content/SelectionRow/ArenaDetails/DetailsContent/ArenaDescription
@onready var no_arenas_label: Label = $LevelPanel/Content/SelectionRow/ArenaScroll/ArenaList/NoArenasLabel
@onready var back_level_button: Button = $LevelPanel/Content/BackButton
@onready var menu_buttons: Array[Button] = [
	$Panel/MenuScroll/Margins/Content/OnePlayerButton,
	$Panel/MenuScroll/Margins/Content/TwoPlayersButton,
	$Panel/MenuScroll/Margins/Content/TestCPUButton,
	$Panel/MenuScroll/Margins/Content/ControlsButton,
	$Panel/MenuScroll/Margins/Content/AudioSettingsButton,
]
var level_buttons: Array[Button] = []
var level_options: Array[String] = []
var arena_entries: Array[ArenaData] = []

var selected_index: int = 0
var showing_levels: bool = false
var test_cpu_mode: bool = false


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
		elif index == 2:
			menu_buttons[index].pressed.connect(_select_test_cpu_mode)
		elif index == 3:
			menu_buttons[index].pressed.connect(_open_controls)
		else:
			menu_buttons[index].pressed.connect(_open_audio_settings)
	back_level_button.pressed.connect(_cancel_level_selection)
	_populate_arena_options()
	level_panel.visible = false
	visible = true
	get_tree().paused = true
	_refresh_selection()
	keyboard_navigator.enabled = true


func open_menu() -> void:
	if test_cpu_mode:
		var debug_controller: CPUTestDebugController = get_parent().get_node(
			"CPUTestDebugController"
		)
		debug_controller.exit_test_mode()
		return
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
		if level_buttons.is_empty():
			return
		selected_index = clampi(selected_index, 0, level_buttons.size() - 1)
		MenuNavigationUtils.update_button_selection(
			level_buttons, level_options, selected_index
		)
		_update_arena_details()
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
		if selected_index < arena_entries.size():
			_select_level(arena_entries[selected_index].id)
		else:
			_cancel_level_selection()
	elif selected_index < 2:
		_select_player_count(selected_index + 1)
	elif selected_index == 2:
		_select_test_cpu_mode()
	elif selected_index == 3:
		_open_controls()
	else:
		_open_audio_settings()


func _open_controls() -> void:
	if not visible:
		return
	audio_manager.call("play", "menu_select")
	suspend_menu()
	controls_requested.emit()


func _open_audio_settings() -> void:
	if not visible:
		return
	audio_manager.call("play", "menu_select")
	suspend_menu()
	audio_settings_requested.emit()


func _select_player_count(player_count: int) -> void:
	audio_manager.call("play", "menu_select")
	test_cpu_mode = false
	player_2.bot_enabled = player_count == 1
	_show_arena_selection()


func _select_test_cpu_mode() -> void:
	audio_manager.call("play", "menu_select")
	test_cpu_mode = true
	player_2.bot_enabled = true
	_show_arena_selection()


func _show_arena_selection() -> void:
	showing_levels = true
	selected_index = 0
	player_panel.visible = false
	level_panel.visible = true
	_populate_arena_options()
	_refresh_selection()


func _select_level(level_id: String) -> void:
	if not visible or not showing_levels:
		return
	if not level_manager.select_arena(level_id):
		return
	if test_cpu_mode:
		player_2.bot_enabled = true
		player_2.cpu_controller.set_brain(
			TEST_CPU_BRAIN_SCRIPT.new(player_2, level_manager.active_nav_graph)
		)
	audio_manager.call("play", "menu_select")
	match_manager.restart_match()
	audio_manager.call("play_match_music")
	showing_levels = false
	keyboard_navigator.enabled = false
	visible = false
	get_tree().paused = false
	if test_cpu_mode:
		_start_test_cpu_debug()


func on_test_cpu_exited() -> void:
	test_cpu_mode = false
	player_2.cpu_balloon_contact_suppressed = false
	player_2.cpu_controller.use_local_brain()
	player_2.bot_enabled = false
	var scoreboard := get_parent().get_node("Arena/Scoreboard")
	var winner_overlay := scoreboard.get_node("WinnerOverlay") as Control
	if winner_overlay.visible:
		scoreboard.call("_return_to_player_count_menu")
		return
	var pause_menu := scoreboard.get_node("PauseMenu") as PauseMenu
	if pause_menu.current_screen != PauseMenu.MenuScreen.HIDDEN:
		pause_menu.close_pause()
	open_menu()


func _start_test_cpu_debug() -> void:
	var arena := get_parent().get_node("Arena")
	var overlay: NavGraphOverlay = NAV_GRAPH_OVERLAY_SCRIPT.new()
	overlay.name = "CPUTestNavGraphOverlay"
	arena.add_child(overlay)
	overlay.set_graph(level_manager.active_nav_graph)
	overlay.visible = true
	var debug_panel = CPU_DEBUG_PANEL_SCRIPT.new()
	debug_panel.name = "CPUTestDebugPanel"
	get_parent().add_child(debug_panel)
	var debug_controller = CPU_TEST_DEBUG_CONTROLLER_SCRIPT.new()
	debug_controller.name = "CPUTestDebugController"
	get_parent().add_child(debug_controller)
	debug_controller.configure(arena, player_2, self, overlay, debug_panel)


func _populate_arena_options() -> void:
	arena_entries = level_manager.get_available_arenas()
	for child: Node in arena_list.get_children():
		if child is Button:
			child.free()
	level_buttons.clear()
	level_options.clear()
	no_arenas_label.visible = arena_entries.is_empty()
	for arena: ArenaData in arena_entries:
		var button := Button.new()
		button.custom_minimum_size = Vector2(104.0, 18.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 7)
		button.pressed.connect(_select_level.bind(arena.id))
		arena_list.add_child(button)
		level_buttons.append(button)
		level_options.append(arena.display_name)
	level_buttons.append(back_level_button)
	level_options.append("BACK")
	_update_arena_details()


func _update_arena_details() -> void:
	if arena_entries.is_empty() or selected_index >= arena_entries.size():
		arena_preview.texture = null
		preview_fallback.visible = true
		arena_name_label.text = "NO ARENAS AVAILABLE" if arena_entries.is_empty() else ""
		arena_metadata_label.text = ""
		arena_description_label.text = "Register an ArenaData resource in arena_catalog.tres."
		return
	var arena: ArenaData = arena_entries[selected_index]
	arena_preview.texture = arena.preview_texture
	preview_fallback.visible = arena_preview.texture == null
	arena_name_label.text = arena.display_name
	var size_labels := ["SMALL", "MEDIUM", "LARGE"]
	var size_index := clampi(int(arena.size_classification), 0, size_labels.size() - 1)
	var bounds: Rect2 = arena.playable_bounds
	arena_metadata_label.text = "%s  %d×%d  %d PLAYERS  %s" % [
		size_labels[size_index],
		roundi(bounds.size.x),
		roundi(bounds.size.y),
		arena.recommended_players,
		arena.theme_name.to_upper(),
	]
	arena_description_label.text = arena.description


func _cancel_level_selection() -> void:
	if not visible or not showing_levels:
		return
	audio_manager.call("play", "menu_select")
	showing_levels = false
	selected_index = 0
	player_panel.visible = true
	level_panel.visible = false
	_refresh_selection()
