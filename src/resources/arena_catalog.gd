class_name ArenaCatalog
extends Resource

const ArenaDataResource = preload("res://src/resources/arena_data.gd")

@export var arenas: Array[Resource] = []


func get_valid_arenas() -> Array[Resource]:
	var result: Array[Resource] = []
	var seen_ids: Dictionary = {}
	for arena: Resource in arenas:
		if arena == null:
			push_warning("Arena catalog contains an empty entry.")
			continue
		if not arena is ArenaDataResource:
			push_warning("Arena catalog entry does not use ArenaData.")
			continue
		var arena_id: String = str(arena.get("id")).strip_edges()
		if arena_id.is_empty():
			push_warning("Arena catalog entry has an empty id.")
			continue
		if seen_ids.has(arena_id):
			push_warning("Arena catalog contains duplicate id '%s'." % arena_id)
			continue
		seen_ids[arena_id] = true
		if not bool(arena.call("has_valid_metadata")):
			push_warning("Arena catalog entry '%s' has invalid metadata or scene." % arena_id)
			continue
		result.append(arena)
	return result
