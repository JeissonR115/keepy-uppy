class_name CPUController
extends Node

const CPUBrainScript = preload("res://src/models/player/cpu_brain.gd")
const DEFAULT_PREDICTION_HORIZON := LocalBrain.DEFAULT_PREDICTION_HORIZON
const State = CPUBrainScript.State

signal decision_snapshot_updated(snapshot: Variant)

@export_range(0.0, 2.0, 0.01) var reaction_time: float = 0.1:
	set(value):
		reaction_time = clampf(value, 0.0, 2.0)
		if _local_brain != null:
			_local_brain.reaction_time = reaction_time
@export_range(0.0, 64.0, 0.5) var prediction_error_margin: float = 8.0:
	set(value):
		prediction_error_margin = clampf(value, 0.0, 64.0)
		if _local_brain != null:
			_local_brain.prediction_error_margin = prediction_error_margin
@export_range(0.0, 1.0, 0.01) var aggression_level: float = 0.35:
	set(value):
		aggression_level = clampf(value, 0.0, 1.0)
		if _local_brain != null:
			_local_brain.set_aggression_level(aggression_level)
@export_range(0.0, 200.0, 1.0) var dash_threshold_distance: float = 56.0:
	set(value):
		dash_threshold_distance = clampf(value, 0.0, 200.0)
		if _local_brain != null:
			_local_brain.dash_threshold_distance = dash_threshold_distance
@export_range(0.25, 5.0, 0.05) var prediction_horizon: float = DEFAULT_PREDICTION_HORIZON:
	set(value):
		prediction_horizon = clampf(value, 0.25, 5.0)
		if _local_brain != null:
			_local_brain.prediction_horizon = prediction_horizon

@onready var player: PlayerController = get_parent()
var _local_brain: LocalBrain
var _active_brain: CPUBrain
var _intents: CPUIntent = CPUIntent.new()

var state: int:
	get:
		return _active_brain.state if _active_brain != null else State.INACTIVE
var horizontal_intent: float:
	get:
		return _intents.horizontal
var jump_requested: bool:
	get:
		return _intents.jump
var dash_requested: bool:
	get:
		return _intents.dash
var dash_direction: Vector2:
	get:
		return _intents.dash_direction
var down_requested: bool:
	get:
		return _intents.down
var grab_requested: bool:
	get:
		return _intents.grab
var prediction_error_offset: Vector2:
	get:
		return _local_brain.prediction_error_offset if _local_brain != null else Vector2.ZERO
var obstruction_selected: bool:
	get:
		return _local_brain.obstruction_selected if _local_brain != null else false
var active_brain: CPUBrain:
	get:
		return _active_brain
var intents: CPUIntent:
	get:
		return _intents


func _ready() -> void:
	_local_brain = LocalBrain.new(player)
	_sync_local_brain_configuration()
	_active_brain = _local_brain
	var manager := player.get_parent().get_node("MatchManager") as MatchManager
	manager.coin_toss_completed.connect(_on_match_started)


func update_decision(delta: float = 1.0 / 60.0) -> int:
	if _active_brain == null:
		push_error("CPUController has no active brain.")
		_intents = CPUIntent.new()
		return State.INACTIVE
	_intents = _active_brain.decide(delta)
	var snapshot: Variant = _active_brain.get_decision_snapshot()
	if snapshot != null:
		decision_snapshot_updated.emit(snapshot)
	if _intents == null:
		push_error("CPUBrain returned no intent.")
		_intents = CPUIntent.new()
		_active_brain.reset()
		return State.INACTIVE
	return _active_brain.state


func refresh_state() -> int:
	return update_decision()


func reset() -> void:
	if _local_brain != null:
		_local_brain.reset()
	if _active_brain != null and _active_brain != _local_brain:
		_active_brain.reset()
	_intents = CPUIntent.new()


func set_brain(brain: CPUBrain) -> void:
	if brain == null:
		push_error("CPUController cannot select a null brain.")
		return
	if _active_brain != null:
		_active_brain.reset()
	_active_brain = brain
	_intents = CPUIntent.new()


func use_local_brain() -> void:
	if _local_brain == null:
		push_error("LocalBrain is not initialized.")
		return
	set_brain(_local_brain)


func use_remote_brain(server: CPUBridgeServer, timeout_seconds: float = 0.25) -> void:
	if _local_brain == null:
		push_error("LocalBrain is not initialized.")
		return
	if server == null:
		push_error("CPUController cannot use RemoteBrain without a bridge server.")
		return
	set_brain(RemoteBrain.new(player, server, _local_brain, timeout_seconds))


func predict_interception(
	target_y: float, horizon_seconds: float = DEFAULT_PREDICTION_HORIZON
) -> Dictionary:
	if _local_brain == null:
		push_error("LocalBrain is not initialized.")
		return {}
	return _local_brain.predict_interception(target_y, horizon_seconds)


func _on_match_started(_coin_result: String, _opening_player: CharacterBody2D) -> void:
	var seed_value := player.match_manager.match_seed
	if _local_brain != null:
		_local_brain.seed_for_match(seed_value)
	if _active_brain != null and _active_brain != _local_brain:
		_active_brain.reset()
	_intents = CPUIntent.new()


func _sync_local_brain_configuration() -> void:
	if _local_brain == null:
		return
	_local_brain.reaction_time = reaction_time
	_local_brain.prediction_error_margin = prediction_error_margin
	_local_brain.aggression_level = aggression_level
	_local_brain.dash_threshold_distance = dash_threshold_distance
	_local_brain.prediction_horizon = prediction_horizon
