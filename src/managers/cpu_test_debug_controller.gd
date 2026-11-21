class_name CPUTestDebugController
extends Node

const SLOW_MOTION_SCALE := 0.25

var arena: Node
var cpu_player: PlayerController
var cpu_controller: CPUController
var menu: PlayerCountMenu
var overlay: NavGraphOverlay
var panel
var _previous_time_scale: float = 1.0
var _previous_paused: bool = false
var _slow_motion: bool = false
var _step_pending: bool = false
var _test_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(false)
	set_physics_process(false)
	set_physics_process_priority(10000)


func configure(
	active_arena: Node,
	player: PlayerController,
	player_menu: PlayerCountMenu,
	graph_overlay: NavGraphOverlay,
	debug_panel,
	paused_before_mode: bool = true
) -> void:
	arena = active_arena
	cpu_player = player
	cpu_controller = player.cpu_controller
	menu = player_menu
	overlay = graph_overlay
	panel = debug_panel
	_previous_time_scale = Engine.time_scale
	_previous_paused = paused_before_mode
	_test_active = true
	set_process_input(true)
	set_physics_process(true)
	panel.control_requested.connect(_on_control_requested)
	panel.layer_toggled.connect(overlay.set_layer_visible)
	cpu_controller.decision_snapshot_updated.connect(_on_decision_snapshot_updated)


func _physics_process(_delta: float) -> void:
	if not _test_active or not _step_pending:
		return
	_step_pending = false
	call_deferred("_finish_single_step")


func _input(event: InputEvent) -> void:
	if not _test_active:
		return
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var key_code := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
	match key_code:
		KEY_F1:
			_toggle_layer("graph")
		KEY_F2:
			_toggle_layer("active_route")
		KEY_F3:
			_toggle_layer("previous_route")
		KEY_F4:
			_toggle_layer("target")
		KEY_F5:
			_toggle_layer("trajectory")
		KEY_F6:
			overlay.set_layer_visible("cpu_label", not overlay.show_cpu_label)
		KEY_F7:
			toggle_pause()
		KEY_F8:
			step_once()
		KEY_F9:
			toggle_slow_motion()
		KEY_F10:
			exit_test_mode()
		_:
			return
	get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused


func step_once() -> void:
	if _step_pending:
		return
	get_tree().paused = true
	_step_pending = true
	get_tree().paused = false


func toggle_slow_motion() -> void:
	_slow_motion = not _slow_motion
	Engine.time_scale = (
		_previous_time_scale * SLOW_MOTION_SCALE
		if _slow_motion
		else _previous_time_scale
	)


func exit_test_mode() -> void:
	if not _test_active:
		return
	_test_active = false
	set_process_input(false)
	set_physics_process(false)
	_step_pending = false
	Engine.time_scale = _previous_time_scale
	_slow_motion = false
	get_tree().paused = _previous_paused
	if is_instance_valid(cpu_controller):
		var callback := Callable(self, "_on_decision_snapshot_updated")
		if cpu_controller.decision_snapshot_updated.is_connected(callback):
			cpu_controller.decision_snapshot_updated.disconnect(callback)
	if is_instance_valid(overlay):
		overlay.visible = false
		overlay.clear_graph()
		overlay.queue_free()
	if is_instance_valid(panel):
		panel.visible = false
		panel.queue_free()
	if is_instance_valid(menu):
		menu.on_test_cpu_exited()
	queue_free()


func _finish_single_step() -> void:
	if not _test_active:
		return
	get_tree().paused = true


func _toggle_layer(layer_name: String) -> void:
	if not _test_active or not is_instance_valid(overlay):
		return
	var current: bool = true
	match layer_name:
		"graph":
			current = overlay.show_graph
		"active_route":
			current = overlay.show_active_route
		"previous_route":
			current = overlay.show_previous_route
		"target":
			current = overlay.show_target
		"trajectory":
			current = overlay.show_trajectory
	overlay.set_layer_visible(layer_name, not current)
	var button: CheckButton = panel.layer_buttons.get(layer_name)
	if button != null:
		button.set_pressed_no_signal(not current)


func _on_control_requested(action: String) -> void:
	if not _test_active:
		return
	match action:
		"pause":
			toggle_pause()
		"step":
			step_once()
		"slow":
			toggle_slow_motion()
		"exit":
			exit_test_mode()


func _on_decision_snapshot_updated(snapshot: Variant) -> void:
	if (
		not _test_active
		or not is_instance_valid(overlay)
		or not is_instance_valid(panel)
	):
		return
	overlay.set_snapshot(snapshot, cpu_player)
	panel.set_snapshot(snapshot)
