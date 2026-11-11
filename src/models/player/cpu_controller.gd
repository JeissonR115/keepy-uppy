class_name CPUController
extends Node

enum State { INACTIVE, CPU_TURNO_PROPIO, CPU_TURNO_RIVAL }

const HORIZONTAL_DEADZONE := 10.0
const JUMP_ALIGNMENT_DISTANCE := 26.0
const DEFAULT_PREDICTION_HORIZON := 3.0
const MAX_PREDICTION_STEPS := 360
const CONTACT_TARGET_OFFSET := 12.0

@export_range(0.0, 2.0, 0.01) var reaction_time: float = 0.1:
	set(value):
		reaction_time = clampf(value, 0.0, 2.0)
@export_range(0.0, 64.0, 0.5) var prediction_error_margin: float = 8.0:
	set(value):
		prediction_error_margin = clampf(value, 0.0, 64.0)
@export_range(0.0, 1.0, 0.01) var aggression_level: float = 0.35:
	set(value):
		aggression_level = clampf(value, 0.0, 1.0)
		if is_node_ready() and state == State.CPU_TURNO_RIVAL:
			_select_obstruction_decision()
@export_range(0.0, 200.0, 1.0) var dash_threshold_distance: float = 56.0:
	set(value):
		dash_threshold_distance = clampf(value, 0.0, 200.0)
@export_range(0.25, 5.0, 0.05) var prediction_horizon: float = DEFAULT_PREDICTION_HORIZON:
	set(value):
		prediction_horizon = clampf(value, 0.25, 5.0)

var state: State = State.INACTIVE
var horizontal_intent: float = 0.0
var jump_requested: bool = false
var dash_requested: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var prediction_error_offset: Vector2 = Vector2.ZERO
var obstruction_selected: bool = false
var _reaction_remaining: float = 0.0
var _random := RandomNumberGenerator.new()
var _has_balloon_direction: bool = false
var _last_balloon_direction: Vector2 = Vector2.ZERO

@onready var player: PlayerController = get_parent()


func _ready() -> void:
	var manager := player.get_parent().get_node("MatchManager") as MatchManager
	manager.coin_toss_completed.connect(_on_match_started)


func update_decision(delta: float = 1.0 / 60.0) -> State:
	_clear_intents()
	var next_state := State.INACTIVE
	if player.bot_enabled and player.match_manager.match_state == MatchManager.MatchState.ACTIVE:
		if player.match_manager.expected_balloon_player == player:
			next_state = State.CPU_TURNO_PROPIO
		else:
			next_state = State.CPU_TURNO_RIVAL
	if next_state != state:
		_enter_state(next_state)
	if state == State.INACTIVE:
		return state
	_update_reaction_for_balloon_direction()
	if _reaction_remaining > 0.0:
		_reaction_remaining = maxf(_reaction_remaining - delta, 0.0)
		if _reaction_remaining > 0.0:
			return state
	if state == State.CPU_TURNO_PROPIO:
		_decide_own_turn()
	elif state == State.CPU_TURNO_RIVAL:
		_decide_rival_turn()
	return state


func refresh_state() -> State:
	return update_decision()


func reset() -> void:
	state = State.INACTIVE
	_reaction_remaining = 0.0
	_has_balloon_direction = false
	prediction_error_offset = Vector2.ZERO
	obstruction_selected = false
	_clear_intents()


func _on_match_started(_coin_result: String, _opening_player: CharacterBody2D) -> void:
	var seed_value := player.match_manager.match_seed
	var actor_hash := player.input_prefix.hash()
	var combined_seed := int(posmod(seed_value * 31 + actor_hash, 2147483647))
	_random.seed = 1 if combined_seed == 0 else combined_seed
	reset()


func _enter_state(next_state: State) -> void:
	state = next_state
	_reaction_remaining = reaction_time
	if state == State.INACTIVE:
		prediction_error_offset = Vector2.ZERO
		obstruction_selected = false
	elif state == State.CPU_TURNO_PROPIO:
		prediction_error_offset = _random_offset()
	elif state == State.CPU_TURNO_RIVAL:
		_select_obstruction_decision()


func _update_reaction_for_balloon_direction() -> void:
	var velocity := player.balloon.linear_velocity
	var direction := Vector2(
		0.0 if absf(velocity.x) < 1.0 else signf(velocity.x),
		0.0 if absf(velocity.y) < 1.0 else signf(velocity.y)
	)
	if _has_balloon_direction and direction != _last_balloon_direction:
		_reaction_remaining = maxf(_reaction_remaining, reaction_time)
	_last_balloon_direction = direction
	_has_balloon_direction = true


func _random_offset() -> Vector2:
	if prediction_error_margin <= 0.0:
		return Vector2.ZERO
	var angle := _random.randf_range(-PI, PI)
	var distance := sqrt(_random.randf()) * prediction_error_margin
	return Vector2(cos(angle), sin(angle)) * distance


func _select_obstruction_decision() -> void:
	obstruction_selected = _random.randf() < aggression_level


