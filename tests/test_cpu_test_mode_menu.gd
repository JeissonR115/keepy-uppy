extends SceneTree

const TEST_CPU_BRAIN := preload("res://src/models/player/test_cpu_brain.gd")
const LOCAL_BRAIN := preload("res://src/models/player/local_brain.gd")


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _run_test() -> void:
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	var menu: PlayerCountMenu = main_scene.get_node("PlayerCountMenu")
	if not _expect(
		main_scene.get_node_or_null("CPUTestDebugPanel") == null
		and main_scene.get_node_or_null("CPUTestDebugPanel/VisibilityButton") == null,
		"Test CPU debug UI was created before entering Test CPU mode."
	):
		return
	if not _expect(
		menu.menu_buttons.size() == 4
		and menu.menu_buttons[2].text.contains("TEST CPU"),
		"Main menu does not offer a Test CPU option."
	):
		return
	menu._select_test_cpu_mode()
	if not _expect(
		menu.showing_levels and menu.test_cpu_mode and menu.player_2.bot_enabled,
		"Test CPU selection did not enter catalog arena selection with Player 2 as CPU."
	):
		return
	menu._select_level("classic")
	await process_frame
	var player: PlayerController = main_scene.get_node("Arena/Player2")
	var debug_panel = main_scene.get_node("CPUTestDebugPanel")
	var visibility_button: Button = debug_panel.visibility_button
	var overlay: NavGraphOverlay = main_scene.get_node_or_null(
		"Arena/CPUTestNavGraphOverlay"
	) as NavGraphOverlay
	if not _expect(
		player.bot_enabled
		and player.cpu_controller.active_brain.get_script() == TEST_CPU_BRAIN
		and overlay != null
		and overlay.visible
		and debug_panel != null
		and visibility_button != null
		and visibility_button.is_inside_tree()
		and main_scene.get_node_or_null("CPUTestDebugController") != null,
		"Test CPU arena selection did not start the autonomous CPU with its debug UI."
	):
		return
	var debugger = main_scene.get_node("CPUTestDebugController")
	menu.open_menu()
	var pause_event := InputEventKey.new()
	pause_event.pressed = true
	pause_event.keycode = KEY_F7
	debugger._input(pause_event)
	if not _expect(
		menu.visible
		and root.get_tree().paused
		and not debugger.is_processing_input()
		and not debugger.is_physics_processing()
		and not debug_panel.visible
		and not visibility_button.is_visible_in_tree()
		and not overlay.visible
		and overlay.graph == null,
		"Returning to the main menu did not immediately deactivate Test CPU visuals and controls."
	):
		return
	await process_frame
	if not _expect(
		menu.visible
		and not menu.test_cpu_mode
		and not player.bot_enabled
		and player.cpu_controller.active_brain.get_script() == LOCAL_BRAIN
		and main_scene.get_node_or_null("CPUTestDebugPanel") == null
		and main_scene.get_node_or_null("CPUTestDebugPanel/VisibilityButton") == null
		and not is_instance_valid(visibility_button)
		and main_scene.get_node_or_null("Arena/CPUTestNavGraphOverlay") == null,
		"Exiting Test CPU did not restore the main menu and normal local brain."
	):
		return
	menu._select_player_count(2)
	menu._select_level("classic")
	await process_frame
	if not _expect(
		not player.bot_enabled
		and player.cpu_controller.active_brain.get_script() == LOCAL_BRAIN
		and main_scene.get_node_or_null("CPUTestDebugPanel") == null
		and main_scene.get_node_or_null("CPUTestDebugPanel/VisibilityButton") == null
		and main_scene.get_node_or_null("CPUTestDebugController") == null
		and main_scene.get_node_or_null("Arena/CPUTestNavGraphOverlay") == null,
		"The ordinary two-player flow retained Test CPU behavior or visualization."
	):
		return
	await _press_and_release_key(KEY_F10)
	if not _expect(
		not menu.visible and not root.get_tree().paused,
		"The Test CPU exit shortcut affected an ordinary two-player match."
	):
		return
	menu.open_menu()
	menu._select_player_count(1)
	menu._select_level("classic")
	await process_frame
	if not _expect(
		player.bot_enabled
		and player.cpu_controller.active_brain.get_script() == LOCAL_BRAIN
		and main_scene.get_node_or_null("CPUTestDebugPanel") == null
		and main_scene.get_node_or_null("CPUTestDebugPanel/VisibilityButton") == null
		and main_scene.get_node_or_null("CPUTestDebugController") == null
		and main_scene.get_node_or_null("Arena/CPUTestNavGraphOverlay") == null,
		"The ordinary one-player bot flow inherited Test CPU behavior or visualization."
	):
		return
	await _press_and_release_key(KEY_F7)
	if not _expect(
		not menu.visible and not root.get_tree().paused,
		"The Test CPU pause shortcut affected an ordinary one-player match."
	):
		return
	print("Test CPU menu flow uses the arena catalog and restores normal modes on exit.")
	quit()


func _press_and_release_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
