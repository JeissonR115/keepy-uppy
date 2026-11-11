extends SceneTree

const MovementConstants = preload("res://src/models/player/player_movement_constants.gd")


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
	if not _expect(
		player_1.visual.color == player_1.idle_color,
		"Idle state did not restore the player rectangle's base color."
	):
		return
	player_1._update_visual_state(1.0, true, 1.0 / 60.0)
	if not _expect(
		player_1.visual.color == player_1.run_color,
		"Running state did not change the player rectangle color."
	):
		return
	player_1.velocity.x = MovementConstants.MAX_RUN
	player_1._update_visual_state(1.0, true, 1.0 / 60.0)
	if not _expect(
		player_1.visual.color == player_1.run_color,
		"Fast running did not preserve the run color."
	):
		return
	player_1.velocity.x = 0.0
	player_1.velocity.y = -1.0
	player_1._update_visual_state(0.0, false, 1.0 / 60.0)
	if not _expect(
		player_1.visual.color == player_1.rise_color,
		"Rising state did not select the rising color."
	):
		return
	player_1.velocity.y = 1.0
	player_1._update_visual_state(0.0, false, 1.0 / 60.0)
	if not _expect(
		player_1.visual.color == player_1.fall_color,
		"Falling state did not select the falling color."
	):
		return
	player_1.velocity.y = MovementConstants.MAX_FALL
	player_1._update_visual_state(0.0, false, 1.0 / 60.0)
	if not _expect(
		player_1.visual.color == player_1.fall_color,
		"Fast falling did not preserve the falling color."
	):
		return
	player_1.velocity.y = 0.0
	player_1.movement_state = PlayerController.MovementState.CLIMB
	player_1.velocity.y = MovementConstants.CLIMB_UP_SPEED
	player_1._update_visual_state(0.0, false, 1.0 / 60.0)
	if not _expect(
		player_1.visual.color == player_1.run_color,
		"Climbing did not select the climbing color."
	):
		return
	player_1.movement_state = PlayerController.MovementState.NORMAL
	player_1.velocity.y = 1.0
	player_1.wall_slide_timer = 0.1
	player_1._update_visual_state(0.0, false, 1.0 / 60.0)
	if not _expect(
		player_1.visual.color == player_1.fall_color,
		"Wall sliding did not select the falling color."
	):
		return
	player_1.wall_slide_timer = 0.0
	player_1.is_dashing = true
	player_1._update_visual_state(0.0, true, 1.0 / 60.0)
	if not _expect(
		player_1.visual.color == player_1.dash_color,
		"Dash state did not select the dash color."
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

	var toucher_color := Color(0.2, 0.8, 1.0)
	balloon._flash_impact(toucher_color)
	if not _expect(
		balloon.visual.color == Color.WHITE,
		"Balloon impact feedback did not flash."
	):
		return

	print("Player rectangle states, visible cape, priority indicator, and balloon impact flash verified.")
	quit()
