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
		if not _expect(
			player.visual is Polygon2D
			and player.visual.polygon.size() == 4
			and player.visual.polygon[0] == Vector2(-6.0, -12.0)
			and player.visual.polygon[2] == Vector2(6.0, 12.0)
			and player.get_node("Cape") is PlayerCape,
			"%s is not a basic rectangle with its procedural cape." % player_name
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

	print("DotGothic16 is unaffected by the isolated 32-bit arena effect; players use rectangles.")
	quit()
