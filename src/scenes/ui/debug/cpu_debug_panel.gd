class_name CPUDebugPanel
extends CanvasLayer

signal layer_toggled(layer_name: String, enabled: bool)
signal control_requested(action: String)

var state_label: Label
var reason_label: Label
var target_label: Label
var route_label: Label
var edge_label: Label
var intent_label: Label
var layer_buttons: Dictionary = {}
var options_panel: PanelContainer
var visibility_button: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	options_panel = PanelContainer.new()
	options_panel.name = "Panel"
	options_panel.position = Vector2(4.0, 22.0)
	options_panel.custom_minimum_size = Vector2(112.0, 146.0)
	options_panel.size = options_panel.custom_minimum_size
	add_child(options_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 1)
	options_panel.add_child(content)
	var title := Label.new()
	title.text = "CPU DEBUG"
	title.add_theme_font_size_override("font_size", 7)
	content.add_child(title)
	state_label = _add_label(content, "STATE: --")
	reason_label = _add_label(content, "Waiting for decision.")
	reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_label = _add_label(content, "TARGET: --")
	route_label = _add_label(content, "ROUTE: --")
	edge_label = _add_label(content, "EDGE: --")
	intent_label = _add_label(content, "INTENT: --")
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 1)
	content.add_child(controls)
	_add_control_button(controls, "P", "pause")
	_add_control_button(controls, ">", "step")
	_add_control_button(controls, "S", "slow")
	_add_control_button(controls, "X", "exit")
	var layers := HBoxContainer.new()
	layers.add_theme_constant_override("separation", 1)
	content.add_child(layers)
	_add_layer_button(layers, "G", "graph")
	_add_layer_button(layers, "R", "active_route")
	_add_layer_button(layers, "O", "previous_route")
	_add_layer_button(layers, "T", "target")
	_add_layer_button(layers, "B", "trajectory")
	visibility_button = Button.new()
	visibility_button.name = "VisibilityButton"
	visibility_button.position = Vector2(4.0, 4.0)
	visibility_button.text = "HIDE"
	visibility_button.tooltip_text = "Hide CPU debug options"
	visibility_button.add_theme_font_size_override("font_size", 6)
	visibility_button.custom_minimum_size = Vector2(32.0, 14.0)
	add_child(visibility_button)
	visibility_button.pressed.connect(_toggle_options)


func set_snapshot(snapshot) -> void:
	if snapshot == null or state_label == null:
		return
	state_label.text = "STATE: %s" % snapshot.state
	reason_label.text = "WHY: %s" % snapshot.reason
	target_label.text = "TARGET: %.0f,%.0f" % [snapshot.target_position.x, snapshot.target_position.y]
	route_label.text = "ROUTE: %s" % _route_text(snapshot.route)
	var edge_text := "--"
	if snapshot.current_edge_from >= 0:
		edge_text = "%d>%d %s" % [
			snapshot.current_edge_from,
			snapshot.current_edge_to,
			snapshot.current_edge_action,
		]
	edge_label.text = "EDGE: %s" % edge_text
	var cpu_intent: CPUIntent = snapshot.intent
	intent_label.text = "I H%.0f J%d D%d" % [
		cpu_intent.horizontal,
		int(cpu_intent.jump),
		int(cpu_intent.dash),
	]


func _add_label(parent: VBoxContainer, initial_text: String) -> Label:
	var label := Label.new()
	label.text = initial_text
	label.add_theme_font_size_override("font_size", 6)
	label.clip_text = true
	parent.add_child(label)
	return label


func _add_layer_button(parent: HBoxContainer, caption: String, layer_name: String) -> void:
	var button := CheckButton.new()
	button.name = "%sLayer" % layer_name.capitalize()
	button.text = caption
	button.button_pressed = true
	button.add_theme_font_size_override("font_size", 5)
	button.custom_minimum_size = Vector2(18.0, 12.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.toggled.connect(_on_layer_toggled.bind(layer_name))
	parent.add_child(button)
	layer_buttons[layer_name] = button


func _add_control_button(parent: HBoxContainer, caption: String, action: String) -> void:
	var button := Button.new()
	button.name = "%sControl" % action.capitalize()
	button.text = caption
	button.tooltip_text = action.capitalize()
	button.add_theme_font_size_override("font_size", 5)
	button.custom_minimum_size = Vector2(22.0, 11.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_control_pressed.bind(action))
	parent.add_child(button)


func _on_layer_toggled(enabled: bool, layer_name: String) -> void:
	layer_toggled.emit(layer_name, enabled)


func _on_control_pressed(action: String) -> void:
	control_requested.emit(action)


func _toggle_options() -> void:
	options_panel.visible = not options_panel.visible
	visibility_button.text = "HIDE" if options_panel.visible else "SHOW"
	visibility_button.tooltip_text = (
		"Hide CPU debug options"
		if options_panel.visible
		else "Show CPU debug options"
	)


func _route_text(route: PackedInt64Array) -> String:
	var node_labels: PackedStringArray = []
	for node_id: int in route:
		node_labels.append(str(node_id))
	return ">".join(node_labels) if not node_labels.is_empty() else "--"
