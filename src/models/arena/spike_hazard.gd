class_name SpikeHazard
extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("explode_on_spikes"):
		body.call("explode_on_spikes")
