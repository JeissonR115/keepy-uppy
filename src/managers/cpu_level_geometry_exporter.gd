class_name CPULevelGeometryExporter
extends RefCounted

const MOVEMENT_CONSTANTS_PATH := "res://src/models/player/player_movement_constants.gd"


static func export_arena(arena: ArenaData) -> Dictionary:
	if arena == null or not arena.has_valid_metadata():
		push_error("Cannot export geometry for an invalid arena.")
		return {}
	var map_instance := arena.map_scene.instantiate()
	if not map_instance is Node2D:
		push_error("Arena '%s' geometry root must extend Node2D." % arena.id)
		map_instance.free()
		return {}

	var collisions: Array[Dictionary] = []
	var platforms: Array[Dictionary] = []
	var errors: Array[String] = []
	_collect_node_geometry(
		map_instance as Node2D,
		map_instance as Node2D,
		collisions,
		platforms,
		errors
	)
	map_instance.free()
	if not errors.is_empty():
		for error_message: String in errors:
			push_error("Arena '%s' geometry export failed: %s" % [arena.id, error_message])
		return {}

	var bounds := arena.playable_bounds
	var safe_bounds := Rect2(bounds.position + arena.safe_margin, bounds.size - arena.safe_margin * 2.0)
	return {
		"schema_version": 1,
		"level": arena.id,
		"bounds": _rect_to_json(bounds),
		"safe_bounds": _rect_to_json(safe_bounds),
		"spawns": {
			"player_1": _vector_to_json(arena.player_1_spawn),
			"player_2": _vector_to_json(arena.player_2_spawn),
		},
		"auxiliary_bounds": _get_auxiliary_bounds(safe_bounds),
		"collisions": collisions,
		"platforms": platforms,
		"movement_constants": _get_movement_constants(),
	}


static func _collect_node_geometry(
	node: Node,
	map_root: Node2D,
	collisions: Array[Dictionary],
	platforms: Array[Dictionary],
	errors: Array[String]
) -> void:
	if node is TileMapLayer:
		_collect_tile_map(node as TileMapLayer, collisions, platforms)
	elif node is CollisionShape2D:
		var shape_node := node as CollisionShape2D
		if not shape_node.disabled and shape_node.shape != null:
			var owner := _find_collision_object(shape_node)
			var descriptor := _shape_to_json(shape_node.shape)
			if owner == null:
				errors.append("CollisionShape2D '%s' has no CollisionObject2D owner." % shape_node.name)
			elif descriptor.is_empty():
				errors.append(
					"Unsupported collision shape '%s' on '%s'."
					% [shape_node.shape.get_class(), shape_node.name]
				)
			else:
				var item := {
					"source": str(map_root.get_path_to(shape_node)),
					"shape": descriptor,
					"transform": _transform_to_json(shape_node.global_transform),
					"collision_layer": owner.collision_layer,
					"collision_mask": owner.collision_mask,
					"one_way": shape_node.one_way_collision,
				}
				if shape_node.one_way_collision:
					item["one_way_margin"] = shape_node.one_way_collision_margin
					platforms.append(item)
				else:
					collisions.append(item)
	elif node is CollisionPolygon2D:
		var polygon_node := node as CollisionPolygon2D
		if not polygon_node.disabled and polygon_node.polygon.size() >= 3:
			var owner := _find_collision_object(polygon_node)
			if owner == null:
				errors.append("CollisionPolygon2D '%s' has no CollisionObject2D owner." % polygon_node.name)
			else:
				var item := {
					"source": str(map_root.get_path_to(polygon_node)),
					"points": _points_to_json(polygon_node.polygon),
					"transform": _transform_to_json(polygon_node.global_transform),
					"collision_layer": owner.collision_layer,
					"collision_mask": owner.collision_mask,
					"one_way": polygon_node.one_way_collision,
				}
				if polygon_node.one_way_collision:
					item["one_way_margin"] = polygon_node.one_way_collision_margin
					platforms.append(item)
				else:
					collisions.append(item)

	for child: Node in node.get_children():
		_collect_node_geometry(child, map_root, collisions, platforms, errors)


