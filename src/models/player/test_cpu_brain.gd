class_name TestCPUBrain
extends CPUBrain

enum DecisionState { SERVE, POSITION, HIT, AVOID }

const CPU_INTENT_SCRIPT := preload("res://src/models/player/cpu_intent.gd")
const LOCAL_BRAIN_SCRIPT := preload("res://src/models/player/local_brain.gd")
const NAV_GRAPH_BRAIN_SCRIPT := preload("res://src/models/player/nav_graph_brain.gd")
const TARGET_SELECTOR := preload("res://src/models/player/cpu_node_target_selector.gd")
const INTERCEPTION_PREDICTOR := preload("res://src/models/player/cpu_interception_predictor.gd")
const DECISION_SNAPSHOT := preload("res://src/models/player/cpu_decision_snapshot.gd")
const CONTACT_TARGET_OFFSET := 12.0
const HIT_DISTANCE := 42.0
const HORIZONTAL_DEADZONE := 10.0

var player: PlayerController
var graph: NavGraph
var fallback_brain: LocalBrain
var route_brain: NavGraphBrain
var decision_state: DecisionState = DecisionState.POSITION
var reason: String = "Waiting for match state."
var target_position: Vector2 = Vector2.ZERO
var current_node: int = -1
var target_node: int = -1
var previous_route := PackedInt64Array()
var trajectory := PackedVector2Array()
var last_route_change_reason: String = ""
var decision_snapshot
var _route_initialized: bool = false


func _init(owner: PlayerController = null, nav_graph: NavGraph = null) -> void:
	player = owner
	graph = nav_graph
	if player != null:
		fallback_brain = LOCAL_BRAIN_SCRIPT.new(player)
	route_brain = NAV_GRAPH_BRAIN_SCRIPT.new()
	decision_snapshot = DECISION_SNAPSHOT.new()


func set_graph(nav_graph: NavGraph) -> void:
	graph = nav_graph
	_route_initialized = false
	target_node = -1
	previous_route = PackedInt64Array()
	last_route_change_reason = "Navigation graph changed."
	route_brain.reset()


func decide(delta: float) -> CPUIntent:
	var intent := _decide(delta)
	_capture_snapshot(intent)
	return intent


func _decide(delta: float) -> CPUIntent:
	var intent: CPUIntent = CPU_INTENT_SCRIPT.new()
	if player == null:
		state = State.INACTIVE
		return intent
	if (
		not player.bot_enabled
		or player.match_manager.match_state != MatchManager.MatchState.ACTIVE
	):
		state = State.INACTIVE
		player.cpu_balloon_contact_suppressed = false
		reason = "Match is not active."
		trajectory = PackedVector2Array()
		return intent

	if player.match_manager.expected_balloon_player != player:
		state = State.CPU_TURNO_RIVAL
		decision_state = DecisionState.AVOID
		player.cpu_balloon_contact_suppressed = true
		_avoid_balloon(intent)
		reason = "Waiting for the opponent's turn; keeping clear of the balloon."
		return intent

	state = State.CPU_TURNO_PROPIO
	var arena_bounds := _balloon_bounds()
	trajectory = INTERCEPTION_PREDICTOR.trace(
		player.balloon, arena_bounds, LOCAL_BRAIN_SCRIPT.DEFAULT_PREDICTION_HORIZON
	)
	if player.balloon.waiting_for_first_touch:
		decision_state = DecisionState.SERVE
		target_position = player.balloon.global_position
		reason = "The CPU is the opening server and must make the first touch."
		_direct_approach(intent, target_position)
		_update_contact_gate()
		return intent
	if graph == null:
		return _use_fallback(delta, "No valid graph is loaded for this arena.")

	var prediction: Dictionary = INTERCEPTION_PREDICTOR.predict(
		player.balloon,
		player.global_position,
		arena_bounds,
		player.global_position.y - CONTACT_TARGET_OFFSET,
		LOCAL_BRAIN_SCRIPT.DEFAULT_PREDICTION_HORIZON
	)
	if not prediction.get("found", false):
		return _use_fallback(delta, "No safe descending interception was found.")
	target_position = prediction["position"]
	var selection: Dictionary = TARGET_SELECTOR.select_target(
		graph, player.global_position, target_position
	)
	if not selection.get("found", false):
		return _use_fallback(delta, "No reachable navigation node can reach the interception.")
	current_node = int(selection["start_node"])
	var selected_target := int(selection["target_node"])
	if not _route_initialized or selected_target != target_node:
		if _route_initialized:
			previous_route = route_brain.route.duplicate()
		var configured := route_brain.configure(
			player, graph, current_node, selected_target
		)
		if not configured:
			return _use_fallback(delta, "Could not configure a route: %s" % route_brain.last_error)
		target_node = selected_target
		_route_initialized = true
		last_route_change_reason = "Interception target changed to node %d." % target_node
	decision_state = DecisionState.POSITION
	reason = "Following the reachable route toward the predicted interception."
	intent = route_brain.decide(delta)
	if route_brain.route_complete or player.global_position.distance_to(player.balloon.global_position) <= HIT_DISTANCE:
		decision_state = DecisionState.HIT
		reason = _approach_for_safe_hit(intent)
	_update_contact_gate()
	return intent


