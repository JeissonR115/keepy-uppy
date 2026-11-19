class_name RemoteBrain
extends CPUBrain

signal fallback_activated(reason: String)

var player: PlayerController
var bridge_server: CPUBridgeServer
var local_brain: LocalBrain
var timeout_seconds: float = 0.25
var _pending_sequence: int = 0
var _pending_since_usec: int = 0
var _received_intent: CPUIntent
var _fallback_reported: bool = false


func _init(
	owner: PlayerController,
	server: CPUBridgeServer,
	fallback: LocalBrain,
	timeout: float = 0.25
) -> void:
	player = owner
	bridge_server = server
	local_brain = fallback
	timeout_seconds = maxf(timeout, 0.001)
	bridge_server.client_connected.connect(_on_client_connected)
	bridge_server.action_received.connect(_on_action_received)
	bridge_server.client_disconnected.connect(_on_client_disconnected)


func decide(delta: float) -> CPUIntent:
	var local_intent := local_brain.decide(delta)
	state = local_brain.state
	_expire_pending_request()
	if _received_intent != null:
		var remote_intent := _received_intent
		_received_intent = null
		_fallback_reported = false
		_request_action()
		return remote_intent
	if _pending_sequence == 0:
		_request_action()
	return local_intent


func reset() -> void:
	if _pending_sequence != 0 and bridge_server != null:
		bridge_server.cancel_action_request(_pending_sequence)
	_pending_sequence = 0
	_pending_since_usec = 0
	_received_intent = null
	_fallback_reported = false
	state = State.INACTIVE
	if local_brain != null:
		local_brain.reset()


func _request_action() -> void:
	if (
		bridge_server == null
		or player == null
		or state == State.INACTIVE
	):
		return
	if not bridge_server.is_client_connected():
		_report_fallback("Python client is not connected.")
		return
	var sequence := bridge_server.request_action(CPUObservationBuilder.build_for(player))
	if sequence < 0:
		_report_fallback("Could not send observation to Python.")
		return
	_pending_sequence = sequence
	_pending_since_usec = Time.get_ticks_usec()


func _expire_pending_request() -> void:
	if _pending_sequence == 0:
		return
	if not bridge_server.is_client_connected():
		_pending_sequence = 0
		_pending_since_usec = 0
		_report_fallback("Python client disconnected.")
		return
	var elapsed_seconds := float(Time.get_ticks_usec() - _pending_since_usec) / 1_000_000.0
	if elapsed_seconds < timeout_seconds:
		return
	bridge_server.cancel_action_request(_pending_sequence)
	_pending_sequence = 0
	_pending_since_usec = 0
	_report_fallback("Python action timed out.")


func _on_action_received(action: CPUIntent, sequence: int) -> void:
	if sequence != _pending_sequence:
		return
	_pending_sequence = 0
	_pending_since_usec = 0
	_received_intent = action
	_fallback_reported = false


func _on_client_connected(_session_id: String) -> void:
	_fallback_reported = false


func _on_client_disconnected() -> void:
	if _pending_sequence == 0:
		return
	_pending_sequence = 0
	_pending_since_usec = 0
	_report_fallback("Python client disconnected.")


func _report_fallback(reason: String) -> void:
	if _fallback_reported:
		return
	_fallback_reported = true
	push_warning("Remote CPU brain is using LocalBrain: %s" % reason)
	fallback_activated.emit(reason)
