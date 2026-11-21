extends RefCounted

const DEFAULT_PREDICTION_HORIZON := 3.0
const MAX_PREDICTION_STEPS := 360


## Predicts whether the balloon crosses target_y within the configured horizon.
## The result contract is {found: bool, position: Vector2, time: float}.
static func predict(
	balloon: BalloonController,
	player_position: Vector2,
	arena_bounds: Rect2,
	target_y: float,
	horizon_seconds: float = DEFAULT_PREDICTION_HORIZON
) -> Dictionary:
	var safe_target := Vector2(
		clampf(player_position.x, arena_bounds.position.x, arena_bounds.end.x),
		clampf(player_position.y, arena_bounds.position.y, arena_bounds.end.y)
	)
	var scoring_ground_bound := _scoring_ground_bound(balloon, arena_bounds)
	if (
		not is_finite(target_y)
		or not is_finite(horizon_seconds)
		or horizon_seconds <= 0.0
		or target_y >= scoring_ground_bound
		or balloon.waiting_for_first_touch
	):
		return {"found": false, "position": safe_target, "time": 0.0}

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
	var ground_bound := scoring_ground_bound
	var elapsed := 0.0
	var previous_position := current_position

	for _step_index in range(max_steps):
		var delta := minf(step, horizon - elapsed)
		if delta <= 0.0:
			break
		previous_position = current_position
		var step_result := _simulate_step(
			balloon, current_position, current_velocity, arena_bounds, ground_bound, gravity, delta
		)
		current_position = step_result["position"]
		current_velocity = step_result["velocity"]
		elapsed += delta
		if step_result["grounded"]:
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


## Returns the bounded balloon trajectory used by prediction, including its initial point.
static func trace(
	balloon: BalloonController,
	arena_bounds: Rect2,
	horizon_seconds: float = DEFAULT_PREDICTION_HORIZON
) -> PackedVector2Array:
	var points := PackedVector2Array()
	if (
		balloon == null
		or balloon.waiting_for_first_touch
		or not is_finite(horizon_seconds)
		or horizon_seconds <= 0.0
		or not balloon.global_position.is_finite()
		or not balloon.linear_velocity.is_finite()
	):
		return points
	var physics_hz := float(ProjectSettings.get_setting(
		"physics/common/physics_ticks_per_second", 60
	))
	var step := 1.0 / maxf(physics_hz, 1.0)
	var max_steps := mini(ceili(horizon_seconds / step), MAX_PREDICTION_STEPS)
	var horizon := minf(horizon_seconds, max_steps * step)
	var ground_bound := _scoring_ground_bound(balloon, arena_bounds)
	var gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	var position := balloon.global_position
	var velocity := balloon.linear_velocity
	points.append(position)
	var elapsed := 0.0
	for _step_index in range(max_steps):
		var delta := minf(step, horizon - elapsed)
		if delta <= 0.0:
			break
		var result := _simulate_step(
			balloon, position, velocity, arena_bounds, ground_bound, gravity, delta
		)
		position = result["position"]
		velocity = result["velocity"]
		elapsed += delta
		points.append(position)
		if result["grounded"]:
			break
	return points


static func _simulate_step(
	balloon: BalloonController,
	position: Vector2,
	velocity: Vector2,
	arena_bounds: Rect2,
	ground_bound: float,
	gravity: float,
	delta: float
) -> Dictionary:
	velocity /= 1.0 + maxf(balloon.air_resistance, 0.0) * delta
	velocity.x /= 1.0 + maxf(balloon.horizontal_damping, 0.0) * delta
	velocity.x = clampf(velocity.x, -balloon.max_horizontal_speed, balloon.max_horizontal_speed)
	velocity.y = clampf(velocity.y, -balloon.max_hit_speed, balloon.max_fall_speed)
	velocity.y += gravity * balloon.gravity_scale * delta
	velocity.y = clampf(velocity.y, -balloon.max_hit_speed, balloon.max_fall_speed)
	position += velocity * delta
	if position.x < arena_bounds.position.x:
		position.x = arena_bounds.position.x
		velocity.x = absf(velocity.x) * balloon.rebound_strength
	elif position.x > arena_bounds.end.x:
		position.x = arena_bounds.end.x
		velocity.x = -absf(velocity.x) * balloon.rebound_strength
	if position.y < arena_bounds.position.y:
		position.y = arena_bounds.position.y
		velocity.y = absf(velocity.y) * balloon.rebound_strength
	var grounded := position.y >= ground_bound
	return {"position": position, "velocity": velocity, "grounded": grounded}


static func _scoring_ground_bound(balloon: BalloonController, arena_bounds: Rect2) -> float:
	var arena := balloon.get_parent()
	var scoring_bound := INF
	if arena == null:
		return arena_bounds.end.y - balloon.balloon_collision_radius
	for node: Node in arena.find_children("*", "TileMapLayer", true, false):
		if not node.is_in_group("scoring_ground") or not node is TileMapLayer:
			continue
		var layer := node as TileMapLayer
		if layer.tile_set == null:
			continue
		var tile_height := float(layer.tile_set.tile_size.y)
		for cell: Vector2i in layer.get_used_cells():
			var cell_top := layer.to_global(layer.map_to_local(cell)).y - tile_height * 0.5
			scoring_bound = minf(
				scoring_bound,
				cell_top - balloon.balloon_collision_radius
			)
	return (
		scoring_bound
		if is_finite(scoring_bound)
		else arena_bounds.end.y - balloon.balloon_collision_radius
	)
