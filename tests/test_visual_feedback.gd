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

	var arena: Node = main_scene.get_node("Arena")
	var player_1: CharacterBody2D = arena.get_node("Player1")
	var player_2: CharacterBody2D = arena.get_node("Player2")
	var balloon: RigidBody2D = arena.get_node("Balloon")
	var match_manager: Node = arena.get_node("MatchManager")

	if not _expect(
		player_1.get_node("PriorityIndicator").visible
		or player_2.get_node("PriorityIndicator").visible,
		"Opening priority was not indicated visually."
	):
		return

	player_1._update_visual_state(0.0, true, 1.0 / 60.0)
	var idle_color: Color = player_1.visual.color
	player_1._update_visual_state(1.0, true, 1.0 / 60.0)
	if not _expect(player_1.visual.color != idle_color, "Running state did not change the player visual."):
		return
	player_1.velocity.y = -1.0
	player_1._update_visual_state(0.0, false, 1.0 / 60.0)
	var rise_color: Color = player_1.visual.color
	if not _expect(rise_color != idle_color, "Rising state did not change the player visual."):
		return
	player_1.velocity.y = 1.0
	player_1._update_visual_state(0.0, false, 1.0 / 60.0)
	if not _expect(player_1.visual.color != rise_color, "Falling state did not differ from rising."):
		return
	player_1.is_dashing = true
	player_1._update_visual_state(0.0, true, 1.0 / 60.0)
	if not _expect(
		player_1.visual.color == player_1.dash_color,
		"Dash state did not show its visual treatment."
	):
		return
	player_1.is_dashing = false

	var previous_priority: CharacterBody2D = match_manager.priority_player
	var next_priority := player_2 if previous_priority == player_1 else player_1
	match_manager.set_next_server(next_priority)
	if not _expect(
		next_priority.get_node("PriorityIndicator").visible
		and not previous_priority.get_node("PriorityIndicator").visible,
		"Priority change did not move the visual indicator."
	):
		return

	balloon._flash_impact()
	if not _expect(
		balloon.visual.color == Color.WHITE,
		"Balloon impact feedback did not flash."
	):
		return
	await create_timer(0.25).timeout
	if not _expect(
		balloon.visual.color.is_equal_approx(balloon.default_visual_color),
		"Balloon impact flash did not return to its base color."
	):
		return

	print("Player movement states, dash trail, priority indicator, and balloon flash verified.")
	quit()
