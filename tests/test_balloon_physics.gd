extends SceneTree

var ground_touch_count: int = 0
var player_hit_count: int = 0
var last_hit_player: CharacterBody2D


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _on_ground_touched() -> void:
	ground_touch_count += 1


func _on_player_hit(player: CharacterBody2D) -> void:
	player_hit_count += 1
	last_hit_player = player


func _run_test() -> void:
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var balloon: RigidBody2D = main_scene.get_node("Arena/Balloon")
	var player_1: CharacterBody2D = main_scene.get_node("Arena/Player1")
	var match_manager: Node = main_scene.get_node("Arena/MatchManager")
	balloon.ground_touched.disconnect(Callable(match_manager, "_on_ground_touched"))
	balloon.ground_touched.connect(_on_ground_touched)
	balloon.player_hit.connect(_on_player_hit)
	var body_shape := balloon.get_node("CollisionShape2D").shape as CircleShape2D
	var contact_shape := balloon.get_node("PlayerContactArea/CollisionShape2D").shape as CircleShape2D
	if not _expect(
		is_equal_approx(body_shape.radius, balloon.balloon_collision_radius)
		and is_equal_approx(contact_shape.radius, balloon.player_contact_radius)
		and is_equal_approx(balloon.gravity_scale, balloon.gravity_strength)
		and is_equal_approx(balloon.physics_material_override.bounce, balloon.rebound_strength),
		"Exported balloon settings were not applied to their physics resources."
	):
		return

	balloon.reset_round(Vector2(160, 150))
	for _frame in range(90):
		await physics_frame
	if not _expect(ground_touch_count == 1, "Ground contact was not reported exactly once in the round."):
		return

	balloon.reset_round(Vector2(160, 80))
	for _frame in range(90):
		await physics_frame
	if not _expect(ground_touch_count == 2, "Ground contact was not re-armed for the next round."):
		return

	balloon.reset_round(Vector2(160, 80))
	balloon.linear_velocity = Vector2(900, -900)
	await physics_frame
	await physics_frame
	if not _expect(
		absf(balloon.linear_velocity.x) <= balloon.max_horizontal_speed + 0.1
		and absf(balloon.linear_velocity.y) <= balloon.max_vertical_speed + 0.1,
		"Balloon exceeded a configured axis speed limit."
	):
		return

	balloon.reset_round(Vector2(160, 90))
	player_1.global_position = Vector2(160, 106)
	player_1.velocity = Vector2.ZERO
	for _frame in range(5):
		await physics_frame
	if not _expect(player_hit_count == 1, "Player contact did not produce exactly one valid hit."):
		return
	if not _expect(last_hit_player == player_1, "Balloon hit attribution identified the wrong player."):
		return
	if not _expect(balloon.linear_velocity.y < 0.0, "Player contact did not apply an upward impulse."):
		return
	if not _expect(
		balloon.visual.color != balloon.default_visual_color,
		"Player impact did not trigger visible balloon feedback."
	):
		return
	var slow_impact_speed := absf(balloon.linear_velocity.y)
	balloon._on_player_contact_area_body_entered(player_1)
	if not _expect(player_hit_count == 1, "A repeated contact inside the interval applied another hit."):
		return
	for _frame in range(8):
		await physics_frame
	balloon._on_player_contact_area_body_entered(player_1)
	if not _expect(player_hit_count == 2, "A valid contact was still rejected after the interval elapsed."):
		return
	balloon.reset_round(Vector2(160, 90))
	player_1.global_position = Vector2(160, 106)
	player_1.velocity = Vector2(0, -200)
	balloon._on_player_contact_area_body_entered(player_1)
	await physics_frame
	var fast_impact_speed := absf(balloon.linear_velocity.y)
	if not _expect(
		fast_impact_speed > slow_impact_speed
		and fast_impact_speed <= balloon.max_player_hit_impulse / balloon.mass + 1.0,
		"Normal impact did not scale with approach speed inside its configured range."
	):
		return

	print("Balloon contacts, per-axis speed bounds, repeat interval, and ground event verified.")
	quit()