static func _collect_tile_map(
	layer: TileMapLayer,
	collisions: Array[Dictionary],
	platforms: Array[Dictionary]
) -> void:
	var tile_set := layer.tile_set
	if tile_set == null:
		return
	for cell: Vector2i in layer.get_used_cells():
		var tile_data := layer.get_cell_tile_data(cell)
		if tile_data == null:
			continue
		var alternative := layer.get_cell_alternative_tile(cell)
		for physics_layer in range(tile_set.get_physics_layers_count()):
			var polygon_count := tile_data.get_collision_polygons_count(physics_layer)
			for polygon_index in range(polygon_count):
				var one_way := tile_data.is_collision_polygon_one_way(physics_layer, polygon_index)
				var item := {
					"source": str(layer.name),
					"cell": {"x": cell.x, "y": cell.y},
					"cell_position": _vector_to_json(layer.to_global(layer.map_to_local(cell))),
					"cell_transform": {
						"alternative": alternative,
						"flip_h": (alternative & TileSetAtlasSource.TRANSFORM_FLIP_H) != 0,
						"flip_v": (alternative & TileSetAtlasSource.TRANSFORM_FLIP_V) != 0,
						"transpose": (alternative & TileSetAtlasSource.TRANSFORM_TRANSPOSE) != 0,
					},
					"physics_layer": physics_layer,
					"collision_layer": tile_set.get_physics_layer_collision_layer(physics_layer),
					"collision_mask": tile_set.get_physics_layer_collision_mask(physics_layer),
					"points": _points_to_json(
						tile_data.get_collision_polygon_points(physics_layer, polygon_index)
					),
					"one_way": one_way,
					"one_way_margin": tile_data.get_collision_polygon_one_way_margin(
						physics_layer, polygon_index
					),
				}
				if one_way:
					platforms.append(item)
				else:
					collisions.append(item)


static func _find_collision_object(node: Node) -> CollisionObject2D:
	var ancestor := node.get_parent()
	while ancestor != null:
		if ancestor is CollisionObject2D:
			return ancestor as CollisionObject2D
		ancestor = ancestor.get_parent()
	return null


static func _shape_to_json(shape: Shape2D) -> Dictionary:
	if shape is RectangleShape2D:
		return {"type": "rectangle", "size": _vector_to_json((shape as RectangleShape2D).size)}
	if shape is CircleShape2D:
		return {"type": "circle", "radius": (shape as CircleShape2D).radius}
	if shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		return {"type": "capsule", "radius": capsule.radius, "height": capsule.height}
	if shape is SegmentShape2D:
		var segment := shape as SegmentShape2D
		return {
			"type": "segment",
			"a": _vector_to_json(segment.a),
			"b": _vector_to_json(segment.b),
		}
	if shape is ConvexPolygonShape2D:
		return {
			"type": "convex_polygon",
			"points": _points_to_json((shape as ConvexPolygonShape2D).points),
		}
	if shape is ConcavePolygonShape2D:
		return {
			"type": "concave_polygon",
			"segments": _points_to_json((shape as ConcavePolygonShape2D).segments),
		}
	if shape is WorldBoundaryShape2D:
		var boundary := shape as WorldBoundaryShape2D
		return {
			"type": "world_boundary",
			"normal": _vector_to_json(boundary.normal),
			"distance": boundary.distance,
		}
	if shape is SeparationRayShape2D:
		var ray := shape as SeparationRayShape2D
		return {
			"type": "separation_ray",
			"length": ray.length,
			"slide_on_slope": ray.slide_on_slope,
		}
	return {}


static func _get_movement_constants() -> Dictionary:
	var movement_script := load(MOVEMENT_CONSTANTS_PATH) as GDScript
	if movement_script == null:
		push_error("Could not load PlayerMovementConstants for geometry export.")
		return {}
	var result: Dictionary = {}
	var source_constants := movement_script.get_script_constant_map()
	for key: Variant in source_constants:
		var value: Variant = source_constants[key]
		if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
			result[str(key)] = value
	return result


static func _get_auxiliary_bounds(safe_bounds: Rect2) -> Array[Dictionary]:
	var depth := LevelManager.SAFE_BOUNDARY_THICKNESS
	return [
		{
			"name": "SafeLeftBoundary",
			"center": _vector_to_json(
				Vector2(safe_bounds.position.x - depth * 0.5, safe_bounds.get_center().y)
			),
			"size": _vector_to_json(Vector2(depth, safe_bounds.size.y + depth * 2.0)),
		},
		{
			"name": "SafeRightBoundary",
			"center": _vector_to_json(
				Vector2(safe_bounds.end.x + depth * 0.5, safe_bounds.get_center().y)
			),
			"size": _vector_to_json(Vector2(depth, safe_bounds.size.y + depth * 2.0)),
		},
		{
			"name": "SafeCeilingBoundary",
			"center": _vector_to_json(
				Vector2(safe_bounds.get_center().x, safe_bounds.position.y - depth * 0.5)
			),
			"size": _vector_to_json(Vector2(safe_bounds.size.x, depth)),
		},
	]


static func _rect_to_json(rect: Rect2) -> Dictionary:
	return {"position": _vector_to_json(rect.position), "size": _vector_to_json(rect.size)}


static func _transform_to_json(transform: Transform2D) -> Dictionary:
	return {
		"origin": _vector_to_json(transform.origin),
		"x_axis": _vector_to_json(transform.x),
		"y_axis": _vector_to_json(transform.y),
	}


static func _points_to_json(points: PackedVector2Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for point: Vector2 in points:
		result.append(_vector_to_json(point))
	return result


static func _vector_to_json(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}
