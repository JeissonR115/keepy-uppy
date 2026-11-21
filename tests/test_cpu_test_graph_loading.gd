extends SceneTree

const NAV_GRAPH_REPOSITORY := preload("res://src/models/player/nav_graph_repository.gd")
const TEST_CPU_BRAIN := preload("res://src/models/player/test_cpu_brain.gd")


func _initialize() -> void:
	call_deferred("_run_test")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _run_test() -> void:
	var catalog := load("res://src/resources/arena_catalog.tres") as ArenaCatalog
	var arenas := catalog.get_valid_arenas()
	if not _expect(arenas.size() == 4, "Expected four registered arena graphs."):
		return
	for arena: ArenaData in arenas:
		var result: Dictionary = NAV_GRAPH_REPOSITORY.load_for_level(arena.id)
		var graph: NavGraph = result.get("graph") as NavGraph
		if not _expect(
			graph != null
			and graph.level_id == arena.id
			and graph.get_point_count() > 0
			and graph.get_edge_count() > 0,
			"Could not load a valid graph for %s: %s" % [arena.id, result.get("error", "")]
		):
			return

	var missing: Dictionary = NAV_GRAPH_REPOSITORY.load_for_level("no-such-arena")
	if not _expect(
		missing.get("graph") == null and not str(missing.get("error", "")).is_empty(),
		"A missing graph did not return a recoverable error."
	):
		return
	var malformed: Dictionary = NAV_GRAPH_REPOSITORY.parse_json("classic", "not-json")
	if not _expect(
		malformed.get("graph") == null and not str(malformed.get("error", "")).is_empty(),
		"Malformed graph data did not return a recoverable error."
	):
		return
	var wrong_level := NAV_GRAPH_REPOSITORY.parse_json(
		"classic",
		'{"schema_version":1,"level":"sky-towers","nodes":[{"id":1,"position":{"x":0,"y":0}}],"edges":[]}'
	)
	if not _expect(
		wrong_level.get("graph") == null
		and not str(wrong_level.get("error", "")).is_empty(),
		"A graph for a different arena was accepted."
	):
		return

	var main_scene: Node = load("res://src/scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	var menu: PlayerCountMenu = main_scene.get_node("PlayerCountMenu")
	menu._select_player_count(1)
	menu._select_level("classic")
	await process_frame
	root.get_tree().paused = true
	var arena: Node = main_scene.get_node("Arena")
	var level_manager: LevelManager = arena.get_node("LevelManager")
	var player: PlayerController = arena.get_node("Player2")
	var match_manager: MatchManager = arena.get_node("MatchManager")
	var balloon: BalloonController = arena.get_node("Balloon")
	if not _expect(
		level_manager.active_nav_graph != null
		and level_manager.active_nav_graph.level_id == "classic",
		"Level selection did not load the graph for the active arena."
	):
		return
	match_manager.match_state = MatchManager.MatchState.ACTIVE
	match_manager.expected_balloon_player = player
	player.bot_enabled = true
	balloon.waiting_for_first_touch = false
	var fallback_brain = TEST_CPU_BRAIN.new(player)
	player.cpu_controller.set_brain(fallback_brain)
	fallback_brain.decide(1.0 / 60.0)
	fallback_brain.set_graph(null)
	fallback_brain.decide(1.0 / 60.0)
	if not _expect(
		fallback_brain.fallback_brain != null
		and fallback_brain.reason == "No valid graph is loaded for this arena.",
		"Test CPU did not use LocalBrain when its graph is unavailable."
	):
		return
	print("Test CPU graph repository loads bundled arenas and safely rejects missing or invalid data.")
	quit()
