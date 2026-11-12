extends SceneTree

const MovementConstants = preload("res://src/models/player/player_movement_constants.gd")

var rescued_count := 0


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _on_dash_rescued(_player: CharacterBody2D, _direction: Vector2) -> void:
	rescued_count += 1


func _run_test() -> void:
	var main_scene := (load("res://src/scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main_scene)
	await process_frame
	var main_menu: Node = main_scene.get_node("PlayerCountMenu")
	main_scene.get_node("PlayerCountMenu/Panel/MenuScroll/Margins/Content/TwoPlayersButton").pressed.emit()
	main_menu._select_level("classic")
	await physics_frame
	var arena: Node = main_scene.get_node("Arena")
	var player: PlayerController = arena.get_node("Player1")
	var balloon: BalloonController = arena.get_node("Balloon")
	var match_manager: MatchManager = arena.get_node("MatchManager")
	balloon.dash_rescued.connect(_on_dash_rescued)
	match_manager.set_next_server(player)
	player.reset_for_round(Vector2(112, 90))
	balloon.reset_round(Vector2(280, 48))
	balloon.gravity_scale = 0.0
	Input.action_press("player_1_right")
	Input.action_press("player_1_dash")
	for _frame in range(30):
		await physics_frame
		if not player.is_dashing and player.presentation.dash_afterimages_spawned == MovementConstants.DASH_AFTERIMAGE_COUNT:
			break
	Input.action_release("player_1_right")
	Input.action_release("player_1_dash")
	if not _expect(
		player.presentation.dash_afterimages_spawned == MovementConstants.DASH_AFTERIMAGE_COUNT
		and not player.presentation.active_afterimages.is_empty()
		and not player.dash_rescue_area.monitoring,
		"Dash did not leave six fading, rescue-enabled sprite afterimages."
	):
		return
	if not _expect(rescued_count == 0 and not player.dash_rescue_hit, "The balloon was unexpectedly rescued before contacting the dash trail."):
		return
	var final_ghost := player.presentation.active_afterimages.back() as Area2D
	var final_ghost_sprite := final_ghost.get_node("Sprite") as Sprite2D
	if not _expect(
		final_ghost_sprite.texture != null
		and final_ghost_sprite.modulate.a > 0.0
		and final_ghost.collision_mask == 4
		and final_ghost.collision_layer == 0,
		"Afterimage does not repeat the player sprite with a translucent visual-only rescue sensor."
	):
		return
	player.is_dashing = true
	player._on_dash_rescue_area_body_entered(balloon)
	player.is_dashing = false
	if not _expect(rescued_count == 1 and player.dash_rescue_hit, "The primary dash rescue could not be established for the extra-trail test."):
		return
	for _frame in range(7):
		await physics_frame
	balloon.global_position = final_ghost.global_position
	balloon.linear_velocity = Vector2.ZERO
	for _frame in range(3):
		await physics_frame
	if not _expect(
		rescued_count == 2 and player.presentation.dash_trail_rescue_hit,
		"The trailing dash sprites did not provide exactly one additional rescue touch."
	):
		return
	for _frame in range(4):
		await physics_frame
	if not _expect(rescued_count == 2, "The six afterimage areas provided more than one additional rescue touch."):
		return
	for _frame in range(18):
		await physics_frame
	if not _expect(
		player.presentation.active_afterimages.is_empty()
		and player.presentation.dash_afterimages_spawned == MovementConstants.DASH_AFTERIMAGE_COUNT,
		"Dash afterimages or their rescue window outlived the configured fade."
	):
		return
	main_scene.queue_free()
	await process_frame
	print("Six pixel-tinted dash afterimages fade out and extend one rescue opportunity.")
	quit()
