class_name KeyboardMenu
extends Node

signal selection_changed(index: int)
signal item_activated(index: int)
signal cancelled

@export var item_paths: Array[NodePath] = []

@onready var navigator: MenuKeyboardNavigator = $Navigator

var items: Array[Control] = []
var selected_index: int = 0
var movement_enabled: bool = true
var confirmation_enabled: bool = true


func _ready() -> void:
	for item_path: NodePath in item_paths:
		var item := get_node_or_null(item_path) as Control
		if item != null:
			items.append(item)
	navigator.moved.connect(_move_selection)
	navigator.confirmed.connect(_confirm_selection)
	navigator.cancelled.connect(func() -> void: cancelled.emit())
	navigator.movement_enabled = movement_enabled
	navigator.confirm_enabled = confirmation_enabled


func activate(index: int = 0) -> void:
	if items.is_empty():
		return
	navigator.enabled = true
	select(index)


func deactivate() -> void:
	navigator.enabled = false


func select(index: int) -> void:
	if items.is_empty():
		return
	selected_index = posmod(index, items.size())
	items[selected_index].grab_focus()
	selection_changed.emit(selected_index)


func _move_selection(direction: int) -> void:
	select(selected_index + direction)


func _confirm_selection() -> void:
	if not items.is_empty():
		item_activated.emit(selected_index)
