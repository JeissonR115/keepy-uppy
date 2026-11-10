extends SceneTree

var rescue_count: int = 0
var rescued_direction: Vector2


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _on_dash_rescued(_player: CharacterBody2D, direction: Vector2) -> void:
	rescue_count += 1
	rescued_direction = direction


func _run_test() -> void:
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var player: CharacterBody2D = main_scene.get_node("Arena/Player1")
	var balloon: RigidBody2D = main_scene.get_node("Arena/Balloon")
	var trail: Line2D = player.get_node("DashTrail")
	var rescue_area: Area2D = player.get_node("DashRescueArea")
	balloon.dash_rescued.connect(_on_dash_rescued)
	player.dash_speed = 150.0
	player.dash_duration = 0.25
	player.dash_cooldown = 0.5
	player.global_position = Vector2(120, 90)
	player.velocity = Vector2.ZERO
	balloon.reset_round(Vector2(160, 90))

	if not _expect(not rescue_area.monitoring and not trail.visible, "Dash effects should start inactive."):
		return
	Input.action_press("player_1_right")
	Input.action_press("player_1_dash")
	await physics_frame
	await physics_frame
	if not _expect(rescue_area.monitoring and trail.visible, "Dash zone and trail did not activate."):
		return
	for _frame in range(3):
		await physics_frame
	if not _expect(rescue_count == 1, "The active dash zone did not rescue the balloon exactly once."):
		return
	if not _expect(rescued_direction.x > 0.0 and rescued_direction.y < 0.0, "Rescue impulse ignored the dash direction."):
		return
	for _frame in range(2):
		await physics_frame
	if not _expect(balloon.linear_velocity.x > 0.0, "Dash rescue did not apply an impulse to the balloon."):
		return
	if not _expect(
		balloon.linear_velocity.length() > balloon.max_player_hit_impulse / balloon.mass,
		"Dash rescue did not create a stronger, distinct impulse than a normal hit."
	):
		return

	balloon.reset_round(Vector2(280, 80))
	for _frame in range(2):
		await physics_frame
	balloon.reset_round(player.global_position + player.dash_direction * 8.0)
	for _frame in range(3):
		await physics_frame
	if not _expect(rescue_count == 1, "One dash activation rescued the balloon more than once."):
		return

	for _frame in range(20):
		await physics_frame
	if not _expect(not rescue_area.monitoring and not trail.visible, "Dash zone or trail outlived its active interval."):
		return

	Input.action_release("player_1_right")
	Input.action_release("player_1_dash")
	print("Dash rescue direction, one-hit limit, and effect lifetime verified.")
	quit()
