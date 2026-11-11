extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _positional_sound_count() -> int:
	return root.find_children("*", "AudioStreamPlayer2D", true, false).size()


func _run_test() -> void:
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	current_scene = main_scene
	await process_frame
	var two_players_button: Button = main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	)
	two_players_button.pressed.emit()
	main_scene.get_node("PlayerCountMenu")._select_level("classic")
	var player: PlayerController = main_scene.get_node("Arena/Player1")
	for _frame in range(12):
		await physics_frame
	if not _expect(player.is_on_floor(), "Player was not grounded before the jump sound check."):
		return

	var starting_sounds := _positional_sound_count()
	var jump_key := InputEventKey.new()
	jump_key.physical_keycode = KEY_F
	jump_key.pressed = true
	Input.parse_input_event(jump_key)
	await physics_frame
	await physics_frame
	jump_key.pressed = false
	Input.parse_input_event(jump_key)
	if not _expect(
		_positional_sound_count() == starting_sounds + 1,
		"An actual player jump did not trigger exactly one positional jump sound."
	):
		return

	var after_jump := _positional_sound_count()
	player._perform_wall_jump(-1.0, false)
	if not _expect(
		_positional_sound_count() == after_jump + 1,
		"A wall jump did not trigger a positional jump sound."
	):
		return

	await create_timer(0.2).timeout
	var before_dash := _positional_sound_count()
	var dash_key := InputEventKey.new()
	dash_key.physical_keycode = KEY_G
	dash_key.pressed = true
	Input.parse_input_event(dash_key)
	await physics_frame
	await physics_frame
	if not _expect(
		_positional_sound_count() == before_dash,
		"Dash sound played during the dash freeze instead of at impulse start."
	):
		return
	dash_key.pressed = false
	Input.parse_input_event(dash_key)
	for _frame in range(5):
		await physics_frame
		if _positional_sound_count() > before_dash:
			break
	if not _expect(
		_positional_sound_count() == before_dash + 1,
		"Dash impulse did not trigger one positional dash sound after the freeze."
	):
		return

	player._end_dash()
	await create_timer(0.2).timeout
	player.global_position = Vector2(72.0, 152.0)
	player.velocity = Vector2.ZERO
	player.movement_state = PlayerController.MovementState.NORMAL
	player.ducking = false
	for _frame in range(3):
		await physics_frame
	if not _expect(player.is_on_floor(), "Player did not settle on the floor for footstep checks."):
		return
	player.velocity = Vector2(100.0, 0.0)

	var before_step := _positional_sound_count()
	player._update_footsteps(0.13)
	if not _expect(
		_positional_sound_count() == before_step,
		"A footstep played before 14 pixels of grounded running distance."
	):
		return
	player._update_footsteps(0.01)
	if not _expect(
		_positional_sound_count() == before_step + 1 and is_zero_approx(player.step_distance),
		"A footstep did not play and reset its accumulator at 14 pixels."
	):
		return

	var before_silent_states := _positional_sound_count()
	player.movement_state = PlayerController.MovementState.CLIMB
	player._update_footsteps(0.5)
	player.movement_state = PlayerController.MovementState.NORMAL
	player.ducking = true
	player._update_footsteps(0.5)
	player.ducking = false
	player.velocity.x = 10.0
	player._update_footsteps(0.5)
	if not _expect(
		_positional_sound_count() == before_silent_states,
		"Climbing, ducking, or stationary movement triggered a footstep."
	):
		return

	await create_timer(0.2).timeout
	main_scene.queue_free()
	await process_frame
	print("Jump, wall-jump, post-freeze dash, footstep threshold, and silent movement states verified.")
	quit()
