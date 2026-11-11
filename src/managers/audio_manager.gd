extends Node

const MANIFEST_PATH := "res://audio/sound_presets.json"
const MENU_MUSIC_PATH := "res://assets/music/menu.wav"
const MATCH_MUSIC_PATH := "res://assets/music/bgMusic.wav"
const MENU_MUSIC_VOLUME_DB := -6.0
const MATCH_MUSIC_VOLUME_DB := -4.0
const MATCH_MUSIC_PITCH_SCALE := 0.92

var _events: Dictionary = {}
var _streams: Dictionary = {}
var _last_paths: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _menu_music: AudioStreamPlayer
var _match_music: AudioStreamPlayer


func _ready() -> void:
	_rng.randomize()
	_load_manifest()
	_menu_music = _create_music_player(MENU_MUSIC_PATH, MENU_MUSIC_VOLUME_DB, 1.0)
	_match_music = _create_music_player(
		MATCH_MUSIC_PATH,
		MATCH_MUSIC_VOLUME_DB,
		MATCH_MUSIC_PITCH_SCALE
	)


func _create_music_player(
	stream_path: String,
	volume_db: float,
	pitch_scale: float
) -> AudioStreamPlayer:
	if not ResourceLoader.exists(stream_path):
		push_error("AudioManager: music file does not exist: %s." % stream_path)
		return null
	var source_stream := ResourceLoader.load(stream_path) as AudioStreamWAV
	if source_stream == null:
		push_error("AudioManager: music file is not a WAV stream: %s." % stream_path)
		return null
	var looping_stream := source_stream.duplicate() as AudioStreamWAV
	if looping_stream == null:
		push_error("AudioManager: could not duplicate music stream: %s." % stream_path)
		return null
	looping_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	var player := AudioStreamPlayer.new()
	player.name = "MenuMusic" if stream_path == MENU_MUSIC_PATH else "MatchMusic"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = looping_stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	return player


func play_menu_music() -> void:
	if _menu_music == null or _match_music == null:
		push_error("AudioManager: menu music is unavailable.")
		return
	_match_music.stop()
	if not _menu_music.playing:
		_menu_music.play()


func play_match_music() -> void:
	if _menu_music == null or _match_music == null:
		push_error("AudioManager: match music is unavailable.")
		return
	_menu_music.stop()
	if not _match_music.playing:
		_match_music.play()


func _load_manifest() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_error("AudioManager: cannot open sound manifest at %s." % MANIFEST_PATH)
		return

	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		push_error(
			"AudioManager: invalid sound manifest at %s:%d: %s"
			% [MANIFEST_PATH, parser.get_error_line(), parser.get_error_message()]
		)
		return
	if not parser.data is Dictionary or not parser.data.get("events") is Dictionary:
		push_error("AudioManager: manifest must contain an events dictionary.")
		return

	var manifest: Dictionary = parser.data
	var events: Dictionary = manifest["events"]
	for event_id: Variant in events:
		var event: Variant = events[event_id]
		if not event is Dictionary or not _is_valid_event(str(event_id), event):
			push_error("AudioManager: invalid manifest event '%s'." % event_id)
			continue
		_events[event_id] = event
		if event["mode"] == "intensity":
			var tier_streams: Dictionary = {}
			var files: Dictionary = event["files"]
			for tier: Variant in files:
				tier_streams[tier] = _load_list(files[tier], event_id)
			_streams[event_id] = tier_streams
		else:
			_streams[event_id] = _load_list(event["files"], event_id)


func _is_valid_event(event_id: String, event: Dictionary) -> bool:
	if not event.has("mode") or not event.has("playback") or not event.has("files"):
		return false
	if not event["playback"] is Dictionary:
		return false
	if not ["single", "random_variant", "intensity"].has(event["mode"]):
		return false
	if event["mode"] == "intensity":
		return event["files"] is Dictionary and event.get("tiers", []) is Array
	if not event["files"] is Array:
		return false
	if event["files"].is_empty():
		push_error("AudioManager: event '%s' has no file paths." % event_id)
		return false
	return true


func _load_list(paths: Array, event_id: String) -> Array:
	var loaded: Array = []
	for path: Variant in paths:
		if not path is String:
			push_error("AudioManager: event '%s' has a non-string asset path." % event_id)
			continue
		var asset_path := str(path)
		if not ResourceLoader.exists(asset_path):
			push_error(
				"AudioManager: event '%s' references missing audio asset %s."
				% [event_id, asset_path]
			)
			continue
		var stream: Resource = ResourceLoader.load(asset_path)
		if not stream is AudioStream:
			push_error(
				"AudioManager: event '%s' could not load audio asset %s."
				% [event_id, asset_path]
			)
			continue
		loaded.append({"path": asset_path, "stream": stream})
	return loaded


