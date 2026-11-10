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
	var two_players_button: Button = main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	)
	two_players_button.pressed.emit()

	var player: PlayerController = main_scene.get_node("Arena/Player1")
	var other_player: PlayerController = main_scene.get_node("Arena/Player2")
	var cape: PlayerCape = player.get_node("Cape")
	var other_cape: PlayerCape = other_player.get_node("Cape")
	var fill: Polygon2D = cape.get_node("Polygon2D")
	var outline: Line2D = cape.get_node("Line2D")
	var other_fill: Polygon2D = other_cape.get_node("Polygon2D")
	var anchor_a: Marker2D = player.get_node("CapeAnchors/AnchorA")
	var anchor_b: Marker2D = player.get_node("CapeAnchors/AnchorB")

	for _frame in range(30):
		await physics_frame
	if not _expect(
		cape.top_level
		and cape.initialized
		and cape.positions.size() == MovementConstants.CAPE_ROWS * 2
		and cape.get_parent() == player
		and cape.z_index < player.visual.z_index
		and outline.closed,
		"Cape scene was not player-owned, top-level, initialized, and layered behind the player."
	):
		return
	if not _expect(
		cape.positions[0].is_equal_approx(anchor_a.global_position)
		and cape.positions[MovementConstants.CAPE_ROWS].is_equal_approx(anchor_b.global_position),
		"Cape's two pinned rows did not stay attached to their shoulder anchors."
	):
		return
	if not _expect(
		fill.polygon.size() == MovementConstants.CAPE_ROWS * 2
		and outline.points.size() == fill.polygon.size(),
		"Cape fill and outline did not render the complete two-column mesh."
	):
		return
	var base_color: Color = player.idle_color
	var other_player_cape_color: Color = other_fill.color
	if not _expect(
		is_equal_approx(fill.color.h, base_color.h)
		and (
			fill.color.s >= MovementConstants.CAPE_VIVID_SATURATION_MIN
			or is_equal_approx(fill.color.s, MovementConstants.CAPE_VIVID_SATURATION_MIN)
		)
		and is_equal_approx(fill.color.v, MovementConstants.CAPE_VIVID_VALUE_MIN)
		and is_equal_approx(fill.color.a, 1.0)
		and outline.default_color.is_equal_approx(
			fill.color.darkened(MovementConstants.CAPE_OUTLINE_DARKEN)
		),
		"Available dash did not produce an opaque, vivid cape and darkened outline."
	):
		return

	player.global_position = Vector2(120, 80)
	player.velocity = Vector2.ZERO
	Input.action_press("player_1_dash")
	for _frame in range(12):
		await physics_frame
		if not player.dash_available:
			break
	Input.action_release("player_1_dash")
	var muted_color := player.get_cape_color()
	if not _expect(
		not player.dash_available
		and player.dash_freeze_timer > 0.0
		and fill.visible
		and is_equal_approx(fill.color.h, base_color.h)
		and is_equal_approx(fill.color.s, base_color.s * MovementConstants.CAPE_DULL_SATURATION_MULT)
		and is_equal_approx(fill.color.v, base_color.v * MovementConstants.CAPE_DULL_VALUE_MULT)
		and is_equal_approx(fill.color.a, 1.0)
		and outline.default_color.is_equal_approx(
			fill.color.darkened(MovementConstants.CAPE_OUTLINE_DARKEN)
		),
		"Spending dash did not immediately produce the opaque, muted cape palette."
	):
		return
	if not _expect(
		other_fill.color.is_equal_approx(other_player_cape_color),
		"Spending Player 1's dash changed Player 2's cape color."
	):
		return
	for _frame in range(24):
		await physics_frame
		if not player.is_dashing and player.dash_freeze_timer <= 0.0:
			break
	if not _expect(
		not player.dash_available and fill.color.is_equal_approx(muted_color),
		"Spent cape color changed before the player landed."
	):
		return
	player.global_position = Vector2(120, 152)
	player.velocity = Vector2.ZERO
	for _frame in range(3):
		await physics_frame
	if not _expect(
		player.dash_available
		and is_equal_approx(fill.color.s, MovementConstants.CAPE_VIVID_SATURATION_MIN)
		and is_equal_approx(fill.color.v, MovementConstants.CAPE_VIVID_VALUE_MIN)
		and other_fill.color.is_equal_approx(other_player_cape_color),
		"Landing did not restore only the landing player's vivid cape."
	):
		return

	for column in 2:
		var column_length := 0.0
		var start := column * MovementConstants.CAPE_ROWS
		for row in range(MovementConstants.CAPE_ROWS - 1):
			var segment_length := cape.positions[start + row].distance_to(
				cape.positions[start + row + 1]
			)
			if not _expect(
				absf(segment_length - MovementConstants.CAPE_SEGMENT) < 0.25,
				"Cape segment length drifted beyond the constraint tolerance."
			):
				return
			column_length += segment_length
		if not _expect(
			column_length >= MovementConstants.CAPE_SEGMENT
			* (MovementConstants.CAPE_ROWS - 1) * 0.85
			and column_length <= MovementConstants.CAPE_SEGMENT
			* (MovementConstants.CAPE_ROWS - 1) * 1.15,
			"Cape length exceeded the accepted 15 percent tolerance."
		):
			return
	for point in fill.polygon:
		if not _expect(
			is_equal_approx(point.x, roundf(point.x))
			and is_equal_approx(point.y, roundf(point.y)),
			"Cape polygon vertices were not rounded to whole pixels."
		):
			return

	var before_facing_change := cape.positions[MovementConstants.CAPE_ROWS - 1]
	player.facing_direction = Vector2.LEFT
	await physics_frame
	if not _expect(
		is_equal_approx(anchor_a.position.x, -MovementConstants.CAPE_ANCHOR_A.x)
		and is_equal_approx(anchor_b.position.x, -MovementConstants.CAPE_ANCHOR_B.x)
		and cape.positions[MovementConstants.CAPE_ROWS - 1].distance_to(before_facing_change) < 8.0,
		"Cape anchors did not mirror while retaining nearby world-space points."
	):
		return

	player.reset_for_round(Vector2(160, 80))
	if not _expect(not cape.initialized, "Respawn did not invalidate the cape simulation."):
		return
	await physics_frame
	if not _expect(
		cape.initialized
		and cape.positions[0].is_equal_approx(anchor_a.global_position)
		and cape.positions[MovementConstants.CAPE_ROWS].is_equal_approx(anchor_b.global_position),
		"Cape did not safely reset to its anchors after respawn."
	):
		return

	var frozen_positions := cape.positions.duplicate()
	player.movement_state = PlayerController.MovementState.DASH
	player.dash_freeze_timer = MovementConstants.DASH_FREEZE
	for _frame in range(2):
		await physics_frame
	if not _expect(
		cape.positions == frozen_positions,
		"Cape simulation advanced during its player's local dash freeze."
	):
		return
	player.reset_for_round(Vector2(160, 80))
	await physics_frame
	cape.positions[2] = Vector2(INF, INF)
	cape.simulate(
		1.0 / 60.0,
		anchor_a.global_position,
		anchor_b.global_position,
		Vector2.ZERO,
		player.idle_color
	)
	if not _expect(
		cape.initialized
		and is_finite(cape.positions[2].x)
		and is_finite(cape.positions[2].y),
		"Cape simulation did not recover from a non-finite particle."
	):
		return
	if not _expect(
		other_cape.initialized and other_cape.positions[0].is_equal_approx(
			other_player.get_node("CapeAnchors/AnchorA").global_position
		),
		"Second player's cape did not simulate independently."
	):
		return

	print("Cape geometry, dash palette, per-player transitions, anchors, freeze, respawn, and recovery verified.")
	quit()
