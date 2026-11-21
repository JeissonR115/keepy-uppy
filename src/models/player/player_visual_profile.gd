extends Resource

@export var body_frames: SpriteFrames
@export var effect_frames: SpriteFrames
@export var tint: Color = Color.WHITE
@export var shared_settings: PlayerVisualSettings
@export var hair_enabled: bool = false
@export var hair_anchor_a: Vector2 = Vector2(1.0, -15.0)
@export var hair_anchor_b: Vector2 = Vector2(1.0, -15.0)
@export var hair_color: Color = Color("#ad4045")
@export var dash_afterimage_tint: Color = Color(0.62, 0.82, 1.0, 0.55)
@export var body_animation_map: Dictionary = {}
@export var effect_animation_map: Dictionary = {}