func predict_interception(
	target_y: float, horizon_seconds: float = DEFAULT_PREDICTION_HORIZON
) -> Dictionary:
	var arena_bounds := _get_balloon_bounds()
	var safe_target := Vector2(
		clampf(player.global_position.x, arena_bounds.position.x, arena_bounds.end.x),
		clampf(player.global_position.y, arena_bounds.position.y, arena_bounds.end.y)
	)
	if (
		not is_finite(target_y)
		or not is_finite(horizon_seconds)
		or horizon_seconds <= 0.0
		or player.balloon.waiting_for_first_touch
	):
		return {"found": false, "position": safe_target, "time": 0.0}

	var balloon := player.balloon
	var current_position := balloon.global_position
	var current_velocity := balloon.linear_velocity
	if not current_position.is_finite() or not current_velocity.is_finite():
		return {"found": false, "position": safe_target, "time": 0.0}

	var physics_hz := float(ProjectSettings.get_setting(
		"physics/common/physics_ticks_per_second", 60
	))
	var step := 1.0 / maxf(physics_hz, 1.0)
	var max_steps := mini(
		ceili(horizon_seconds / step),
		MAX_PREDICTION_STEPS
	)
	var horizon := minf(horizon_seconds, max_steps * step)
	var gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	var radius := balloon.balloon_collision_radius
	var left_bound := arena_bounds.position.x
	var right_bound := arena_bounds.end.x
	var ceiling_bound := arena_bounds.position.y
	var ground_bound := arena_bounds.end.y
	var elapsed := 0.0
	var previous_position := current_position

	for _step_index in range(max_steps):
		var delta := minf(step, horizon - elapsed)
		if delta <= 0.0:
			break
		var air_retention := 1.0 + maxf(balloon.air_resistance, 0.0) * delta
		current_velocity /= air_retention
		current_velocity.x /= 1.0 + maxf(balloon.horizontal_damping, 0.0) * delta
		current_velocity.x = clampf(
			current_velocity.x,
			-balloon.max_horizontal_speed,
			balloon.max_horizontal_speed
		)
		current_velocity.y = clampf(
			current_velocity.y,
			-balloon.max_hit_speed,
			balloon.max_fall_speed
		)
		current_velocity.y += gravity * balloon.gravity_scale * delta
		current_velocity.y = clampf(
			current_velocity.y,
			-balloon.max_hit_speed,
			balloon.max_fall_speed
		)
		previous_position = current_position
		current_position += current_velocity * delta
		elapsed += delta

		if current_position.x < left_bound:
			current_position.x = left_bound
			current_velocity.x = absf(current_velocity.x) * balloon.rebound_strength
		elif current_position.x > right_bound:
			current_position.x = right_bound
			current_velocity.x = -absf(current_velocity.x) * balloon.rebound_strength
		if current_position.y < ceiling_bound:
			current_position.y = ceiling_bound
			current_velocity.y = absf(current_velocity.y) * balloon.rebound_strength
		elif current_position.y >= ground_bound:
			return {"found": false, "position": safe_target, "time": elapsed}

		if previous_position.y <= target_y and current_position.y >= target_y:
			var segment_height := current_position.y - previous_position.y
			if is_zero_approx(segment_height):
				return {"found": false, "position": safe_target, "time": elapsed}
			var fraction := clampf(
				(target_y - previous_position.y) / segment_height,
				0.0,
				1.0
			)
			var intersection := previous_position.lerp(current_position, fraction)
			intersection.y = target_y
			return {
				"found": true,
				"position": intersection,
				"time": elapsed - delta + delta * fraction,
			}

	return {"found": false, "position": safe_target, "time": horizon}


func _decide_own_turn() -> void:
	var target_position: Vector2
	if player.balloon.waiting_for_first_touch:
		target_position = player.balloon.global_position
	else:
		var prediction := predict_interception(
			player.global_position.y - CONTACT_TARGET_OFFSET,
			prediction_horizon
		)
		target_position = prediction["position"]
		if prediction["found"]:
			var bounds := _get_balloon_bounds()
			target_position += prediction_error_offset
			target_position.x = clampf(target_position.x, bounds.position.x, bounds.end.x)
			target_position.y = clampf(target_position.y, bounds.position.y, bounds.end.y)
		else:
			var bounds := _get_balloon_bounds()
			target_position = Vector2(
				clampf(player.global_position.x, bounds.position.x, bounds.end.x),
				player.global_position.y
			)

	var horizontal_distance := target_position.x - player.global_position.x
	if absf(horizontal_distance) > HORIZONTAL_DEADZONE:
		horizontal_intent = signf(horizontal_distance)
	var target_distance := player.global_position.distance_to(target_position)
	if (
		not player.balloon.waiting_for_first_touch
		and target_distance >= dash_threshold_distance
		and player.dash_available
		and player.dash_cooldown_timer <= 0.0
	):
		dash_requested = true
		dash_direction = (target_position - player.global_position).normalized()
	jump_requested = (
		absf(horizontal_distance)
		<= JUMP_ALIGNMENT_DISTANCE
		and target_position.y < player.global_position.y - 6.0
	)


