extends SceneTree

const EXPECTED_PHYSICAL_KEYS := {
	"player_1_left": 65,
	"player_1_right": 68,
	"player_1_jump": 70,
	"player_1_dash": 71,
	"player_1_up": 87,
	"player_1_down": 83,
	"player_1_grab": 82,
	"player_2_left": 4194311,
	"player_2_right": 4194313,
	"player_2_jump": 49,
	"player_2_dash": 50,
	"player_2_up": 4194312,
	"player_2_down": 4194314,
	"player_2_grab": 52,
}


func _initialize() -> void:
	assert(not InputMap.has_action("player_1_accelerate"), "Player 1 manual boost action must be removed.")
	assert(not InputMap.has_action("player_2_accelerate"), "Player 2 manual boost action must be removed.")
	for action: String in EXPECTED_PHYSICAL_KEYS:
		assert(InputMap.has_action(action), "Missing Input Map action: %s" % action)
		var expected_key: int = EXPECTED_PHYSICAL_KEYS[action]
		var has_expected_key := false
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey and event.physical_keycode == expected_key:
				has_expected_key = true
				if has_expected_key:
					break
		assert(has_expected_key, "Unexpected key binding for action: %s" % action)

	print("All 14 player Input Map bindings verified.")
	quit()
