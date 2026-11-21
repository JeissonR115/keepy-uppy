class_name BalloonController
extends RigidBody2D

const TOUCH_PIXEL_SCENE := preload("res://src/scenes/ui/components/touch_pixel.tscn")

signal player_hit(player: CharacterBody2D)
signal dash_rescued(player: CharacterBody2D, dash_direction: Vector2)
signal contact_visualized(player: CharacterBody2D, balloon_position: Vector2)
signal ground_touched
signal spikes_touched

@export var player_hit_impulse: float = 180.0
@export var min_player_hit_impulse: float = 120.0
@export var max_player_hit_impulse: float = 340.0
@export var impact_speed_factor: float = 0.2
@export var dash_rescue_impulse: float = 350.0
@export var max_dash_rescue_impulse: float = 360.0
@export var movement_direction_factor: float = 0.45
@export var dash_movement_direction_factor: float = 0.4
@export var movement_impulse_factor: float = 0.12
@export var max_horizontal_speed: float = 220.0
@export_range(1.0, 600.0, 1.0) var max_fall_speed: float = 90.0
@export_range(1.0, 900.0, 1.0) var max_hit_speed: float = 220.0
@export var contact_interval: float = 0.1
@export_range(0.1, 10.0, 0.1) var downward_warning_duration: float = 1.5
@export var balloon_collision_radius: float = 9.0
@export var player_contact_radius: float = 16.0
@export var gravity_strength: float = 0.14
@export var trampoline_rebound_speed: float = 180.0
@export var air_resistance: float = 0.055
@export var horizontal_damping: float = 0.08
@export_range(0.0, 1.0) var rebound_strength: float = 0.28

const BALLOON_REF_SPEED := 240.0

@onready var player_contact_area: Area2D = $PlayerContactArea
@onready var visual: Polygon2D = $Visual
@onready var string_visual: Line2D = $String
@onready var ground_burst: AnimatedSprite2D = $GroundBurst
@onready var balloon_collision_shape: CollisionShape2D = $CollisionShape2D
@onready var player_contact_shape: CollisionShape2D = $PlayerContactArea/CollisionShape2D
@onready var audio_manager: Node = get_node("/root/AudioManager")

var ground_contact_reported: bool = false
var spike_contact_reported: bool = false
var scoring_ground_contact_from_above: bool = false
var waiting_for_first_touch: bool = false
var waiting_spawn_position: Vector2 = Vector2.ZERO
var default_visual_color: Color
var current_turn_color: Color = Color.WHITE
var impact_tween: Tween
var player_contact_cooldowns: Dictionary = {}
var pending_contact_impulses: Dictionary = {}
var downward_warning_time_left: float = 0.0
var downward_warning_elapsed: float = 0.0
var downward_warning_color: Color = Color.WHITE
var player_contacts_armed: bool = false
var setup_overlap_player_ids: Dictionary = {}

enum ContactType { NORMAL, DASH_RESCUE }


func _ready() -> void:
	default_visual_color = visual.color
	current_turn_color = default_visual_color
	gravity_scale = gravity_strength
	linear_damp = 0.0
	var physics_material := physics_material_override as PhysicsMaterial
	if physics_material != null:
		physics_material.bounce = rebound_strength
	var balloon_shape := balloon_collision_shape.shape as CircleShape2D
	balloon_shape.radius = balloon_collision_radius
	var contact_shape := player_contact_shape.shape as CircleShape2D
	contact_shape.radius = player_contact_radius
	body_entered.connect(_on_body_entered)
	player_contact_area.body_entered.connect(_on_player_contact_area_body_entered)
	player_contact_area.body_exited.connect(_on_player_contact_area_body_exited)
	ground_burst.animation_finished.connect(_on_ground_burst_animation_finished)


