# =========================================================
# GameFSM.gd
# ---------------------------------------------------------
# Pure finite state machine with validated transitions.
# No game logic, no side effects — just state and rules.
# =========================================================
class_name GameFSM
extends RefCounted

signal state_changed(old_state: int, new_state: int)

var current: int = -1
var _transitions: Dictionary = {}
var _state_names: Dictionary = {}
var _debug: bool = false

# =========================================================
# 🔹 CONFIGURATION
# =========================================================
func set_debug(enabled: bool) -> void:
	_debug = enabled

func set_state_names(names: Dictionary) -> void:
	_state_names = names

func define(from: int, to: int) -> void:
	if from not in _transitions:
		_transitions[from] = []
	if to not in _transitions[from]:
		_transitions[from].append(to)

# =========================================================
# 🔹 TRANSITIONS
# =========================================================
func transition_to(new_state: int) -> bool:
	if current == new_state:
		return true
	var allowed: Array = _transitions.get(current, [])
	if new_state not in allowed:
		var msg := "⛔ FSM: illegal %s → %s" % [_name(current), _name(new_state)]
		push_warning(msg)
		if _debug:
			print(msg)
		return false
	var old := current
	current = new_state
	if _debug:
		print("🔄 FSM: %s → %s" % [_name(old), _name(new_state)])
	state_changed.emit(old, new_state)
	return true

func force(new_state: int) -> void:
	var old := current
	current = new_state
	if _debug:
		print("🔄 FSM (forced): %s → %s" % [_name(old), _name(new_state)])
	state_changed.emit(old, new_state)

# =========================================================
# 🔹 QUERIES
# =========================================================
func is_in(state: int) -> bool:
	return current == state

func is_any(states: Array) -> bool:
	return current in states

func get_name() -> String:
	return _name(current)

func get_allowed_transitions() -> Array:
	return _transitions.get(current, [])

# =========================================================
# 🔹 INTERNAL
# =========================================================
func _name(state: int) -> String:
	return _state_names.get(state, "STATE_%d" % state)
