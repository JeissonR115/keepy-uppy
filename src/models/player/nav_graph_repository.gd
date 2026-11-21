class_name NavGraphRepository
extends RefCounted

const NAV_GRAPH_SCRIPT := preload("res://src/models/player/nav_graph.gd")
const GRAPH_DIRECTORY := "res://data/nav_graphs/"


static func load_for_level(level_id: String) -> Dictionary:
	if level_id.is_empty() or level_id.contains("/") or level_id.contains("\\"):
		return {"graph": null, "error": "Invalid navigation graph level id."}
	var path := GRAPH_DIRECTORY + level_id + ".json"
	if not FileAccess.file_exists(path):
		return {"graph": null, "error": "Navigation graph not found: %s" % path}
	return parse_json(level_id, FileAccess.get_file_as_string(path))


static func parse_json(level_id: String, json_text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(json_text)
	if not parsed is Dictionary:
		return {"graph": null, "error": "Navigation graph is not a JSON object."}
	var graph: NavGraph = NAV_GRAPH_SCRIPT.new()
	if not graph.load_graph(parsed, level_id):
		return {"graph": null, "error": graph.last_error}
	return {"graph": graph, "error": ""}