func _physics_process(delta: float) -> void:
	if downward_warning_time_left > 0.0:
		downward_warning_time_left = maxf(downward_warning_time_left - delta, 0.0)
		downward_warning_elapsed += delta
		if downward_warning_time_left <= 0.0:
			clear_downward_warning()
		else:
			var flash_phase := int(floor(downward_warning_elapsed / 0.12)) % 2
			visual.color = Color.WHITE if flash_phase == 0 else downward_warning_color
	for player_id: int in player_contact_cooldowns.keys():
		player_contact_cooldowns[player_id] = maxf(
			float(player_contact_cooldowns[player_id]) - delta,
			0.0
		)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	scoring_ground_contact_from_above = false
	for contact_index in state.get_contact_count():
		var collider := state.get_contact_collider_object(contact_index) as Node
		if collider == null or not collider.is_in_group("scoring_ground"):
			continue
		var contact_normal := state.transform.basis_xform(
			state.get_contact_local_normal(contact_index)
		).normalized()
		if contact_normal.y < -0.5:
			scoring_ground_contact_from_above = true
			break
	if waiting_for_first_touch:
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		var stopped_transform := state.transform
		stopped_transform.origin = waiting_spawn_position
		state.transform = stopped_transform
		return

	var air_retention := 1.0 + maxf(air_resistance, 0.0) * state.step
	state.linear_velocity /= air_retention
	state.linear_velocity.x /= 1.0 + maxf(horizontal_damping, 0.0) * state.step
	state.linear_velocity.x = clampf(
		state.linear_velocity.x,
		-max_horizontal_speed,
		max_horizontal_speed
	)
	state.linear_velocity.y = clampf(
		state.linear_velocity.y,
		-max_hit_speed,
		max_fall_speed
	)


func reset_round(spawn_position: Vector2, wait_for_first_touch: bool = false) -> void:
	clear_downward_warning()
	if impact_tween != null and impact_tween.is_running():
		impact_tween.kill()
	freeze = false
	visual.color = default_visual_color
	visual.visible = true
	string_visual.visible = true
	balloon_collision_shape.set_deferred("disabled", false)
	player_contact_area.monitoring = true
	player_contacts_armed = false
	setup_overlap_player_ids.clear()
	global_position = spawn_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = false
	self.waiting_for_first_touch = wait_for_first_touch
	waiting_spawn_position = position
	gravity_scale = 0.0 if wait_for_first_touch else gravity_strength
	ground_contact_reported = false
	spike_contact_reported = false
	player_contact_cooldowns.clear()
	pending_contact_impulses.clear()
	ground_burst.stop()
	ground_burst.frame = 0
	ground_burst.visible = false


func prepare_for_round() -> void:
	clear_downward_warning()
	if impact_tween != null and impact_tween.is_running():
		impact_tween.kill()
	visual.visible = false
	string_visual.visible = false
	balloon_collision_shape.set_deferred("disabled", true)
	player_contact_area.monitoring = false
	ground_burst.stop()
	ground_burst.frame = 0
	ground_burst.visible = false
	player_contacts_armed = false
	setup_overlap_player_ids.clear()
	waiting_for_first_touch = true
	gravity_scale = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	pending_contact_impulses.clear()
	disarm_player_contacts()


func disarm_player_contacts() -> void:
	player_contacts_armed = false
	setup_overlap_player_ids.clear()
	player_contact_area.set_deferred("monitoring", false)


func is_downward_warning_active() -> bool:
	return downward_warning_time_left > 0.0


func start_downward_warning(player_color: Color) -> void:
	if impact_tween != null and impact_tween.is_running():
		impact_tween.kill()
	downward_warning_color = player_color
	downward_warning_time_left = downward_warning_duration
	downward_warning_elapsed = 0.0
	visual.color = Color.WHITE


func clear_downward_warning(restore_visual: bool = true) -> void:
	var had_warning := downward_warning_time_left > 0.0
	downward_warning_time_left = 0.0
	downward_warning_elapsed = 0.0
	if had_warning and restore_visual:
		visual.color = current_turn_color


func set_turn_color(color: Color) -> void:
	current_turn_color = color
	if (
		not is_downward_warning_active()
		and (impact_tween == null or not impact_tween.is_running())
	):
		visual.color = current_turn_color


func arm_for_serve() -> void:
	setup_overlap_player_ids.clear()
	for body in player_contact_area.get_overlapping_bodies():
		if body is CharacterBody2D and body.is_in_group("players"):
			setup_overlap_player_ids[body.get_instance_id()] = true
	player_contacts_armed = true


