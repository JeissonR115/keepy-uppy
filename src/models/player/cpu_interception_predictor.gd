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
	if (
		not is_finite(target_y)
		or not is_finite(horizon_seconds)
		or horizon_seconds <= 0.0
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
