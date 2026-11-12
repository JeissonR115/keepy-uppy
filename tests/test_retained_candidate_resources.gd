extends SceneTree

const RETAINED_SCENES: Array[String] = [
	"res://src/scenes/levels/ancient_ruins.tscn",
	"res://src/models/environment/platform.tscn",
	"res://src/scenes/ui/components/keyboard_menu.tscn",
	"res://src/scenes/ui/components/touch_pixel.tscn",
]


func _initialize() -> void:
	for scene_path: String in RETAINED_SCENES:
		if not _expect(ResourceLoader.load(scene_path) is PackedScene, "Retained candidate scene failed to load: %s" % scene_path):
			quit(1)
			return
	if not _expect(FileAccess.file_exists("res://config-music.js"), "Retained music authoring utility is missing."):
		quit(1)
		return
	if not _expect(FileAccess.file_exists("res://assets/sprites/player/Animations/player/idle/f0.png"), "Retained player source artwork is missing."):
		quit(1)
		return
	print("Retained candidate scenes, source artwork, and authoring utility are present and loadable.")
	quit()


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
