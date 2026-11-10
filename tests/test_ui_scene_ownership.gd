extends SceneTree


func _initialize() -> void:
	_run_test()


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _run_test() -> void:
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	var player_count_menu: Node = main_scene.get_node("PlayerCountMenu")
	var arena: Node = main_scene.get_node("Arena")
	var scoreboard: Node = arena.get_node("Scoreboard")
	var pause_menu: Node = scoreboard.get_node("PauseMenu")
	var control_settings: Node = scoreboard.get_node("ControlSettings")
	if not _expect(
		player_count_menu.has_node("Panel/MenuScroll/Margins/Content/ControlsButton"),
		"Player-count scene is missing the Keyboard Controls button."
	):
		return

	for node_path: NodePath in [
		"Backdrop",
		"Panel/MenuScroll/Margins/Content/Title",
		"Panel/MenuScroll/Margins/Content/OnePlayerButton",
		"Panel/MenuScroll/Margins/Content/TwoPlayersButton",
		"Panel/MenuScroll/Margins/Content/ControlsButton",
	]:
		if not _expect(
			player_count_menu.has_node(node_path),
			"Player-count scene is missing its authored UI node: %s." % node_path
		):
			return

	for node_path: NodePath in [
		"PausePanel/Content/Title",
		"PausePanel/Content/Options/ResumeButton",
		"PausePanel/Content/Options/RestartButton",
		"PausePanel/Content/Options/ControlsButton",
		"ConfirmationPanel/Content/Options/ConfirmButton",
		"ConfirmationPanel/Content/Options/CancelButton",
	]:
		if not _expect(
			pause_menu.has_node(node_path),
			"Pause-menu scene is missing its authored UI node: %s." % node_path
		):
			return

	for node_path: NodePath in [
		"Backdrop",
		"SettingsPanel/Content/Title",
		"SettingsPanel/Content/ActionScroll/ActionMargins/Columns",
		"SettingsPanel/Content/StatusLabel",
		"SettingsPanel/Content/Buttons/CancelButton",
		"SettingsPanel/Content/Buttons/ResetButton",
		"SettingsPanel/Content/Buttons/CloseButton",
	]:
		if not _expect(
			control_settings.has_node(node_path),
			"Control-settings scene is missing its authored UI node: %s." % node_path
		):
			return

	if not _expect(
		scoreboard.has_node("SetResultPanel/SetResultLabel"),
		"Set-result presentation is not authored in the scoreboard scene."
	):
		return
	if not _expect(
		scoreboard.has_node("WinnerNavigator"),
		"Winner-menu navigation node is not owned by the scoreboard scene."
	):
		return

	main_scene.free()
	print("Menu and HUD layout nodes are owned by their scenes.")
	quit()
