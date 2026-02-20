# turn_controller.gd
class_name TurnController
extends RefCounted

signal turn_advanced(new_player: int)
signal extra_turn_granted(player: int)

var _advance_pending: bool = false

func request_advance(source: String, slot_result: Dictionary) -> void:
	if _advance_pending:
		return
	_advance_pending = true

	var extra = slot_result.get("extra_turn", false)
	if extra:
		extra_turn_granted.emit(slot_result.get("player", 0))
	else:
		turn_advanced.emit(1 - slot_result.get("player", 0))

	_advance_pending = false