func apply_dash_rescue(player: CharacterBody2D, dash_direction: Vector2) -> bool:
	if not _accept_player_contact(player):
		return false
	if (
		player.has_method("claim_dash_balloon_contact")
		and not bool(player.call("claim_dash_balloon_contact"))
	):
		return false
	_activate_after_first_touch()
	var rescue_direction := dash_direction.normalized()
	if rescue_direction.is_zero_approx():
		rescue_direction = Vector2.UP
	var launch_direction := (
		rescue_direction
		+ player.velocity.normalized() * dash_movement_direction_factor
		+ Vector2.UP * 0.35
	).normalized()
	var impulse_strength := clampf(
		dash_rescue_impulse + player.velocity.length() * movement_impulse_factor,
		dash_rescue_impulse,
		max_dash_rescue_impulse
	)
	var approach_speed := maxf(
		player.velocity.dot(rescue_direction) - linear_velocity.dot(rescue_direction),
		0.0
	)
	_queue_player_contact(
		player,
		ContactType.DASH_RESCUE,
		launch_direction * impulse_strength,
		launch_direction,
		approach_speed
	)
	return true


func _flash_impact(toucher_color: Color) -> void:
	if impact_tween != null and impact_tween.is_running():
		impact_tween.kill()
	visual.color = Color.WHITE
	impact_tween = create_tween()
	impact_tween.tween_property(visual, "color", toucher_color, 0.18)
	impact_tween.tween_callback(func() -> void: visual.color = current_turn_color)


func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if body.is_in_group("trampoline"):
		apply_trampoline_bounce()
		return
	if (
		body.is_in_group("scoring_ground")
		and scoring_ground_contact_from_above
		and not ground_contact_reported
	):
		if _begin_balloon_impact():
			ground_touched.emit()


func apply_trampoline_bounce() -> void:
	linear_velocity.y = -maxf(absf(linear_velocity.y), trampoline_rebound_speed)
	sleeping = false


func explode_on_spikes() -> void:
	if not player_contacts_armed or spike_contact_reported or ground_contact_reported:
		return
	if not _begin_balloon_impact():
		return
	spike_contact_reported = true
	spikes_touched.emit()


func _begin_balloon_impact() -> bool:
	if ground_contact_reported:
		return false
	ground_contact_reported = true
	disarm_player_contacts()
	balloon_collision_shape.set_deferred("disabled", true)
	visual.visible = false
	string_visual.visible = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	gravity_scale = 0.0
	set_deferred("freeze", true)
	_play_ground_burst()
	audio_manager.call("play_gameplay_event", "balloon_explode", global_position)
	return true


func _play_ground_burst() -> void:
	ground_burst.stop()
	ground_burst.frame = 0
	ground_burst.visible = true
	ground_burst.play("explode")


func _on_ground_burst_animation_finished() -> void:
	ground_burst.visible = false


func show_contact_pixel(world_position: Vector2) -> void:
	var pixel := TOUCH_PIXEL_SCENE.instantiate() as Polygon2D
	pixel.position = to_local(world_position)
	add_child(pixel)


func _on_player_contact_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("players"):
		var player := body as PlayerController
		if player == null:
			return
		if not player_contacts_armed:
			return
		if setup_overlap_player_ids.has(player.get_instance_id()):
			return
		if player.is_dashing:
			apply_dash_rescue(player, player.dash_direction)
			return
		if not _accept_player_contact(player):
			return
		_activate_after_first_touch()
		var prediction := predict_normal_contact_result(player)
		_queue_player_contact(
			player,
			ContactType.NORMAL,
			prediction["impulse"],
			prediction["direction"],
			prediction["approach_speed"]
		)


func _on_player_contact_area_body_exited(body: Node2D) -> void:
	if body != null:
		setup_overlap_player_ids.erase(body.get_instance_id())


func _activate_after_first_touch() -> void:
	if not waiting_for_first_touch:
		return
	waiting_for_first_touch = false
	gravity_scale = gravity_strength
	linear_velocity = Vector2.ZERO
	sleeping = false


