class_name PlayerActionCatalog
extends RefCounted

const PLAYER_ONE_PREFIX := "player_1"
const PLAYER_TWO_PREFIX := "player_2"
const ACTION_LEFT := "left"
const ACTION_RIGHT := "right"
const ACTION_UP := "up"
const ACTION_DOWN := "down"
const ACTION_JUMP := "jump"
const ACTION_DASH := "dash"
const ACTION_ACCELERATE := "accelerate"

const PLAYERS: Array[Dictionary] = [
	{
		"prefix": PLAYER_ONE_PREFIX,
		"heading": "PLAYER 1",
		"color": Color(0.290196, 0.764706, 0.843137),
		"actions": [
			{"suffix": ACTION_LEFT, "label": "LEFT", "default_key": KEY_A},
			{"suffix": ACTION_RIGHT, "label": "RIGHT", "default_key": KEY_D},
			{"suffix": ACTION_UP, "label": "UP", "default_key": KEY_W},
			{"suffix": ACTION_DOWN, "label": "DOWN", "default_key": KEY_S},
			{"suffix": ACTION_JUMP, "label": "JUMP", "default_key": KEY_F},
			{"suffix": ACTION_DASH, "label": "DASH", "default_key": KEY_G},
			{"suffix": ACTION_ACCELERATE, "label": "BOOST", "default_key": KEY_H},
		],
	},
	{
		"prefix": PLAYER_TWO_PREFIX,
		"heading": "PLAYER 2",
		"color": Color(1.0, 0.584314, 0.427451),
		"actions": [
			{"suffix": ACTION_LEFT, "label": "LEFT", "default_key": KEY_LEFT},
			{"suffix": ACTION_RIGHT, "label": "RIGHT", "default_key": KEY_RIGHT},
			{"suffix": ACTION_UP, "label": "UP", "default_key": KEY_UP},
			{"suffix": ACTION_DOWN, "label": "DOWN", "default_key": KEY_DOWN},
			{"suffix": ACTION_JUMP, "label": "JUMP", "default_key": KEY_1},
			{"suffix": ACTION_DASH, "label": "DASH", "default_key": KEY_2},
			{"suffix": ACTION_ACCELERATE, "label": "BOOST", "default_key": KEY_3},
		],
	},
]


static func action_name(player_prefix: String, action_suffix: String) -> String:
	return "%s_%s" % [player_prefix, action_suffix]


static func action_names() -> Array[String]:
	var names: Array[String] = []
	for player_data: Dictionary in PLAYERS:
		for action_data: Dictionary in player_data.actions:
			names.append(action_name(player_data.prefix, action_data.suffix))
	return names


static func default_physical_keys() -> Dictionary:
	var keys: Dictionary = {}
	for player_data: Dictionary in PLAYERS:
		for action_data: Dictionary in player_data.actions:
			keys[action_name(player_data.prefix, action_data.suffix)] = action_data.default_key
	return keys


static func player_color(player_prefix: String) -> Color:
	for player_data: Dictionary in PLAYERS:
		if player_data.prefix == player_prefix:
			return player_data.color
	return Color.WHITE
