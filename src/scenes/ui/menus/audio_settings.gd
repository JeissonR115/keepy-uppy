class_name AudioSettings
extends CanvasLayer

signal returned_to_menu

@onready var settings_manager: ControlSettingsManager = get_node("../../../ControlSettingsManager")
@onready var master_slider: HSlider = $Panel/Content/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Panel/Content/MusicRow/MusicSlider
@onready var effects_slider: HSlider = $Panel/Content/EffectsRow/EffectsSlider
@onready var mute_button: CheckButton = $Panel/Content/MuteButton
@onready var preview_button: Button = $Panel/Content/PreviewButton
@onready var back_button: Button = $Panel/Content/BackButton
@onready var status_label: Label = $Panel/Content/StatusLabel
@onready var audio_manager: Node = get_node("/root/AudioManager")

var focus_order: Array[Control] = []
var focused_index := 0
var was_paused_before_open := false
var loading_settings := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 128
	focus_order = [
		master_slider,
		music_slider,
		effects_slider,
		mute_button,
		preview_button,
		back_button,
	]
	for control: Control in focus_order:
		control.focus_entered.connect(_on_focus_entered.bind(control))
	master_slider.value_changed.connect(_on_audio_level_changed)
	music_slider.value_changed.connect(_on_audio_level_changed)
	effects_slider.value_changed.connect(_on_audio_level_changed)
	mute_button.toggled.connect(_on_mute_toggled)
	preview_button.pressed.connect(_preview_effect)
	back_button.pressed.connect(close)
	visible = false


func _process(_delta: float) -> void:
	if not visible:
		return
	var direction := MenuNavigationUtils.just_pressed_direction()
	if direction.y != 0:
		_move_focus(direction.y)
	elif direction.x != 0:
		var slider: HSlider = focus_order[focused_index] as HSlider
		if slider != null:
			slider.value = clampf(slider.value + direction.x * slider.step, slider.min_value, slider.max_value)
	if MenuNavigationUtils.is_player_one_action_just_pressed(PlayerActionCatalog.ACTION_JUMP):
		var focused := focus_order[focused_index]
		if focused == mute_button:
			mute_button.button_pressed = not mute_button.button_pressed
		elif focused == preview_button or focused == back_button:
			(focused as Button).emit_signal("pressed")
	elif MenuNavigationUtils.is_player_one_action_just_pressed(PlayerActionCatalog.ACTION_DASH):
		close()


func open() -> void:
	was_paused_before_open = get_tree().paused
	get_tree().paused = true
	_load_current_settings()
	focused_index = 0
	visible = true
	_focus_current()


func close() -> void:
	if not visible:
		return
	visible = false
	if not was_paused_before_open:
		get_tree().paused = false
	returned_to_menu.emit()


func _load_current_settings() -> void:
	loading_settings = true
	var settings: Dictionary = settings_manager.get_audio_settings()
	master_slider.value = float(settings["master"])
	music_slider.value = float(settings["music"])
	effects_slider.value = float(settings["effects"])
	mute_button.button_pressed = bool(settings["muted"])
	_update_labels()
	loading_settings = false


func _on_audio_level_changed(_value: float) -> void:
	if not loading_settings:
		_save_settings()
	_update_labels()


func _on_mute_toggled(_pressed: bool) -> void:
	if not loading_settings:
		_save_settings()
	_update_labels()


func _save_settings() -> void:
	var result: Dictionary = settings_manager.set_audio_settings({
		"master": master_slider.value,
		"music": music_slider.value,
		"effects": effects_slider.value,
		"muted": mute_button.button_pressed,
	})
	if not result.valid:
		status_label.text = result.reason
		_load_current_settings()
	else:
		status_label.text = "SETTINGS SAVED"


func _preview_effect() -> void:
	audio_manager.call("play", "jump")


func _update_labels() -> void:
	$Panel/Content/MasterRow/MasterValue.text = "%d%%" % roundi(master_slider.value * 100.0)
	$Panel/Content/MusicRow/MusicValue.text = "%d%%" % roundi(music_slider.value * 100.0)
	$Panel/Content/EffectsRow/EffectsValue.text = "%d%%" % roundi(effects_slider.value * 100.0)
	mute_button.text = "MUTE: ON" if mute_button.button_pressed else "MUTE: OFF"


func _move_focus(step: int) -> void:
	focused_index = MenuNavigationUtils.wrap_index(
		focused_index + step, focus_order.size()
	)
	_focus_current()


func _focus_current() -> void:
	MenuNavigationUtils.focus_control(focus_order[focused_index])


func _on_focus_entered(control: Control) -> void:
	var index := focus_order.find(control)
	if index >= 0:
		focused_index = index