func _queue_player_contact(
	player: CharacterBody2D,
	contact_type: ContactType,
	impulse: Vector2,
	launch_direction: Vector2,
	approach_speed: float
) -> void:
	clear_downward_warning(false)
	var controller := player as PlayerController
	var toucher_color := controller.idle_color if controller != null else Color.WHITE
	visual.color = toucher_color
	_flash_impact(toucher_color)
	contact_visualized.emit(player, global_position)
	pending_contact_impulses[player.get_instance_id()] = {
		"player": player,
		"type": contact_type,
		"impulse": impulse,
		"direction": launch_direction,
		"impact_speed": approach_speed,
	}
	audio_manager.call(
		"play_gameplay_event",
		"balloon_touch",
		global_position,
		clampf(approach_speed / BALLOON_REF_SPEED, 0.0, 1.0)
	)
	if contact_type == ContactType.DASH_RESCUE:
		dash_rescued.emit(player, launch_direction)
	else:
		player_hit.emit(player)


func apply_pending_contact(player: CharacterBody2D, contact_type: ContactType) -> Dictionary:
	var player_id := player.get_instance_id()
	var contact: Dictionary = pending_contact_impulses.get(player_id, {})
	if contact.is_empty() or int(contact.get("type", -1)) != contact_type:
		return {}
	pending_contact_impulses.erase(player_id)
	var impulse: Vector2 = contact["impulse"]
	var resulting_velocity := linear_velocity + impulse / maxf(mass, 0.001)
	resulting_velocity = resulting_velocity.limit_length(max_hit_speed)
	resulting_velocity.x = clampf(resulting_velocity.x, -max_horizontal_speed, max_horizontal_speed)
	resulting_velocity.y = clampf(resulting_velocity.y, -max_hit_speed, max_fall_speed)
	impulse = (resulting_velocity - linear_velocity) * mass
	sleeping = false
	apply_central_impulse(impulse)
	return {
		"direction": contact["direction"],
		"resulting_velocity": resulting_velocity,
	}


func predict_normal_contact_result(player: PlayerController) -> Dictionary:
	var impulse_direction := global_position - player.global_position
	if impulse_direction.is_zero_approx():
		impulse_direction = Vector2.UP
	impulse_direction = impulse_direction.normalized()
	var balloon_velocity := Vector2.ZERO if waiting_for_first_touch else linear_velocity
	var approach_speed := maxf(
		player.velocity.dot(impulse_direction) - balloon_velocity.dot(impulse_direction),
		0.0
	)
	var launch_direction := (
		impulse_direction + player.velocity.normalized() * movement_direction_factor
	).normalized()
	var impulse_strength := clampf(
		player_hit_impulse
		+ approach_speed * impact_speed_factor
		+ player.velocity.length() * movement_impulse_factor,
		min_player_hit_impulse,
		max_player_hit_impulse
	)
	var resulting_velocity := _clamp_resulting_velocity(
		balloon_velocity + launch_direction * impulse_strength / maxf(mass, 0.001)
	)
	return {
		"direction": launch_direction,
		"impulse": launch_direction * impulse_strength,
		"approach_speed": approach_speed,
		"resulting_velocity": resulting_velocity,
	}


func _clamp_resulting_velocity(resulting_velocity: Vector2) -> Vector2:
	resulting_velocity = resulting_velocity.limit_length(max_hit_speed)
	resulting_velocity.x = clampf(
		resulting_velocity.x, -max_horizontal_speed, max_horizontal_speed
	)
	resulting_velocity.y = clampf(resulting_velocity.y, -max_hit_speed, max_fall_speed)
	return resulting_velocity


func clear_pending_contacts() -> void:
	pending_contact_impulses.clear()


func _accept_player_contact(player: CharacterBody2D) -> bool:
	if player is PlayerController and (player as PlayerController).cpu_balloon_contact_suppressed:
		return false
	var player_id := player.get_instance_id()
	if not player_contacts_armed or setup_overlap_player_ids.has(player_id):
		return false
	if float(player_contact_cooldowns.get(player_id, 0.0)) > 0.0:
		return false
	player_contact_cooldowns[player_id] = contact_interval
	return true
