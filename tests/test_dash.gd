extends SceneTree

const DIRECTION_ACTIONS := [
	[],
	["player_1_right"],
	["player_1_up", "player_1_right"],
	["player_1_up"],
	["player_1_up", "player_1_left"],
	["player_1_left"],
	["player_1_down", "player_1_left"],
	["player_1_down"],
	["player_1_down", "player_1_right"],
]
const EXPECTED_DIRECTIONS := [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2(0.70710678, -0.70710678),
	Vector2.UP,
	Vector2(-0.70710678, -0.70710678),
	Vector2.LEFT,
	Vector2(-0.70710678, 0.70710678),
	Vector2.DOWN,
	Vector2(0.70710678, 0.70710678),
]
const DIRECTIONAL_ACTIONS := [
	"player_1_left",
	"player_1_right",
	"player_1_up",
	"player_1_down",
]


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _release_directional_actions() -> void:
	for action: String in DIRECTIONAL_ACTIONS:
		Input.action_release(action)


func _run_test() -> void:
	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var player: CharacterBody2D = main_scene.get_node("Arena/Player1")
	player.dash_duration = 0.06
	player.dash_cooldown = 0.1
	player.facing_direction = Vector2.LEFT

	for index in range(DIRECTION_ACTIONS.size()):
		_release_directional_actions()
		for action: String in DIRECTION_ACTIONS[index]:
			Input.action_press(action)
		Input.action_press("player_1_dash")
		await physics_frame
		await physics_frame
		if not _expect(player.is_dashing, "Dash did not activate for direction case %d." % index):
			return
		if not _expect(
			player.dash_direction.is_equal_approx(EXPECTED_DIRECTIONS[index]),
			"Unexpected dash direction for case %d: %s" % [index, player.dash_direction]
		):
			return
		if not _expect(player.dash_trail.visible, "Dash trail was not visible during dash case %d." % index):
			return

		Input.action_release("player_1_dash")
		_release_directional_actions()
		for _frame in range(9):
			await physics_frame
		if not _expect(not player.dash_trail.visible, "Dash trail remained visible after dash case %d." % index):
			return

	player.dash_duration = 0.05
	player.dash_cooldown = 0.3
	Input.action_press("player_1_right")
	Input.action_press("player_1_dash")
	await physics_frame
	await physics_frame
	Input.action_release("player_1_dash")
	Input.action_release("player_1_right")
	for _frame in range(5):
		await physics_frame

	Input.action_press("player_1_dash")
	await physics_frame
	await physics_frame
	if not _expect(not player.is_dashing, "Dash activated while its cooldown was active."):
		return

	print("Eight-way dash, facing fallback, and cooldown verified.")
	quit()
