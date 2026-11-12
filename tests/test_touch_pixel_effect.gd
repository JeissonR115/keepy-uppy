extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var main_scene := (load("res://src/scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main_scene)
	await process_frame
	paused = false
	var arena: Node = main_scene.get_node("Arena")
	var player: PlayerController = arena.get_node("Player1")
	var balloon: BalloonController = arena.get_node("Balloon")
	var player_world_position := player.global_position + Vector2(6.0, 0.0)
	var balloon_world_position := balloon.global_position + Vector2(-7.0, 0.0)
	var expected_player_local := player.to_local(player_world_position)
	var expected_balloon_local := balloon.to_local(balloon_world_position)
	player.show_touch_pixel(player_world_position)
	balloon.show_contact_pixel(balloon_world_position)
	await process_frame
	var player_pixel := player.get_node("TouchPixel") as Polygon2D
	var balloon_pixel := balloon.get_node("TouchPixel") as Polygon2D
	if not _expect(player_pixel != null and balloon_pixel != null, "Both contact owners must instantiate the shared effect scene."):
		quit(1)
		return
	if not _expect(
		player_pixel.position.distance_to(expected_player_local) < 0.01
		and balloon_pixel.position.distance_to(expected_balloon_local) < 0.01,
		"Shared contact effects did not preserve parent-local world placement."
	):
		quit(1)
		return
	if not _expect(
		player_pixel.z_index == 5
		and balloon_pixel.z_index == 5
		and player_pixel.polygon.size() == 4
		and balloon_pixel.polygon.size() == 4,
		"Shared contact effects changed their z-order or square shape."
	):
		quit(1)
		return
	await create_timer(2.1).timeout
	if not _expect(
		not is_instance_valid(player_pixel) and not is_instance_valid(balloon_pixel),
		"Shared contact effects did not free themselves after their two-second fade."
	):
		quit(1)
		return
	print("Player and balloon share the same positioned, layered, two-second contact effect.")
	quit()


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
