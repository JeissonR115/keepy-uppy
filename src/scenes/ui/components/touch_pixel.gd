extends Polygon2D

const FADE_DELAY := 1.3
const FADE_DURATION := 0.7


func _ready() -> void:
	var fade := create_tween()
	fade.tween_interval(FADE_DELAY)
	fade.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	fade.tween_callback(queue_free)
