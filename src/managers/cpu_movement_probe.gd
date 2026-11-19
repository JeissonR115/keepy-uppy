class_name CPUMovementProbe
extends RefCounted

const ARENA_SCENE := preload("res://src/scenes/levels/arena.tscn")
const MAX_PHYSICS_FRAMES := 1200
const MovementConstants = preload("res://src/models/player/player_movement_constants.gd")


class ProbeBrain:
	extends CPUBrain

	var player: PlayerController
	var movement: String
	var horizontal: float
	var direction: Vector2
	var action_started: bool = false


	func _init(
		probe_player: PlayerController,
		probe_movement: String,
		probe_horizontal: float,
		probe_direction: Vector2
	) -> void:
		player = probe_player
		movement = probe_movement
		horizontal = probe_horizontal
		direction = probe_direction


	func decide(_delta: float) -> CPUIntent:
		state = State.CPU_TURNO_PROPIO
		var intent := CPUIntent.new()
		if movement == "jump":
			intent.horizontal = horizontal
			if not action_started and player.is_on_floor():
				intent.jump = true
				action_started = true
		elif not action_started:
			intent.dash = true
			intent.dash_direction = direction.normalized()
			action_started = true
		return intent


static func run(
	tree: SceneTree,
	arena_data: ArenaData,
	request: Dictionary
) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = Vector2i.ONE
	viewport.world_2d = World2D.new()
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(viewport)

	var probe_arena := ARENA_SCENE.instantiate()
	probe_arena.process_mode = Node.PROCESS_MODE_ALWAYS
	var scoreboard := probe_arena.get_node_or_null("Scoreboard")
	if scoreboard != null:
		scoreboard.free()
	viewport.add_child(probe_arena)
	await tree.process_frame

	var level_manager := probe_arena.get_node("LevelManager") as LevelManager
	if not level_manager.select_arena(arena_data.id):
		push_error("Movement probe could not select arena '%s'." % arena_data.id)
		viewport.queue_free()
		await tree.process_frame
		return {}

	var match_manager := probe_arena.get_node("MatchManager") as MatchManager
	match_manager.match_state = MatchManager.MatchState.ACTIVE
	match_manager.accepting_gameplay_input = true
	var probe_player := probe_arena.get_node("Player1") as PlayerController
	var other_player := probe_arena.get_node("Player2") as PlayerController
	other_player.set_physics_process(false)
	other_player.collision_layer = 0
	other_player.collision_mask = 0
	var probe_balloon := probe_arena.get_node("Balloon") as BalloonController
	probe_balloon.freeze = true
	probe_balloon.collision_layer = 0
	probe_balloon.collision_mask = 0

	var movement := str(request["movement"])
	var start_position := _vector_from_json(request["start_position"])
	var horizontal := float(request.get("horizontal", 0.0))
	var direction := (
		_vector_from_json(request["direction"])
		if movement == "dash"
		else Vector2.ZERO
	)
	probe_player.reset_for_round(start_position)
	probe_player.bot_enabled = true
	var probe_brain := ProbeBrain.new(probe_player, movement, horizontal, direction)
	probe_player.cpu_controller.set_brain(probe_brain)

	var physics_delta := Engine.time_scale / float(Engine.physics_ticks_per_second)
	var minimum_dash_frames := ceili(
		(MovementConstants.DASH_TIME + MovementConstants.DASH_FREEZE) / physics_delta
	)
	var action_start_frame := -1
	var frames := 0
	var left_floor := false
	var landed := false
	for _frame in range(MAX_PHYSICS_FRAMES):
		await tree.physics_frame
		frames += 1
		if probe_brain.action_started and action_start_frame < 0:
			action_start_frame = Engine.get_physics_frames()
		if action_start_frame < 0:
			continue
		if movement == "jump":
			if not probe_player.is_on_floor():
				left_floor = true
			elif left_floor:
				landed = true
		elif (
			Engine.get_physics_frames() - action_start_frame >= minimum_dash_frames
			and probe_player.movement_state != PlayerController.MovementState.DASH
			and probe_player.is_on_floor()
		):
			landed = true
		if landed:
			break

	var final_position := probe_player.global_position
	viewport.queue_free()
	await tree.process_frame
	return {
		"level": arena_data.id,
		"movement": movement,
		"start_position": _vector_to_json(start_position),
		"action_started": probe_brain.action_started,
		"landed": landed,
		"landing_position": _vector_to_json(final_position) if landed else null,
		"final_position": _vector_to_json(final_position),
		"physics_frames_elapsed": frames,
		"physics_delta": physics_delta,
		"reason": (
			""
			if landed
			else "jump_start_not_grounded"
			if movement == "jump" and not probe_brain.action_started
			else "landing_timeout"
		),
	}


static func _vector_from_json(value: Dictionary) -> Vector2:
	return Vector2(float(value["x"]), float(value["y"]))


static func _vector_to_json(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}
