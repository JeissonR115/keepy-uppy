class_name ArenaCatalog
extends Resource

@export var arenas: Array[Resource] = []


func get_valid_arenas() -> Array[ArenaData]:
	var result: Array[ArenaData] = []
	var seen_ids: Dictionary = {}
	for arena: Resource in arenas:
		if arena == null:
			push_warning("Arena catalog contains an empty entry.")
			continue
		if not arena is ArenaData:
			push_warning("Arena catalog entry does not use ArenaData.")
			continue
		var arena_data := arena as ArenaData
		var arena_id: String = arena_data.id.strip_edges()
		if arena_id.is_empty():
			push_warning("Arena catalog entry has an empty id.")
			continue
		if seen_ids.has(arena_id):
			push_warning("Arena catalog contains duplicate id '%s'." % arena_id)
			continue
		seen_ids[arena_id] = true
		if not arena_data.has_valid_metadata():
			push_warning("Arena catalog entry '%s' has invalid metadata or scene." % arena_id)
			continue
		result.append(arena_data)
	return result
