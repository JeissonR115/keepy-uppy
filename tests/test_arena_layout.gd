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
	var arena: Node = main_scene.get_node("Arena")
	var required_surfaces := ["ScoringGround", "LeftWall", "RightWall"]
	for surface_name: String in required_surfaces:
		if not _expect(arena.get_node_or_null(surface_name) is StaticBody2D, "%s arena boundary is missing." % surface_name):
			return
	for platform_name: String in ["PlatformLeft", "PlatformCenter", "PlatformRight"]:
		if not _expect(arena.get_node_or_null(platform_name) == null, "%s is still instanced in the arena." % platform_name):
			return
	var static_bodies := arena.find_children("*", "StaticBody2D", true, false)
	if not _expect(static_bodies.size() == 3, "The arena still contains an extra static platform collision body."):
		return
	print("Floor-only arena with side boundaries and no elevated platform bodies verified.")
	quit()
