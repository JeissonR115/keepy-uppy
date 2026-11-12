extends Area2D

const DashTechniques = preload("res://src/models/player/player_dash_techniques.gd")

signal expired(afterimage: Area2D)

@onready var ghost_sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var owner_player: CharacterBody2D


func configure(
	player: CharacterBody2D,
	source_sprite: AnimatedSprite2D,
	rescue_size: Vector2,
	ghost_tint: Color,
	lifetime: float
) -> void:
	owner_player = player
	global_position = player.global_position.round()
	ghost_sprite.texture = source_sprite.sprite_frames.get_frame_texture(
		source_sprite.animation, source_sprite.frame
	)
	ghost_sprite.position = source_sprite.global_position.round() - global_position
	ghost_sprite.global_scale = source_sprite.global_scale
	ghost_sprite.flip_h = source_sprite.flip_h
	ghost_sprite.offset = source_sprite.offset
	ghost_sprite.modulate = ghost_tint
	ghost_sprite.z_index = source_sprite.z_index - 1
	var rectangle := RectangleShape2D.new()
	rectangle.size = rescue_size
	collision_shape.shape = rectangle
	body_entered.connect(_on_body_entered)
	var fade := create_tween()
	fade.tween_property(ghost_sprite, "modulate:a", 0.0, lifetime)
	fade.tween_callback(_expire)


func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(owner_player):
		DashTechniques.handle_trail_rescue_body(owner_player, body)


func _expire() -> void:
	expired.emit(self)
	queue_free()
