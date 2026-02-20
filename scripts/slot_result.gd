# slot_result.gd
class_name SlotResult
extends RefCounted

var chip: Node2D
var slot_type: String = ""
var is_correct: bool = false
var extra_turn: bool = false
var goal_handled: bool = false
var punish_popup_handled: bool = false
var outcome: Dictionary = {}

func is_valid_for(active_chip: Node2D) -> bool:
	return chip == active_chip and slot_type != ""
