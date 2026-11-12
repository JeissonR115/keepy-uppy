extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _hair_points(hair: Node) -> Array[Vector2]:
	var points: Array[Vector2] = hair.get("points_a")
	return points.duplicate()


func _run_test() -> void:
	var main_scene := (load("res://src/scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main_scene)
	await process_frame
	var player_1: PlayerController = main_scene.get_node("Arena/Player1")
	var player_2: PlayerController = main_scene.get_node("Arena/Player2")
	var hair: Node = player_2.get_node_or_null("PlayerHair")
	if not _expect(
		player_1.get_node_or_null("PlayerHair") == null
		and hair != null
		and hair.find_children("*", "CollisionObject2D", true, false).is_empty()
		and hair.get_node("StrandA") is Line2D
		and hair.get_node("StrandB") is Line2D,
		"Procedural hair was not attached only to P2 as cosmetic line geometry."
	):
		return
	var initial := _hair_points(hair)
	if not _expect(
		initial.size() == 6
		and is_equal_approx(initial[0].x, -4.0)
		and is_equal_approx(initial[0].y, -11.0),
		"P2 hair did not initialize from the configured visual anchors."
	):
		return

	for _frame in range(24):
		hair.call("simulate", 1.0 / 60.0, Vector2(130.0, 0.0), Vector2.RIGHT, false, Vector2.ZERO, false)
	var accelerating := _hair_points(hair)
	for _frame in range(24):
		hair.call("simulate", 1.0 / 60.0, Vector2(-130.0, 0.0), Vector2.LEFT, false, Vector2.ZERO, false)
	var reversing := _hair_points(hair)
	if not _expect(
		accelerating[5].distance_to(initial[5]) > 0.5
		and reversing[5].distance_to(accelerating[5]) > 0.5,
		"Hair did not trail player acceleration and direction reversal."
	):
		return
	for _frame in range(24):
		hair.call("simulate", 1.0 / 60.0, Vector2.ZERO, Vector2.LEFT, false, Vector2.ZERO, false)
	var braking := _hair_points(hair)
	hair.call("simulate", 1.0 / 60.0, Vector2.ZERO, Vector2.RIGHT, false, Vector2.ZERO, false)
	if not _expect(
		braking[5].distance_to(reversing[5]) > 0.25
		and _hair_points(hair)[5].distance_to(braking[5]) > 0.01,
		"Hair did not settle after braking or respond to a turn in place."
	):
		return

	var before_frozen := _hair_points(hair)
	hair.call("simulate", 1.0 / 60.0, Vector2(0.0, -250.0), Vector2.RIGHT, true, Vector2.RIGHT, true)
	if not _expect(_hair_points(hair) == before_frozen, "Hair advanced during dash freeze."):
		return
	for _frame in range(12):
		hair.call("simulate", 1.0 / 60.0, Vector2(0.0, -250.0), Vector2.RIGHT, false, Vector2.ZERO, false)
	var rising := _hair_points(hair)
	for _frame in range(12):
		hair.call("simulate", 1.0 / 60.0, Vector2(0.0, 220.0), Vector2.RIGHT, false, Vector2.ZERO, false)
	var falling := _hair_points(hair)
	for _frame in range(12):
		hair.call("simulate", 1.0 / 60.0, Vector2(360.0, 0.0), Vector2.RIGHT, true, Vector2.RIGHT, false)
	var dashing := _hair_points(hair)
	if not _expect(
		falling[5].distance_to(rising[5]) > 0.25
		and dashing[5].distance_to(falling[5]) > 0.25,
		"Hair did not respond distinctly to vertical motion and dash impulse."
	):
		return
	for index in range(1, dashing.size()):
		if not _expect(
			dashing[index].is_finite()
			and absf(dashing[index].distance_to(dashing[index - 1]) - 2.5) < 0.01,
			"Hair segment %d became invalid or exceeded its fixed length." % index
		):
			return

	hair.call("reset_simulation")
	var reset_points := _hair_points(hair)
	if not _expect(
		reset_points[0] == Vector2(-4.0, -11.0)
		and reset_points[5] == Vector2(-4.0, 1.5),
		"Hair reset did not restore anchor-relative segment geometry."
	):
		return
	hair.call("simulate", 1.0 / 60.0, Vector2(INF, 0.0), Vector2.RIGHT, false, Vector2.ZERO, false)
	if not _expect(
		_hair_points(hair)[0] == Vector2(-4.0, -11.0),
		"Hair did not recover safely from invalid movement data."
	):
		return
	print("P2 hair follows acceleration, reversal, vertical motion, dash, and reset without collision nodes.")
	quit()