func _decide_rival_turn() -> void:
	var threat := _find_balloon_threat()
	if threat["found"]:
		_evade_balloon(threat["position"])
		return
	if obstruction_selected:
		_try_obstruct_opponent()


func _find_balloon_threat() -> Dictionary:
	var balloon := player.balloon
	var balloon_position := balloon.global_position
	var safe_distance := balloon.player_contact_radius + _player_collision_radius() + 2.0
	if balloon_position.distance_to(player.global_position) <= safe_distance:
		return {"found": true, "position": balloon_position}

	var balloon_velocity := balloon.linear_velocity
	var speed_squared := balloon_velocity.length_squared()
	if speed_squared > 0.001:
		var time_to_closest := (
			(player.global_position - balloon_position).dot(balloon_velocity)
			/ speed_squared
		)
		if time_to_closest > 0.0 and time_to_closest <= prediction_horizon:
			var gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
			var projected_position := (
				balloon_position
				+ balloon_velocity * time_to_closest
				+ Vector2.DOWN
				* gravity
				* balloon.gravity_scale
				* time_to_closest
				* time_to_closest
				* 0.5
			)
			if projected_position.distance_to(player.global_position) <= safe_distance:
				return {"found": true, "position": projected_position}

	var prediction := predict_interception(
		player.global_position.y - CONTACT_TARGET_OFFSET,
		prediction_horizon
	)
	if (
		prediction["found"]
		and absf(prediction["position"].x - player.global_position.x) <= safe_distance
	):
		return {"found": true, "position": prediction["position"]}
	return {"found": false, "position": Vector2.ZERO}


func _evade_balloon(threat_position: Vector2) -> void:
	var bounds := _get_balloon_bounds()
	var safe_distance := (
		player.balloon.player_contact_radius + _player_collision_radius() + 8.0
	)
	var away_direction := signf(player.global_position.x - threat_position.x)
	if is_zero_approx(away_direction):
		if not is_zero_approx(player.balloon.linear_velocity.x):
			away_direction = -signf(player.balloon.linear_velocity.x)
		else:
			var opponent_x := _opponent().global_position.x
			away_direction = signf(player.global_position.x - opponent_x)
	if is_zero_approx(away_direction):
		away_direction = -1.0 if player.global_position.x > 160.0 else 1.0

	var left_target := maxf(bounds.position.x, player.global_position.x - safe_distance)
	var right_target := minf(bounds.end.x, player.global_position.x + safe_distance)
	var left_clearance := absf(left_target - threat_position.x)
	var right_clearance := absf(right_target - threat_position.x)
	var target_x := left_target if away_direction < 0.0 else right_target
	if maxf(left_clearance, right_clearance) > minf(left_clearance, right_clearance):
		target_x = left_target if left_clearance > right_clearance else right_target
	horizontal_intent = signf(target_x - player.global_position.x)


func _try_obstruct_opponent() -> void:
	var opponent := _opponent()
	var balloon_position := player.balloon.global_position
	var obstruction_x := lerpf(opponent.global_position.x, balloon_position.x, 0.5)
	var predicted := predict_interception(
		player.global_position.y - CONTACT_TARGET_OFFSET,
		prediction_horizon
	)
	var threat_x: float = (
		predicted["position"].x
		if predicted["found"]
		else balloon_position.x
	)
	var safe_distance := player.balloon.player_contact_radius + _player_collision_radius() + 4.0
	if (
		absf(obstruction_x - threat_x) <= safe_distance
		or Vector2(obstruction_x, player.global_position.y).distance_to(balloon_position)
		<= safe_distance
	):
		return
	var bounds := _get_balloon_bounds()
	obstruction_x = clampf(obstruction_x, bounds.position.x, bounds.end.x)
	horizontal_intent = signf(obstruction_x - player.global_position.x)


func _opponent() -> CharacterBody2D:
	if player.match_manager.player_1 == player:
		return player.match_manager.player_2
	return player.match_manager.player_1


func _player_collision_radius() -> float:
	var capsule := player.player_collision_shape.shape as CapsuleShape2D
	return capsule.radius if capsule != null else 6.0


func _get_balloon_bounds() -> Rect2:
	var arena: Node = player.get_parent()
	var viewport_size: Vector2 = arena.get_viewport_rect().size
	var radius: float = player.balloon.balloon_collision_radius
	var world_bounds := Rect2(Vector2.ZERO, viewport_size)
	var level_manager := arena.get_node_or_null("LevelManager")
	if level_manager != null and level_manager.has_method("get_selected_arena"):
		var selected_arena: Resource = level_manager.call("get_selected_arena")
		if selected_arena != null:
			world_bounds = selected_arena.get("playable_bounds")
	var left_bound := world_bounds.position.x + radius
	var right_bound := world_bounds.end.x - radius
	var ceiling_bound := world_bounds.position.y + radius
	var ground_bound := world_bounds.end.y - radius
	return Rect2(
		Vector2(left_bound, ceiling_bound),
		Vector2(right_bound - left_bound, ground_bound - ceiling_bound)
	)


func _clear_intents() -> void:
	horizontal_intent = 0.0
	jump_requested = false
	dash_requested = false
	dash_direction = Vector2.ZERO