func reset() -> void:
	state = State.INACTIVE
	decision_state = DecisionState.POSITION
	reason = "Waiting for match state."
	target_position = Vector2.ZERO
	current_node = -1
	target_node = -1
	previous_route = PackedInt64Array()
	trajectory = PackedVector2Array()
	last_route_change_reason = ""
	_route_initialized = false
	if is_instance_valid(player):
		player.cpu_balloon_contact_suppressed = false
	if route_brain != null:
		route_brain.reset()
	if fallback_brain != null:
		fallback_brain.reset()


func get_decision_state_name() -> String:
	match decision_state:
		DecisionState.SERVE:
			return "SERVE"
		DecisionState.POSITION:
			return "POSITION"
		DecisionState.HIT:
			return "HIT"
		DecisionState.AVOID:
			return "AVOID"
	return "POSITION"


func get_decision_snapshot() -> Variant:
	return decision_snapshot


func _use_fallback(delta: float, fallback_reason: String) -> CPUIntent:
	reason = fallback_reason
	last_route_change_reason = "LocalBrain fallback: %s" % fallback_reason
	decision_state = DecisionState.POSITION
	if fallback_brain == null:
		player.cpu_balloon_contact_suppressed = true
		return CPU_INTENT_SCRIPT.new()
	var intent: CPUIntent = fallback_brain.decide(delta)
	state = fallback_brain.state
	if state == State.CPU_TURNO_PROPIO:
		_update_contact_gate()
	return intent


func _capture_snapshot(intent: CPUIntent) -> void:
	decision_snapshot = DECISION_SNAPSHOT.new()
	var active_route := PackedInt64Array()
	var edge_from := -1
	var edge_to := -1
	var edge_action := ""
	if route_brain != null:
		active_route = route_brain.route
		if route_brain.route_index < active_route.size() - 1:
			edge_from = int(active_route[route_brain.route_index])
			edge_to = int(active_route[route_brain.route_index + 1])
			if graph != null:
				edge_action = graph.get_edge_action(edge_from, edge_to)
	decision_snapshot.capture(
		get_decision_state_name(),
		reason,
		target_position,
		current_node,
		active_route,
		previous_route,
		edge_from,
		edge_to,
		edge_action,
		intent,
		last_route_change_reason,
		trajectory
	)


func _approach_for_safe_hit(intent: CPUIntent) -> String:
	var offset := player.balloon.global_position - player.global_position
	if offset.y < -8.0:
		intent.horizontal = signf(offset.x) if absf(offset.x) > HORIZONTAL_DEADZONE else 0.0
		if absf(offset.x) < 28.0 and player.is_on_floor():
			intent.jump = true
		return "Aligning below the balloon for a safe upward contact."
	# If the balloon is below or level with the player, leave the contact zone and wait
	# for a trajectory that can be struck upward from underneath.
	intent.horizontal = -signf(offset.x) if not is_zero_approx(offset.x) else (
		-1.0 if player.global_position.x > 160.0 else 1.0
	)
	return "Waiting for the balloon to pass above the CPU before contacting it."


func _direct_approach(intent: CPUIntent, target: Vector2) -> void:
	var offset := target - player.global_position
	intent.horizontal = signf(offset.x) if absf(offset.x) > HORIZONTAL_DEADZONE else 0.0
	if offset.y < -6.0 and absf(offset.x) < 28.0 and player.is_on_floor():
		intent.jump = true


func _avoid_balloon(intent: CPUIntent) -> void:
	var offset := player.global_position - player.balloon.global_position
	var safe_distance := player.balloon.player_contact_radius + _player_radius() + 8.0
	if offset.length() > safe_distance:
		return
	var direction := signf(offset.x)
	if is_zero_approx(direction):
		direction = -1.0 if player.global_position.x > 160.0 else 1.0
	intent.horizontal = direction


func _update_contact_gate() -> void:
	var prediction: Dictionary = player.balloon.predict_normal_contact_result(player)
	player.cpu_balloon_contact_suppressed = (
		float(prediction["resulting_velocity"].y) > 0.0
	)


func _player_radius() -> float:
	var shape := player.player_collision_shape.shape as CapsuleShape2D
	return shape.radius if shape != null else 6.0


func _balloon_bounds() -> Rect2:
	var arena := player.get_parent()
	var level_manager := arena.get_node_or_null("LevelManager") as LevelManager
	var bounds := (
		level_manager.active_arena.playable_bounds
		if level_manager != null and level_manager.active_arena != null
		else Rect2(Vector2.ZERO, arena.get_viewport_rect().size)
	)
	var radius := player.balloon.balloon_collision_radius
	return Rect2(
		bounds.position + Vector2.ONE * radius,
		bounds.size - Vector2.ONE * radius * 2.0
	)
