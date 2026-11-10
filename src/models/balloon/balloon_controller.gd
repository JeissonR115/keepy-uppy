extends RigidBody2D

signal player_hit(player: CharacterBody2D)
signal dash_rescued(player: CharacterBody2D, dash_direction: Vector2)
signal ground_touched

@export var player_hit_impulse: float = 180.0
@export var dash_rescue_impulse: float = 300.0
@export var max_speed: float = 420.0

@onready var player_contact_area: Area2D = $PlayerContactArea
@onready var visual: Polygon2D = $Visual

var ground_contact_reported: bool = false
var default_visual_color: Color
var impact_tween: Tween


func _ready() -> void:
	default_visual_color = visual.color
	body_entered.connect(_on_body_entered)
	player_contact_area.body_entered.connect(_on_player_contact_area_body_entered)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	state.linear_velocity = state.linear_velocity.limit_length(max_speed)


func reset_round(spawn_position: Vector2) -> void:
	global_position = spawn_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = false
	ground_contact_reported = false


func apply_dash_rescue(player: CharacterBody2D, dash_direction: Vector2) -> void:
	var rescue_direction := dash_direction.normalized()
	if rescue_direction.is_zero_approx():
		rescue_direction = Vector2.UP
	rescue_direction.y = minf(rescue_direction.y, -0.35)
	rescue_direction = rescue_direction.normalized()
	sleeping = false
	apply_central_impulse(rescue_direction * dash_rescue_impulse)
	_flash_impact()
	dash_rescued.emit(player, rescue_direction)


func _flash_impact() -> void:
	if impact_tween != null and impact_tween.is_running():
		impact_tween.kill()
	visual.color = Color.WHITE
	impact_tween = create_tween()
	impact_tween.tween_property(visual, "color", default_visual_color, 0.18)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("scoring_ground") and not ground_contact_reported:
		ground_contact_reported = true
		ground_touched.emit()


func _on_player_contact_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("players"):
		var player := body as CharacterBody2D
		var impulse_direction := global_position - player.global_position
		if impulse_direction.is_zero_approx():
			impulse_direction = Vector2.UP
		sleeping = false
		apply_central_impulse(impulse_direction.normalized() * player_hit_impulse)
		_flash_impact()
		player_hit.emit(player)
