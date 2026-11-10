class_name MenuNavigationUtils
extends RefCounted


static func is_player_one_action_just_pressed(action_suffix: String) -> bool:
	return Input.is_action_just_pressed(
		PlayerActionCatalog.action_name(PlayerActionCatalog.PLAYER_ONE_PREFIX, action_suffix)
	)


static func just_pressed_direction() -> Vector2i:
	if is_player_one_action_just_pressed(PlayerActionCatalog.ACTION_UP):
		return Vector2i.UP
	if is_player_one_action_just_pressed(PlayerActionCatalog.ACTION_DOWN):
		return Vector2i.DOWN
	if is_player_one_action_just_pressed(PlayerActionCatalog.ACTION_LEFT):
		return Vector2i.LEFT
	if is_player_one_action_just_pressed(PlayerActionCatalog.ACTION_RIGHT):
		return Vector2i.RIGHT
	return Vector2i.ZERO


static func linear_step(direction: Vector2i) -> int:
	if direction.x < 0 or direction.y < 0:
		return -1
	if direction.x > 0 or direction.y > 0:
		return 1
	return 0


static func wrap_index(index: int, item_count: int) -> int:
	assert(item_count > 0, "Cannot navigate an empty menu.")
	return posmod(index, item_count)


static func focus_control(control: Control) -> void:
	control.grab_focus()


static func update_button_selection(
	buttons: Array[Button], labels: Array[String], selected_index: int
) -> void:
	assert(buttons.size() == labels.size(), "Menu buttons and labels must have matching sizes.")
	assert(selected_index >= 0 and selected_index < buttons.size(), "Selected menu index is invalid.")
	for index in range(buttons.size()):
		buttons[index].text = ("> " if index == selected_index else "  ") + labels[index]
	if not buttons.is_empty():
		focus_control(buttons[selected_index])