func _pick(event_id: String, intensity: float) -> Dictionary:
	if not _events.has(event_id):
		push_warning("AudioManager: unknown sound event '%s'." % event_id)
		return {}

	var event: Dictionary = _events[event_id]
	var playback: Dictionary = event["playback"]
	var event_streams: Variant = _streams.get(event_id, [])
	var variants: Array
	if event["mode"] == "intensity":
		var tier := "hard"
		for definition: Variant in event["tiers"]:
			if intensity <= float(definition["max_intensity"]):
				tier = str(definition["name"])
				break
		variants = event_streams.get(tier, [])
	else:
		variants = event_streams
	if variants.is_empty():
		push_error("AudioManager: event '%s' has no loadable audio variants." % event_id)
		return {}

	var previous_path := str(_last_paths.get(event_id, ""))
	var choices: Array = []
	for variant: Dictionary in variants:
		if variant["path"] != previous_path:
			choices.append(variant)
	if choices.is_empty():
		choices = variants
	var selected: Dictionary = choices[_rng.randi_range(0, choices.size() - 1)]
	_last_paths[event_id] = selected["path"]

	var normalized_intensity := clampf(intensity, 0.0, 1.0)
	var volume_range: Array = playback.get(
		"volume_db_by_intensity",
		[playback.get("volume_db", 0.0), playback.get("volume_db", 0.0)]
	)
	var pitch_jitter := float(playback.get("pitch_jitter", 0.0))
	return {
		"path": selected["path"],
		"stream": selected["stream"],
		"bus": str(playback.get("bus", "Master")),
		"volume_db": lerpf(
			float(volume_range[0]), float(volume_range[1]), normalized_intensity
		),
		"pitch": 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter),
		"max_distance": float(playback.get("max_distance", 800.0)),
		"positional": bool(playback.get("positional", false)),
	}


func play(event_id: String, intensity: float = 0.0, pitch_offset: float = 0.0) -> void:
	_play(event_id, Vector2.ZERO, intensity, pitch_offset, false)


func play_event(event_id: String, pos: Vector2 = Vector2.ZERO, intensity: float = 0.0) -> void:
	if not _events.has(event_id):
		push_warning("AudioManager: unknown sound event '%s'." % event_id)
		return
	var playback: Dictionary = _events[event_id]["playback"]
	_play(event_id, pos, intensity, 0.0, bool(playback.get("positional", false)))


func play_at(
	event_id: String,
	pos: Vector2,
	intensity: float = 0.0,
	pitch_offset: float = 0.0
) -> void:
	_play(event_id, pos, intensity, pitch_offset, true)


func _has_network_peer() -> bool:
	return multiplayer.has_multiplayer_peer() and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer


func play_gameplay_event(
	event_id: String,
	pos: Vector2 = Vector2.ZERO,
	intensity: float = 0.0
) -> void:
	if not _has_network_peer():
		play_event(event_id, pos, intensity)
	elif multiplayer.is_server():
		rpc("_receive_gameplay_sfx", event_id, pos, intensity)
	else:
		push_warning(
			"AudioManager: only the multiplayer authority may broadcast '%s'." % event_id
		)


func play_local_action(
	event_id: String,
	pos: Vector2,
	owns_action: bool,
	pitch_offset: float = 0.0
) -> void:
	if not ["jump", "dash"].has(event_id):
		push_error("AudioManager: '%s' is not a local replicated action sound." % event_id)
		return
	if not _has_network_peer():
		play_at(event_id, pos, 0.0, pitch_offset)
		return
	if not owns_action:
		return

	play_at(event_id, pos, 0.0, pitch_offset)
	if multiplayer.is_server():
		_broadcast_local_action(event_id, pos, 1)
	else:
		rpc_id(1, "_receive_local_action", event_id, pos)


@rpc("authority", "call_local", "reliable")
func _receive_gameplay_sfx(event_id: String, pos: Vector2, intensity: float) -> void:
	play_event(event_id, pos, intensity)


@rpc("any_peer", "call_remote", "unreliable")
func _receive_local_action(event_id: String, pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
	if not ["jump", "dash"].has(event_id):
		push_warning("AudioManager: rejected unsupported remote action sound '%s'." % event_id)
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 0:
		push_warning("AudioManager: rejected local action sound without a remote sender.")
		return
	_broadcast_local_action(event_id, pos, sender_id)


@rpc("authority", "call_remote", "unreliable")
func _receive_remote_action(event_id: String, pos: Vector2) -> void:
	if ["jump", "dash"].has(event_id):
		play_at(event_id, pos)


func _broadcast_local_action(event_id: String, pos: Vector2, source_peer_id: int) -> void:
	for peer_id: int in multiplayer.get_peers():
		if peer_id != source_peer_id:
			rpc_id(peer_id, "_receive_remote_action", event_id, pos)


func _play(
	event_id: String,
	pos: Vector2,
	intensity: float,
	pitch_offset: float,
	positional: bool
) -> void:
	var sound := _pick(event_id, intensity)
	if sound.is_empty():
		return
	var bus := str(sound["bus"])
	if AudioServer.get_bus_index(bus) < 0:
		push_error("AudioManager: event '%s' uses unknown audio bus '%s'." % [event_id, bus])
		return

	if positional:
		var player := AudioStreamPlayer2D.new()
		player.stream = sound["stream"]
		player.bus = bus
		player.volume_db = float(sound["volume_db"])
		player.pitch_scale = maxf(0.01, float(sound["pitch"]) + pitch_offset)
		player.max_distance = float(sound["max_distance"])
		var parent := get_tree().current_scene
		if parent == null:
			parent = get_tree().root
		parent.add_child(player)
		player.global_position = pos
		player.finished.connect(player.queue_free)
		player.play()
	else:
		var player := AudioStreamPlayer.new()
		player.stream = sound["stream"]
		player.bus = bus
		player.volume_db = float(sound["volume_db"])
		player.pitch_scale = maxf(0.01, float(sound["pitch"]) + pitch_offset)
		add_child(player)
		player.finished.connect(player.queue_free)
		player.play()
