class_name ScriptedPlayerBrain
extends CPUBrain

var player: PlayerController


func _init(owner: PlayerController) -> void:
	player = owner


func decide(_delta: float) -> CPUIntent:
	var intent := CPUIntent.new()
	if not player.bot_enabled or player.match_manager.match_state != MatchManager.MatchState.ACTIVE:
		state = State.INACTIVE
		return intent

	state = (
		State.CPU_TURNO_PROPIO
		if player.match_manager.expected_balloon_player == player
		else State.CPU_TURNO_RIVAL
	)
	var horizontal_distance := player.balloon.global_position.x - player.global_position.x
	if absf(horizontal_distance) > 10.0:
		intent.horizontal = signf(horizontal_distance)
	if (
		state == State.CPU_TURNO_PROPIO
		and player.is_on_floor()
		and player.balloon.global_position.y < player.global_position.y - 20.0
	):
		intent.jump = true
	return intent
