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
	match_manager.set_next_server(player_1)

	if not _expect(
		player_1.get_node("PriorityIndicator").visible
		or player_2.get_node("PriorityIndicator").visible,
		"Opening priority was not indicated visually."
	):
		return

	player_1._update_presentation_state(0.0, true, 1.0 / 60.0)
	if not _expect(player_1.visual.animation == "idle", "Idle did not select its sprite animation."):
		return
	player_1.facing_direction = Vector2.LEFT
	player_1._update_presentation_state(0.0, true, 1.0 / 60.0)
	if not _expect(player_1.visual.flip_h, "The body sprite did not mirror when facing left."):
		return
	player_1.facing_direction = Vector2.RIGHT
	player_1._update_presentation_state(0.0, true, 1.0 / 60.0)
	player_1.velocity.x = MovementConstants.MAX_RUN * 0.5
	player_1._update_presentation_state(1.0, true, 1.0 / 60.0)
	if not _expect(player_1.visual.animation == "runSlow", "Slow movement did not select runSlow."):
		return
	player_1.velocity.x = MovementConstants.MAX_RUN
	player_1._update_presentation_state(1.0, true, 1.0 / 60.0)
	if not _expect(player_1.visual.animation == "runFast", "Fast movement did not select runFast."):
		return
	player_1.velocity.x = 0.0
	player_1.velocity.y = -1.0
	player_1._update_presentation_state(0.0, false, 1.0 / 60.0)
	if not _expect(player_1.visual.animation == "dangling", "Airborne rise did not select dangling."):
		return
	player_1.velocity.y = 1.0
	player_1._update_presentation_state(0.0, false, 1.0 / 60.0)
	if not _expect(player_1.visual.animation == "fall", "Normal descent did not select fall."):
		return
	player_1.velocity.y = MovementConstants.FAST_MAX_FALL
	player_1._update_presentation_state(0.0, false, 1.0 / 60.0)
	if not _expect(player_1.visual.animation == "fallFast", "Fast descent did not select fallFast."):
		return
	player_1.velocity.y = MovementConstants.CLIMB_UP_SPEED
	player_1.movement_state = PlayerController.MovementState.CLIMB
	player_1._update_presentation_state(0.0, false, 1.0 / 60.0)
	if not _expect(player_1.visual.animation == "climbup", "Climb entry did not play climbup."):
		return
	player_1.presentation._on_body_animation_finished()
	player_1._update_presentation_state(0.0, false, 1.0 / 60.0)
	if not _expect(
		player_1.visual.animation == "climbPull"
		and player_1.action_effect.animation == "climb",
		"Upward climbing did not select its loop and entry effect."
	):
		return
	player_1.velocity.y = MovementConstants.CLIMB_DOWN_SPEED
	player_1._update_presentation_state(0.0, false, 1.0 / 60.0)
	if not _expect(player_1.visual.animation == "climbPush", "Downward climbing did not select climbPush."):
		return
	player_1.movement_state = PlayerController.MovementState.NORMAL
	player_1.velocity.y = 1.0
	player_1.wall_slide_timer = 0.1
	player_1._update_presentation_state(0.0, false, 1.0 / 60.0)
	if not _expect(player_1.visual.animation == "wallslide", "Wall slide did not select wallslide."):
		return
	player_1.wall_slide_timer = 0.0
	player_1.velocity.y = -1.0
	player_1._update_presentation_state(0.0, false, 1.0 / 60.0, true)
	if not _expect(
		player_1.visual.animation == "flip"
		and player_1.action_effect.animation == "jump",
		"Jump did not trigger the body and action-effect one-shots."
	):
		return
	player_1._update_presentation_state(0.0, false, 1.0 / 60.0)
	if not _expect(
		player_1.visual.animation == "flip"
		and player_1.action_effect.animation == "jump",
		"A held airborne state restarted a one-shot animation."
	):
		return
	player_1.movement_state = PlayerController.MovementState.DASH
	player_1._update_presentation_state(0.0, false, 1.0 / 60.0)
	if not _expect(player_1.visual.animation == "dash", "Dash did not take priority over a jump one-shot."):
		return
	player_1.player_bumped.emit(player_1, player_2, false)
	if not _expect(
		player_1.action_effect.animation == "danger"
		and player_1.presentation.effect_priority == 3,
		"The existing bump event did not override lower-priority action effects."
	):
		return
	var danger_frame: int = player_1.action_effect.frame
	player_1.presentation.play_effect_once("danger", 3)
	player_1.presentation.play_effect_once("jump", 2)
	if not _expect(
		player_1.action_effect.animation == "danger"
		and player_1.action_effect.frame == danger_frame,
		"A held or lower-priority action restarted the danger one-shot."
	):
		return
	player_1.presentation._on_effect_animation_finished()
	player_1.movement_state = PlayerController.MovementState.NORMAL
	player_1.velocity = Vector2.ZERO
	player_1._update_presentation_state(0.0, true, 1.0 / 60.0)
	if not _expect(
		player_1.action_effect.animation == "still"
		and player_1.action_effect.visible,
		"Completing an action effect did not restore the idle effect loop."
	):
		return
	player_2.facing_direction = Vector2.LEFT
	player_2.velocity.y = -1.0
	player_2._update_presentation_state(0.0, false, 1.0 / 60.0, true)
	if not _expect(
		player_2.visual.animation == "flip"
		and player_2.visual.flip_h
		and player_2.action_effect.flip_h
		and player_2.action_effect.animation == "jump"
		and player_2.action_effect.modulate == PlayerPresentationController.PLAYER_TWO_TINT,
		"Player 2's action animation, facing, or orange effect tint did not match player 1's."
	):
		return

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

	print("Player sprite states and effects, visible cape, priority indicator, and balloon impact flash verified.")
	quit()
