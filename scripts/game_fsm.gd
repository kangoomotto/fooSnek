# game_fsm.gd
class_name GameFSM
extends RefCounted

signal state_changed(old_state: int, new_state: int)

var current: int = -1
var _valid_transitions: Dictionary = {}

func define_transition(from: int, to: int) -> void:
	if from not in _valid_transitions:
		_valid_transitions[from] = []
	_valid_transitions[from].append(to)

func transition_to(new_state: int) -> bool:
	if current != -1 and new_state not in _valid_transitions.get(current, []):
		push_warning("FSM: illegal %d → %d" % [current, new_state])
		return false
	var old = current
	current = new_state
	state_changed.emit(old, new_state)
	return true
