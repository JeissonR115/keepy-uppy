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
	paused = false
	var frame_players: Array[PlayerController] = [
		main_scene.get_node("Arena/Player1"), main_scene.get_node("Arena/Player2")
	]
	var initial_body_frames := [frame_players[0].visual.frame, frame_players[1].visual.frame]
	await create_timer(0.2).timeout
	if not _expect(
		frame_players[0].visual.speed_scale > 0.0
		and frame_players[1].visual.speed_scale > 0.0
		and frame_players[0].visual.frame != initial_body_frames[0]
		and frame_players[1].visual.frame != initial_body_frames[1],
		"P1/P2 body sprite frames must advance with playback enabled: start=%s current=%s scales=%s/%s playing=%s/%s." % [
			initial_body_frames, [frame_players[0].visual.frame, frame_players[1].visual.frame],
			frame_players[0].visual.speed_scale, frame_players[1].visual.speed_scale,
			frame_players[0].visual.is_playing(), frame_players[1].visual.is_playing()
		]
	):
		return

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
			and player.visual.position == Vector2(1, -9.000001)
			and player.visual.scale == Vector2.ONE
			and effect.scale == Vector2.ONE
			and player.visual.speed_scale == 1.0
			and player.visual.z_index == 10
			and effect.z_index == 11
			and capsule.radius == 3.0
			and capsule.height == 15.0
			and player.player_collision_shape.position == Vector2(0, 0.5)
			and player.get_node_or_null("Cape") == null
			and player.get_node_or_null("PlayerHair") != null,
			"%s sprite resources, retained collision, or hair are incorrectly configured." % player_name
		):
			return
		if not _expect(
			player.get_node("PlayerHair").z_index == 8,
			"%s hair must render at z-index 8." % player_name
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
		and player_1.visual_profile.get("hair_enabled")
		and player_2.visual_profile.get("hair_enabled")
		and player_1.visual.flip_h == player_2.visual.flip_h
		and player_1.visual.modulate == Color.WHITE
		and player_1.get_node("ActionEffect").modulate == Color.WHITE
		and player_2.visual.modulate == PlayerPresentationController.PLAYER_TWO_TINT
		and player_2.get_node("ActionEffect").modulate == PlayerPresentationController.PLAYER_TWO_TINT,
		"P1/P2 profiles are not independently configured with expected frames and tint."
	):
		return
	var p1_hair := player_1.get_node("PlayerHair")
	var p2_hair := player_2.get_node("PlayerHair")
	var p2_strand := p2_hair.get_node("HairViewport/Strand") as Line2D
	if not _expect(
		p1_hair.scene_file_path == p2_hair.scene_file_path
		and (p1_hair.get_node("HairViewport") as SubViewport).size == Vector2i(24, 24)
		and p2_strand.width == 6.0
		and p2_strand.texture != null
		and p2_strand.texture_mode == Line2D.LINE_TEXTURE_STRETCH
		and player_1.visual_profile.get("hair_color") == PlayerHair.DEFAULT_COLOR
		and player_2.visual_profile.get("hair_color") == PlayerHair.DEFAULT_COLOR
		and p1_hair.get_node("HairOutput") is Sprite2D
		and p2_hair.get_node("HairOutput").material is ShaderMaterial,
		"P1/P2 must instantiate the same textured 24 by 24 hair rig."
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
	var classic_arena := (load("res://src/scenes/levels/arena_classic.tscn") as PackedScene).instantiate()
	var sky_arena := (load("res://src/scenes/levels/sky_towers.tscn") as PackedScene).instantiate()
	if not _expect(
		(classic_arena.get_node("Background") as CanvasItem).z_index == -100
		and (sky_arena.get_node("Background") as CanvasItem).z_index == -100,
		"Arena backgrounds must render at z-index -100."
	):
		return
	classic_arena.free()
	sky_arena.free()
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
