extends SceneTree


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

	var two_players_button: Button = main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	)
	two_players_button.pressed.emit()
	await process_frame

	var arena: Node = main_scene.get_node("Arena")
	var cpu_player: PlayerController = arena.get_node("Player2")
	var manager: MatchManager = arena.get_node("MatchManager")
	var cpu: CPUController = cpu_player.get_node("CPUController")
	cpu_player.bot_enabled = true

	manager.expected_balloon_player = cpu_player
	if not _expect(
		cpu.refresh_state() == CPUController.State.CPU_TURNO_PROPIO,
		"CPU did not enter its own-turn state when it was expected to touch the balloon."
	):
		return

	manager.expected_balloon_player = arena.get_node("Player1")
	if not _expect(
		cpu.refresh_state() == CPUController.State.CPU_TURNO_RIVAL,
		"CPU did not enter rival-turn state when the other player was expected to touch."
	):
		return

	cpu_player.bot_enabled = false
	if not _expect(
		cpu.refresh_state() == CPUController.State.INACTIVE,
		"Disabled CPU did not enter the inactive state."
	):
		return

	cpu_player.bot_enabled = true
	manager.match_state = MatchManager.MatchState.ROUND_OVER
	if not _expect(
		cpu.refresh_state() == CPUController.State.INACTIVE,
		"CPU remained active while the match was not accepting gameplay."
	):
		return

	print("CPU state selection and inactive conditions verified.")
	quit()
