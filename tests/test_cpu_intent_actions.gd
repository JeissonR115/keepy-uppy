extends SceneTree

const SurfaceTechniques = preload("res://src/models/player/player_surface_techniques.gd")


class ScriptedBrain extends CPUBrain:
	var action := CPUIntent.new()

	func decide(_delta: float) -> CPUIntent:
		state = CPUBrain.State.CPU_TURNO_PROPIO
		return action


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
	main_scene.get_node(
		"PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton"
	).pressed.emit()
	main_scene.get_node("PlayerCountMenu")._select_level("classic")
	await process_frame
	await physics_frame

	var arena: Node = main_scene.get_node("Arena")
	var player: PlayerController = arena.get_node("Player1")
	var manager: MatchManager = arena.get_node("MatchManager")
	var cpu: CPUController = player.get_node("CPUController")
	var brain := ScriptedBrain.new()
	player.bot_enabled = true
	cpu.set_brain(brain)
	manager.match_state = MatchManager.MatchState.ACTIVE
	manager.accepting_gameplay_input = true
	manager.round_intermission = 0.0
	manager.expected_balloon_player = player

	var platform := StaticBody2D.new()
	platform.position = Vector2(88.0, 100.0)
	platform.collision_layer = 4
	platform.add_to_group("one_way_platform")
	var platform_shape := CollisionShape2D.new()
	platform_shape.one_way_collision = true
	var platform_rectangle := RectangleShape2D.new()
	platform_rectangle.size = Vector2(40.0, 4.0)
	platform_shape.shape = platform_rectangle
	platform.add_child(platform_shape)
	arena.add_child(platform)

	player.reset_for_round(Vector2(88.0, 90.0))
	player.velocity = Vector2(0.0, 60.0)
	for _frame in range(5):
		await physics_frame
	if not _expect(
		player.is_on_floor() and SurfaceTechniques.is_on_one_way_platform(player),
		"CPU player did not land on the scripted one-way platform."
	):
		return

	brain.action.down = true
	brain.action.jump = true
	await physics_frame
	if not _expect(
		player.platform_drop_timer > 0.0
		and not player.get_collision_mask_value(3),
		"CPU down+jump intent did not drop through the one-way platform."
	):
		return

	var climb_wall := StaticBody2D.new()
	climb_wall.position = Vector2(8.0, 80.0)
	climb_wall.collision_layer = 1
	climb_wall.add_to_group("climbable_wall")
	var wall_shape := CollisionShape2D.new()
	var wall_rectangle := RectangleShape2D.new()
	wall_rectangle.size = Vector2(2.0, 500.0)
	wall_shape.shape = wall_rectangle
	climb_wall.add_child(wall_shape)
	arena.add_child(climb_wall)
	brain.action.down = false
	brain.action.jump = false
	brain.action.grab = true
	player.reset_for_round(Vector2(14.0, 80.0))
	manager.match_state = MatchManager.MatchState.ACTIVE
	manager.accepting_gameplay_input = true
	for _frame in range(3):
		await physics_frame
		if player.movement_state == PlayerController.MovementState.CLIMB:
			break
	if not _expect(
		player.movement_state == PlayerController.MovementState.CLIMB,
		"CPU grab intent did not enter the climb state."
	):
		return

	brain.action.down = true
	await physics_frame
	if not _expect(
		is_equal_approx(player.velocity.y, PlayerMovementConstants.CLIMB_DOWN_SPEED),
		"CPU down intent did not descend while climbing."
	):
		return

	main_scene.queue_free()
	await process_frame
	print("CPU down, jump, and grab intents drive the existing player movement.")
	quit()
