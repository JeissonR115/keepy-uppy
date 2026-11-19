class_name FanCurrent
extends Area2D

@export var air_direction: Vector2 = Vector2.UP
@export_range(0.0, 12000.0, 50.0) var force_strength: float = 2200.0
@export var current_half_extents: Vector2 = Vector2(44.0, 28.0)

@onready var current_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	var rectangle := current_shape.shape.duplicate() as RectangleShape2D
	rectangle.size = current_half_extents * 2.0
	current_shape.shape = rectangle


func _physics_process(_delta: float) -> void:
	if air_direction.is_zero_approx() or is_zero_approx(force_strength):
		return
	var world_direction := global_transform.basis_xform(air_direction).normalized()
	for body in get_overlapping_bodies():
		if body is RigidBody2D and body.is_in_group("balloon"):
			body.apply_central_force(world_direction * force_strength)
