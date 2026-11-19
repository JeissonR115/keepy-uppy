class_name CPUObservationBuilder
extends RefCounted


static func build_for(player: PlayerController) -> Dictionary:
	var manager := player.match_manager
	var player_1 := manager.player_1 as PlayerController
	var player_2 := manager.player_2 as PlayerController
	var level_id := ""
	var level_manager := player.get_parent().get_node_or_null("LevelManager")
	if level_manager != null and level_manager.has_method("get_selected_arena"):
		var arena: Resource = level_manager.call("get_selected_arena")
		if arena != null:
			level_id = str(arena.get("id"))
	return {
		"tick": Engine.get_physics_frames(),
		"bot_player": player.input_prefix,
		"players": {
			"player_1": _player_snapshot(player_1),
			"player_2": _player_snapshot(player_2),
		},
		"balloon": {
			"position": _vector_to_json(player.balloon.global_position),
			"velocity": _vector_to_json(player.balloon.linear_velocity),
			"waiting_for_first_touch": player.balloon.waiting_for_first_touch,
		},
		"current_turn": _player_id(manager.expected_balloon_player),
		"score": {
			"points": {
				"player_1": manager.player_1_score,
				"player_2": manager.player_2_score,
			},
			"sets": {
				"player_1": manager.player_1_sets,
				"player_2": manager.player_2_sets,
			},
		},
		"level": level_id,
	}


static func _player_snapshot(player: PlayerController) -> Dictionary:
	return {
		"position": _vector_to_json(player.global_position),
		"velocity": _vector_to_json(player.velocity),
		"on_floor": player.is_on_floor(),
		"wall_contact": player._wall_direction_within(
			PlayerMovementConstants.WALL_CHECK_DIST
		),
		"dash_cooldown": player.dash_cooldown_timer,
		"dash_available": player.dash_available,
		"stamina": player.climb_stamina,
	}


static func _player_id(player: CharacterBody2D) -> String:
	if not is_instance_valid(player):
		return ""
	var controller := player as PlayerController
	return controller.input_prefix if controller != null else str(player.name)


static func _vector_to_json(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}
