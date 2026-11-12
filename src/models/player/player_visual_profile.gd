extends Resource

@export var body_frames: SpriteFrames
@export var effect_frames: SpriteFrames
@export var tint: Color = Color.WHITE
@export var anchor_a: Vector2 = Vector2(8.0, -8.0)
@export var anchor_b: Vector2 = Vector2(-8.0, -8.0)
@export var hair_enabled: bool = false
@export var cape_enabled: bool = true
@export var hair_anchor_a: Vector2 = Vector2(-4.0, -11.0)
@export var hair_anchor_b: Vector2 = Vector2(1.0, -11.0)
@export var hair_color: Color = Color(0.72, 0.16, 0.22, 1.0)
@export var body_animation_map: Dictionary = {}
@export var effect_animation_map: Dictionary = {}
