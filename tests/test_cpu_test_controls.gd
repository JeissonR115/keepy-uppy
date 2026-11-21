extends SceneTree

const CPU_TEST_DEBUG_CONTROLLER := preload("res://src/managers/cpu_test_debug_controller.gd")

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
	menu._select_test_cpu_mode()
	menu._select_level("classic")
	await process_frame
	var controller = main_scene.get_node("CPUTestDebugController")
	var panel = main_scene.get_node("CPUTestDebugPanel")
	var overlay: NavGraphOverlay = main_scene.get_node("Arena/CPUTestNavGraphOverlay")
	var original_scale := Engine.time_scale
	if not _expect(
		not root.get_tree().paused,
		"Test CPU mode should start with an active simulation."
	):
		return
	if not _expect(
		panel.options_panel.visible
		and panel.visibility_button.visible
		and panel.visibility_button.text == "HIDE",
		"Debug options should start visible with an available hide button."
	):
		return
	panel.visibility_button.pressed.emit()
	if not _expect(
		not panel.options_panel.visible
		and panel.visibility_button.visible
		and panel.visibility_button.text == "SHOW",
		"Hiding debug options should leave an available show button."
	):
		return
	panel.visibility_button.pressed.emit()
	if not _expect(
		panel.options_panel.visible and panel.visibility_button.text == "HIDE",
		"Debug options did not return when the show button was activated."
	):
		return
	panel._on_control_pressed("pause")
	if not _expect(root.get_tree().paused, "Pause control did not pause the simulation."):
		return
	var physics_frames_before := Engine.get_physics_frames()
	panel._on_control_pressed("step")
	if not _expect(not root.get_tree().paused, "Single-step did not briefly resume physics."):
		return
	await physics_frame
	await process_frame
	if not _expect(
		root.get_tree().paused
		and Engine.get_physics_frames() == physics_frames_before + 1,
		"Single-step did not advance exactly one physics tick and pause again."
	):
		return
	panel._on_control_pressed("slow")
	if not _expect(
		is_equal_approx(
			Engine.time_scale,
			original_scale * CPU_TEST_DEBUG_CONTROLLER.SLOW_MOTION_SCALE
		),
		"Slow-motion control did not reduce the engine time scale."
	):
		return
	panel._on_layer_toggled(false, "target")
	panel.visibility_button.pressed.emit()
	if not _expect(
		not panel.options_panel.visible
		and root.get_tree().paused
		and is_equal_approx(
			Engine.time_scale,
			original_scale * CPU_TEST_DEBUG_CONTROLLER.SLOW_MOTION_SCALE
		)
		and not overlay.show_target
		and overlay.show_trajectory,
		"Hiding debug options changed pause, time scale or visualization layers."
	):
		return
	panel.visibility_button.pressed.emit()
	if not _expect(
		panel.options_panel.visible
		and root.get_tree().paused
		and is_equal_approx(
			Engine.time_scale,
			original_scale * CPU_TEST_DEBUG_CONTROLLER.SLOW_MOTION_SCALE
		)
		and not overlay.show_target
		and overlay.show_trajectory,
		"Showing debug options changed pause, time scale or visualization layers."
	):
		return
	panel._on_control_pressed("slow")
	if not _expect(
		is_equal_approx(Engine.time_scale, original_scale),
		"Slow-motion toggle did not restore the prior time scale."
	):
		return
	if not _expect(not overlay.show_target and overlay.show_trajectory, "Debug layer controls are not independent."):
		return
	controller.exit_test_mode()
	await process_frame
	if not _expect(
		menu.visible
		and root.get_tree().paused
		and is_equal_approx(Engine.time_scale, original_scale),
		"Exiting Test CPU did not restore time scale and leave the main menu paused."
	):
		return
	print("Test CPU pause, one-tick stepping, slow motion, layer toggles and exit controls passed.")
	quit()
