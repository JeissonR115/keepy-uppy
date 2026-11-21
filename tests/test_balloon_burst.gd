extends SceneTree

var ground_touch_count: int = 0
var spike_touch_count: int = 0


func _initialize() -> void:
	call_deferred("_run_test")


func _on_ground_touched() -> void:
	ground_touch_count += 1


func _on_spikes_touched() -> void:
	spike_touch_count += 1


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
	main_scene.get_node("PlayerCountMenu")._select_level("classic")
	await process_frame

	var arena: Node = main_scene.get_node("Arena")
	var balloon: RigidBody2D = arena.get_node("Balloon")
	var manager: Node = arena.get_node("MatchManager")
	balloon.ground_touched.connect(_on_ground_touched)
	balloon.spikes_touched.connect(_on_spikes_touched)
	var explosion := balloon.get_node("GroundBurst") as AnimatedSprite2D
	var explosion_frames := explosion.sprite_frames
	if not _expect(
		explosion_frames.has_animation("explode")
		and explosion_frames.get_frame_count("explode") == 9
		and not explosion_frames.get_animation_loop("explode")
		and is_equal_approx(explosion_frames.get_animation_speed("explode"), 12.0),
		"Balloon explosion animation is missing, looping, or has the wrong frame count/speed."
	):
		return
	for frame_index in explosion_frames.get_frame_count("explode"):
		var frame_texture := explosion_frames.get_frame_texture(
			"explode", frame_index
		) as AtlasTexture
		var expected_region := Rect2(192 + frame_index * 64, 0, 64, 64)
		if not _expect(
			frame_texture != null
			and frame_texture.region == expected_region
			and frame_texture.get_size() == Vector2(64, 64),
			"Explosion frame %s did not use the expected 64x64 atlas region." % frame_index
		):
			return

	manager.round_intermission = 1.0
	balloon.get_node("PlayerContactArea").monitoring = false
	manager.set_next_server(arena.get_node("Player1"))
	manager.last_valid_toucher = arena.get_node("Player2")
	manager.round_has_valid_contact = true
	balloon.reset_round(Vector2(40, 150))
	for _frame in range(40):
		if balloon.ground_contact_reported:
			break
		await physics_frame
	if not _expect(
		balloon.ground_contact_reported
		and explosion.visible
		and not balloon.visual.visible
		and not balloon.get_node("String").visible
		and is_zero_approx(balloon.linear_velocity.length()),
		"Scoring-floor contact did not immediately hide and stop the balloon while showing the explosion."
	):
		return
	await process_frame
	if not _expect(
		manager.match_state == manager.MatchState.ROUND_OVER
		and manager.player_2_score == 1
		and ground_touch_count == 1
		and balloon.freeze
		and (balloon.get_node("CollisionShape2D") as CollisionShape2D).disabled
		and not (balloon.get_node("PlayerContactArea") as Area2D).monitoring,
		"The burst delayed floor scoring or failed to end the point."
	):
		return
	var scoring_ground: Node = get_first_node_in_group("scoring_ground")
	if not _expect(scoring_ground != null, "The active level has no scoring ground."):
		return
	balloon._on_body_entered(scoring_ground)
	if not _expect(
		ground_touch_count == 1 and explosion.is_playing(),
		"Repeated floor contact emitted another event or restarted the explosion."
	):
		return
	await explosion.animation_finished
	if not _expect(
		manager.player_2_score == 1
		and ground_touch_count == 1
		and not explosion.visible,
		"Repeated floor contact scored twice or the burst did not finish."
	):
		return
	for _frame in range(90):
		if manager.match_state == manager.MatchState.ACTIVE and not balloon.ground_contact_reported:
			break
		await physics_frame
	if not _expect(
		manager.match_state == manager.MatchState.ACTIVE
		and not balloon.ground_contact_reported
		and not explosion.visible
		and not balloon.freeze
		and balloon.visual.visible
		and balloon.get_node("String").visible
		and not (balloon.get_node("CollisionShape2D") as CollisionShape2D).disabled,
		"The burst or ground-contact guard did not reset for the next point."
	):
		return

	balloon.arm_for_serve()
	balloon.linear_velocity = Vector2(30.0, 40.0)
	balloon.explode_on_spikes()
	if not _expect(
		spike_touch_count == 1
		and ground_touch_count == 1
		and balloon.spike_contact_reported
		and balloon.ground_contact_reported
		and not balloon.visual.visible
		and not balloon.get_node("String").visible
		and explosion.visible
		and is_zero_approx(balloon.linear_velocity.length()),
		"Spike impact did not hide and stop the balloon while playing the shared explosion."
	):
		return
	await process_frame
	if not _expect(
		balloon.freeze
		and (balloon.get_node("CollisionShape2D") as CollisionShape2D).disabled
		and not (balloon.get_node("PlayerContactArea") as Area2D).monitoring,
		"Spike impact did not disable balloon collision and player contacts."
	):
		return
	for _frame in range(7):
		await physics_frame
	var frame_before_duplicate := explosion.frame
	balloon.explode_on_spikes()
	if not _expect(
		spike_touch_count == 1
		and ground_touch_count == 1
		and explosion.frame == frame_before_duplicate,
		"Repeated spike contact emitted another event or restarted the explosion."
	):
		return
	await explosion.animation_finished
	if not _expect(
		not explosion.visible and spike_touch_count == 1 and ground_touch_count == 1,
		"The shared spike explosion did not finish exactly once."
	):
		return
	for _frame in range(90):
		if manager.match_state == manager.MatchState.ACTIVE and not balloon.ground_contact_reported:
			break
		await physics_frame
	if not _expect(
		manager.match_state == manager.MatchState.ACTIVE
		and not balloon.ground_contact_reported
		and not balloon.spike_contact_reported
		and not balloon.freeze
		and balloon.visual.visible
		and balloon.get_node("String").visible
		and not (balloon.get_node("CollisionShape2D") as CollisionShape2D).disabled
		and not explosion.visible,
		"Spike impact state was not cleared when the next round reset."
	):
		return

	print("Shared floor/spike explosion, immediate hiding, duplicate suppression, and reset verified.")
	quit()
