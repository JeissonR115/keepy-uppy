class_name ArenaData
extends Resource

enum SizeClassification { SMALL, MEDIUM, LARGE }

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var theme_name: String = ""
@export var recommended_players: int = 2
@export var size_classification: SizeClassification = SizeClassification.MEDIUM
@export var preview_texture: Texture2D
@export var map_scene: PackedScene
@export var playable_bounds: Rect2 = Rect2(0.0, 0.0, 320.0, 180.0)
@export var player_1_spawn: Vector2 = Vector2(72.0, 144.0)
@export var player_2_spawn: Vector2 = Vector2(248.0, 144.0)
@export var balloon_gravity_scale_multiplier: float = 1.0
@export var balloon_speed_multiplier: float = 1.0
@export var player_speed_multiplier: float = 1.0


func has_valid_metadata() -> bool:
	return (
		not id.strip_edges().is_empty()
		and not display_name.strip_edges().is_empty()
		and recommended_players > 0
		and playable_bounds.size.x > 0.0
		and playable_bounds.size.y > 0.0
		and map_scene != null
		and map_scene.can_instantiate()
	)
