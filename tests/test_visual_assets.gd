extends SceneTree


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

	var font := load("res://assets/fonts/DotGothic16/DotGothic16-Regular.ttf") as FontFile
	var theme := load("res://assets/fonts/DotGothic16/theme.tres") as Theme
	if not _expect(font != null, "DotGothic16 could not be loaded."):
		return
	if not _expect(
		theme != null and theme.default_font == font,
		"The global theme does not use DotGothic16."
	):
		return
	if not _expect(
		ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items"
		and ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")
		== 1,
		"The project still uses low-resolution viewport scaling or nearest-neighbor filtering."
	):
		return
	var controls := main_scene.find_children("*", "Control", true, false)
	if not _expect(not controls.is_empty(), "The main scene has no GUI controls to validate."):
		return
	for control: Control in controls:
		if not _expect(
			control.get_theme_default_font() == font,
			"Control %s is not inheriting the global DotGothic16 font." % control.get_path()
		):
			return

	for player_name: String in ["Player1", "Player2"]:
		var player: PlayerController = main_scene.get_node("Arena/%s" % player_name)
		var effect := player.get_node("ActionEffect") as AnimatedSprite2D
		var capsule := player.player_collision_shape.shape as CapsuleShape2D
		if not _expect(
			player.visual is AnimatedSprite2D
			and player.visual.sprite_frames.get_animation_names().size() == 13
			and player.visual.sprite_frames.get_frame_count("idle") == 66
			and player.visual.sprite_frames.get_frame_texture("idle", 0).get_width() == 32
			and effect.sprite_frames.get_animation_names().size() == 5
			and not effect.sprite_frames.has_animation("idle")
			and player.visual.position == Vector2(0, -4)
			and effect.z_index > player.visual.z_index
			and capsule.radius == 5.0
			and capsule.height == 23.0
			and player.player_collision_shape.position == Vector2(0, 0.5)
			and player.get_node("Cape") is PlayerCape
			and player.cape.visible == bool(player.visual_profile.get("cape_enabled")),
			"%s sprite resources, retained collision, or cape are incorrectly configured." % player_name
		):
			return
		for animation_name: String in [
			"runSlow", "runFast", "flip", "fall", "fallFast", "fallPose",
			"dangling", "dash", "wallslide", "climbPull", "climbPush", "climbup"
		]:
			var frame_count := player.visual.sprite_frames.get_frame_count(animation_name)
			if not _expect(frame_count > 0, "%s has no body animation frames." % animation_name):
				return
			for frame_index in frame_count:
				var texture := player.visual.sprite_frames.get_frame_texture(animation_name, frame_index)
				if not _expect(
					texture != null and texture.get_size() == Vector2(32, 32),
					"%s frame %s is missing or is not 32 by 32 pixels." % [animation_name, frame_index]
				):
					return
		for animation_name: String in ["jump", "climb", "climbLoop", "danger", "still"]:
			if not _expect(
				effect.sprite_frames.get_frame_count(animation_name) > 0,
				"%s has no action-effect frames." % animation_name
			):
				return
			for frame_index in effect.sprite_frames.get_frame_count(animation_name):
				var texture := effect.sprite_frames.get_frame_texture(animation_name, frame_index)
				if not _expect(
					texture != null and texture.get_size() == Vector2(32, 32),
					"%s effect frame %s is missing or is not 32 by 32 pixels." % [animation_name, frame_index]
				):
					return
		var body_map: Dictionary = player.visual_profile.get("body_animation_map")
		var effect_map: Dictionary = player.visual_profile.get("effect_animation_map")
		for state_name: String in [
			"idle", "run_slow", "run_fast", "jump_start", "rise", "fall",
			"fall_fast", "dash", "wall_slide", "climb_up", "climb_down", "climb_up_entry"
		]:
			var clip_name := str(body_map.get(state_name, ""))
			if not _expect(
				not clip_name.is_empty() and player.visual.sprite_frames.has_animation(clip_name),
				"%s profile has no valid body clip for state %s." % [player_name, state_name]
			):
				return
		for state_name: String in ["jump", "climb_entry", "climb_loop", "idle_loop", "danger"]:
			var clip_name := str(effect_map.get(state_name, ""))
			if not _expect(
				not clip_name.is_empty() and effect.sprite_frames.has_animation(clip_name),
				"%s profile has no valid effect clip for state %s." % [player_name, state_name]
			):
				return
	var player_1 := main_scene.get_node("Arena/Player1") as PlayerController
	var player_2 := main_scene.get_node("Arena/Player2") as PlayerController
	if not _expect(
		player_1.visual.sprite_frames == player_2.visual.sprite_frames
		and player_1.action_effect.sprite_frames == player_2.action_effect.sprite_frames
		and player_1.visual_profile != player_2.visual_profile
		and player_1.visual_profile.get("body_frames") == player_1.visual.sprite_frames
		and player_2.visual_profile.get("body_frames") == player_2.visual.sprite_frames
		and player_1.visual_profile.get("tint") == Color.WHITE
		and player_2.visual_profile.get("tint") == PlayerPresentationController.PLAYER_TWO_TINT
		and player_1.visual_profile.get("cape_enabled")
		and not player_2.visual_profile.get("cape_enabled")
		and not player_1.visual_profile.get("hair_enabled")
		and player_2.visual_profile.get("hair_enabled")
		and player_1.visual.flip_h == player_2.visual.flip_h
		and player_1.visual.modulate == Color.WHITE
		and player_1.get_node("ActionEffect").modulate == Color.WHITE
		and player_2.visual.modulate == PlayerPresentationController.PLAYER_TWO_TINT
		and player_2.get_node("ActionEffect").modulate == PlayerPresentationController.PLAYER_TWO_TINT,
		"P1/P2 profiles are not independently configured with the expected frames and tint."
	):
		return
	var p1_capsule := player_1.player_collision_shape.shape as CapsuleShape2D
	var p2_capsule := player_2.player_collision_shape.shape as CapsuleShape2D
	if not _expect(
		p1_capsule.radius == p2_capsule.radius
		and p1_capsule.height == p2_capsule.height
		and player_1.player_collision_shape.position == player_2.player_collision_shape.position
		and player_1.collision_layer == player_2.collision_layer
		and player_1.collision_mask == player_2.collision_mask
		and player_1.dash_rescue_area.get_parent() == player_1
		and player_2.dash_rescue_area.get_parent() == player_2,
		"Visual profiles altered player collision geometry, layers, or rescue-area ownership."
	):
		return

	var arena: CanvasGroup = main_scene.get_node("Arena")
	var screen_effect := arena.material as ShaderMaterial
	var scoreboard: CanvasLayer = arena.get_node("Scoreboard")
	if not _expect(
		screen_effect != null
		and screen_effect.shader != null
		and is_equal_approx(screen_effect.get_shader_parameter("pixel_block_size"), 3.0),
		"The 32-bit pixel effect is not configured on the arena."
	):
		return
	if not _expect(
		scoreboard.get_canvas() != arena.get_canvas()
		and main_scene.get_node("PlayerCountMenu") is CanvasLayer,
		"The world effect is not isolated from the UI canvas layers."
	):
		return

	print("Pixel font, arena layers, animated player sprites, effects, and player tint verified.")
	quit()
