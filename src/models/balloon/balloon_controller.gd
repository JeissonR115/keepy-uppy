extends RigidBody2D

signal player_hit(player: CharacterBody2D)
signal dash_rescued(player: CharacterBody2D, dash_direction: Vector2)
signal ground_touched

@export var player_hit_impulse: float = 180.0
@export var min_player_hit_impulse: float = 120.0
@export var max_player_hit_impulse: float = 240.0
@export var impact_speed_factor: float = 0.2
@export var dash_rescue_impulse: float = 300.0
@export var max_horizontal_speed: float = 360.0
@export var max_vertical_speed: float = 420.0
@export var contact_interval: float = 0.1
@export var balloon_collision_radius: float = 9.0
@export var player_contact_radius: float = 16.0
@export var gravity_strength: float = 0.7
@export var horizontal_damping: float = 0.25
@export_range(0.0, 1.0) var rebound_strength: float = 0.55

@onready var player_contact_area: Area2D = $PlayerContactArea
@onready var visual: Polygon2D = $Visual

var ground_contact_reported: bool = false
var default_visual_color: Color
var impact_tween: Tween
var player_contact_cooldowns: Dictionary = {}


func _ready() -> void:
	default_visual_color = visual.color
	gravity_scale = gravity_strength
	linear_damp = 0.0
	var physics_material := physics_material_override as PhysicsMaterial
	if physics_material != null:
		physics_material.bounce = rebound_strength
	var balloon_shape := $CollisionShape2D.shape as CircleShape2D
	balloon_shape.radius = balloon_collision_radius
	var contact_shape := player_contact_area.get_node("CollisionShape2D").shape as CircleShape2D
	contact_shape.radius = player_contact_radius
	body_entered.connect(_on_body_entered)
	player_contact_area.body_entered.connect(_on_player_contact_area_body_entered)


func _physics_process(delta: float) -> void:
	for player_id: int in player_contact_cooldowns.keys():
		player_contact_cooldowns[player_id] = maxf(
			float(player_contact_cooldowns[player_id]) - delta,
			0.0
		)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	state.linear_velocity.x /= 1.0 + maxf(horizontal_damping, 0.0) * state.step
	state.linear_velocity.x = clampf(
		state.linear_velocity.x,
		-max_horizontal_speed,
		max_horizontal_speed
	)
	state.linear_velocity.y = clampf(
		state.linear_velocity.y,
		-max_vertical_speed,
		max_vertical_speed
	)


func reset_round(spawn_position: Vector2) -> void:
	global_position = spawn_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = false
	ground_contact_reported = false
	player_contact_cooldowns.clear()


func apply_dash_rescue(player: CharacterBody2D, dash_direction: Vector2) -> bool:
	if not _accept_player_contact(player):
		return false
	var rescue_direction := dash_direction.normalized()
	if rescue_direction.is_zero_approx():
		rescue_direction = Vector2.UP
	rescue_direction.y = minf(rescue_direction.y, -0.35)
	rescue_direction = rescue_direction.normalized()
	sleeping = false
	apply_central_impulse(rescue_direction * dash_rescue_impulse)
	_flash_impact()
	dash_rescued.emit(player, rescue_direction)
	return true


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
		if not _accept_player_contact(player):
			return
		var impulse_direction := global_position - player.global_position
		if impulse_direction.is_zero_approx():
			impulse_direction = Vector2.UP
		impulse_direction = impulse_direction.normalized()
		var approach_speed := maxf(
			player.velocity.dot(impulse_direction)
			- linear_velocity.dot(impulse_direction),
			0.0
		)
		var impulse_strength := clampf(
			player_hit_impulse + approach_speed * impact_speed_factor,
			min_player_hit_impulse,
			max_player_hit_impulse
		)
		sleeping = false
		apply_central_impulse(impulse_direction * impulse_strength)
		_flash_impact()
		player_hit.emit(player)


func _accept_player_contact(player: CharacterBody2D) -> bool:
	var player_id := player.get_instance_id()
	if float(player_contact_cooldowns.get(player_id, 0.0)) > 0.0:
		return false
	player_contact_cooldowns[player_id] = contact_interval
	return true
