extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _hair_points(hair: Node) -> PackedVector2Array:
	return (hair.get_node("HairViewport/Strand") as Line2D).points


func _step_hair(
	hair: Node,
	velocity: Vector2,
	facing: Vector2,
	dashing: bool = false,
	dash_direction: Vector2 = Vector2.ZERO,
	frozen: bool = false
) -> void:
	if not frozen and velocity.is_finite():
		(hair.get_parent() as Node2D).global_position += velocity / 60.0
	hair.call("simulate", 1.0 / 60.0, velocity, facing, dashing, dash_direction, frozen)


func _run_test() -> void:
	var main_scene := (load("res://src/scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main_scene)
	await process_frame
	var player_1: PlayerController = main_scene.get_node("Arena/Player1")
	var player_2: PlayerController = main_scene.get_node("Arena/Player2")
	var hair_1: Node = player_1.get_node_or_null("PlayerHair")
	var hair: Node = player_2.get_node_or_null("PlayerHair")
	if not _expect(
		hair_1 != null
		and hair != null
		and player_1.get_node_or_null("Cape") == null
		and player_2.get_node_or_null("Cape") == null
		and hair_1.find_children("*", "CollisionObject2D", true, false).is_empty()
		and hair.find_children("*", "CollisionObject2D", true, false).is_empty()
		and hair.get_node("HairViewport/Strand") is Line2D
		and hair.get_node("HairViewport/HairBase") is Sprite2D
		and hair.get_node("HairOutput") is Sprite2D
		and hair.get_node("HairPivot") is Marker2D
		and (hair.get_node("HairViewport") as SubViewport).size == Vector2i(24, 24)
		and hair.get_node_or_null("StrandA") == null
		and hair.get_node_or_null("StrandB") == null,
		"Both players must use one cosmetic motion-trail line without collision nodes."
	):
		return
	var strand := hair.get_node("HairViewport/Strand") as Line2D
	if not _expect(
		strand.width == 6.0
		and strand.width_curve != null
		and not strand.antialiased
		and strand.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST
		and hair.z_index < player_2.visual.z_index
		and hair_1.z_index < player_1.visual.z_index,
		"Hair trail style, visible cap, or draw order is incorrect."
	):
		return
	for point in strand.points:
		if not _expect(point == point.round(), "Hair trail contains subpixel coordinates."):
			return
	var initial := _hair_points(hair)
	if not _expect(
		initial.size() == 6
		and initial[0].is_equal_approx(initial[5])
		and initial[5] == Vector2(12.0, 12.0),
		"Hair trail did not initialize at the center of its pixel viewport."
	):
		return
	player_2.set_physics_process(false)
	hair.call("set_motion_state", Vector2(60.0, 0.0), Vector2.RIGHT, false, Vector2.ZERO, false)
	player_2.global_position += Vector2(2.0, 0.0)
	hair.call("_process", 1.0 / 60.0)
	var render_sample := _hair_points(hair)
	if not _expect(render_sample != initial, "Hair history did not sample on a render frame."):
		return
	hair.call("set_motion_state", Vector2(0.0, -250.0), Vector2.RIGHT, true, Vector2.RIGHT, true)
	var frozen_render_sample := _hair_points(hair)
	player_2.global_position += Vector2.UP
	hair.call("_process", 1.0 / 60.0)
	if not _expect(_hair_points(hair) == frozen_render_sample,
		"Hair history advanced during the local dash freeze on a render frame."):
		return
	player_2.set_physics_process(true)
	hair.call("reset_simulation")
	for player_hair: Node in [hair_1, hair]:
		for _frame in range(12):
			_step_hair(player_hair, Vector2(130.0, 0.0), Vector2.RIGHT)
		var player_points := _hair_points(player_hair)
		if not _expect(
			player_points.size() == 6 and player_points[0].x < player_points[5].x,
			"P1/P2 hair did not independently track movement."
		):
			return
		player_hair.call("reset_simulation")

	for _frame in range(24):
		_step_hair(hair, Vector2(130.0, 0.0), Vector2.RIGHT)
	var moving_right := _hair_points(hair)
	if not _expect(
		moving_right[0].x < moving_right[5].x
		and moving_right[5].y == 12.0,
		"Hair trail did not follow motion from the head anchor."
	):
		return
	for index in range(1, moving_right.size()):
		if not _expect(
			absf(moving_right[index].x - moving_right[index - 1].x) <= 2.0
			and absf(moving_right[index].y - moving_right[index - 1].y) <= 2.0,
			"Hair trail exceeded its two-pixel step constraint."
		):
			return

	for _frame in range(24):
		_step_hair(hair, Vector2(-130.0, 0.0), Vector2.LEFT)
	var moving_left := _hair_points(hair)
	if not _expect(
		moving_left[0].x > moving_left[5].x
		and moving_left[5].x == 12.0,
		"Hair trail did not mirror its motion when the player turned: %s." % [moving_left]
	):
		return

	for _frame in range(24):
		_step_hair(hair, Vector2.ZERO, Vector2.LEFT)
	var resting := _hair_points(hair)
	for index in range(1, resting.size()):
		if not _expect(
			absf(resting[index].x - resting[index - 1].x) <= 2.0
			and absf(resting[index].y - resting[index - 1].y) <= 2.0,
			"Idle extension exceeded the bounded reference constraint."
		):
			return
	if not _expect(resting[5].y > 12.0 and resting[5].y <= 18.0,
		"Idle hair did not extend downward by the bounded fakeHairCount steps."):
		return

	var before_frozen := _hair_points(hair)
	_step_hair(hair, Vector2(0.0, -250.0), Vector2.RIGHT, true, Vector2.RIGHT, true)
	if not _expect(_hair_points(hair) == before_frozen, "Hair trail advanced during dash freeze."):
		return
	for _frame in range(12):
		_step_hair(hair, Vector2(360.0, 0.0), Vector2.RIGHT, true, Vector2.RIGHT)
	var dashing := _hair_points(hair)
	if not _expect(
		dashing[0].x < dashing[5].x
		and dashing[5].y == 12.0,
		"Dash hair trail did not stay behind the player at head height."
	):
		return

	hair.call("reset_simulation")
	var reset_points := _hair_points(hair)
	if not _expect(
		reset_points.size() == 6 and reset_points[0] == reset_points[5],
		"Hair trail did not reset to the player after a teleport or respawn."
	):
		return
	for player_hair: Node in [hair_1, hair]:
		var body := player_hair.get_parent().get_node("Visual") as AnimatedSprite2D
		for animation_name: String in body.sprite_frames.get_animation_names():
			body.animation = animation_name
			var count := body.sprite_frames.get_frame_count(animation_name)
			for frame_index in count:
				body.frame = frame_index
				player_hair.call("simulate", 1.0 / 60.0, Vector2.ZERO, Vector2.RIGHT,
					false, Vector2.ZERO, false)
				var right_pose: Vector2 = player_hair.get_node("HairPivot").position
				player_hair.call("simulate", 1.0 / 60.0, Vector2.ZERO, Vector2.LEFT,
					false, Vector2.ZERO, false)
				var left_pose: Vector2 = player_hair.get_node("HairPivot").position
				if not _expect(
					is_equal_approx(absf(right_pose.x), absf(left_pose.x))
					and is_equal_approx(right_pose.y, left_pose.y)
					and absf(right_pose.x) <= 3.0
					and right_pose.y >= -12.0 and right_pose.y <= -10.0,
					"Hair pose did not mirror cleanly for %s frame %s." % [animation_name, frame_index]
				):
					return
		player_hair.call("reset_state")
	_step_hair(hair, Vector2(INF, 0.0), Vector2.RIGHT)
	if not _expect(_hair_points(hair) == reset_points, "Hair trail did not recover safely from invalid movement data."):
		return
	for player_hair: PlayerHair in [hair_1, hair]:
		var body := player_hair.get_parent().get_node("Visual") as AnimatedSprite2D
		player_hair.call("update_state", 1.0 / 60.0, false, false, body)
		for _frame in range(60):
			player_hair.call("update_state", 1.0 / 60.0, false, true, body)
		if not _expect(player_hair.trail_color.is_equal_approx(PlayerHair.DASH_COLOR),
			"Dash did not transition both players' hair to reference blue."):
			return
		player_hair.call("update_state", 1.0 / 60.0, true, false, body)
		if not _expect(player_hair.trail_color == Color.WHITE,
			"Landing did not trigger the white hair flash for both players."):
			return
		for _frame in range(60):
			player_hair.call("update_state", 1.0 / 60.0, true, false, body)
		if not _expect(player_hair.trail_color.is_equal_approx(PlayerHair.DEFAULT_COLOR),
			"Grounded hair did not return to its default color for both players."):
			return
		player_hair.call("reset_state")
		if not _expect(player_hair.trail_color == PlayerHair.DEFAULT_COLOR,
			"Hair reset did not restore its default color for both players."):
			return
	print("Both players use the pixel motion-trail hair from the Celeste movement reference.")
	quit()
