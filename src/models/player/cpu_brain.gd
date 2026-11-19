class_name CPUBrain
extends RefCounted

enum State { INACTIVE, CPU_TURNO_PROPIO, CPU_TURNO_RIVAL }

var state: int = State.INACTIVE


func decide(_delta: float) -> CPUIntent:
	state = State.INACTIVE
	return CPUIntent.new()


func reset() -> void:
	state = State.INACTIVE
