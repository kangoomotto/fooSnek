class_name BoardManager
extends Node2D

# =========================================================
# 🔹 DEFAULT OUTCOME TEMPLATE
# =========================================================
const DEFAULT_OUTCOME := {
	"score": 0,
	"reset_score": false,
	"extra_turn": false,
	"return_to_start": false,
	"jump_to_goal": false,
	"move_to": null,
	"do_nothing": true,
	"trigger_quiz": false,
	"visual_feedback": false,
	"popup_type": "",
	"blocking": false,
	"is_goal": false,
	"move_duration": 0.3
}

# =========================================================
# 🔹 BOARD DATA
# =========================================================
var board_slots: Array[Marker2D] = []
var final_slot_index: int = 0
var slot_data: Dictionary = {}

# Runtime settings
var _popup_visual_feedback: Dictionary = {}
const SlotsData = preload("res://game_hud/slots_data.gd")

# =========================================================
# 🔹 READY
# =========================================================
func _ready():
	var lang_mgr = get_node("/root/LanguageManager")
	lang_mgr.language_changed.connect(_on_language_changed)
	EventsBus.popup_visual_feedback.connect(_on_popup_visual_feedback)

func init(board_layout: Node2D) -> void:
	if not board_layout:
		push_error("❌ BoardLayout not provided to BoardManager")
		return
	_collect_slots(board_layout)


func _print_board_layout():
	print("=== BOARD LAYOUT DUMP ===")
	for i in range(board_slots.size()):
		var data = slot_data.get(i, {})
		print("Slot ", i, " -> type: ", data.get("type", "---"), " | label: ", data.get("label", "---"))
	print("=== END DUMP ===")
	
# =========================================================
# 🔹 SLOT COLLECTION
# =========================================================
func _collect_slots(layout: Node2D) -> void:
	board_slots.clear()
	slot_data.clear()
	final_slot_index = 0

	for child in layout.get_children():
		if child is Marker2D and child.name.begins_with("Box_"):
			board_slots.append(child)

	board_slots.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)
	final_slot_index = board_slots.size() - 1

	var lang: String = get_node("/root/LanguageManager").get_language()

	for i in range(board_slots.size()):
		var marker: Marker2D = board_slots[i]
		var meta_type: String = marker.get_meta("type", "stay")
		var extra_info: Dictionary = marker.get_meta("extra_info", {})
		var trigger_quiz: bool = marker.get_meta("trigger_quiz", false)

		var data := {
			"position": marker.global_position,
			"type": meta_type,
			"index": i,
			"on_land": {},
			"on_correct": {},
			"on_wrong": {},
			"trigger_quiz": trigger_quiz,
			"extra_info": extra_info,
		}

		data = _apply_type_behaviors(data)

		if SlotsData:
			data["label"] = SlotsData.get_slot_label(meta_type, lang)
			data["image_pool"] = SlotsData.get_slot_image_pool(meta_type)
		else:
			data["label"] = meta_type.capitalize()
			data["image_pool"] = []

		slot_data[i] = data
		
	#_print_board_layout() 
	EventsBus.board_ready.emit()

# =========================================================
# 🔹 PUBLIC GETTERS
# =========================================================
func get_slot_data(index: int) -> Dictionary:
	if slot_data.has(index):
		return slot_data[index]
	return {}

func get_box_position(index: int) -> Vector2:
	if index < 0 or index >= board_slots.size():
		return Vector2.ZERO
	return board_slots[index].global_position

func get_final_slot_index() -> int:
	return 25  # Real goal slot

# =========================================================
# 🔹 LANGUAGE
# =========================================================
func _on_language_changed(new_lang: String) -> void:
	for index in slot_data.keys():
		var meta_type = slot_data[index]["type"]
		slot_data[index]["label"] = SlotsData.get_slot_label(meta_type, new_lang)

# =========================================================
# 🔹 POPUP SETTINGS
# =========================================================
func _on_popup_visual_feedback(settings: Dictionary):
	_popup_visual_feedback = settings

# =========================================================
# 🔹 DEEP MERGE
# =========================================================
static func deep_merge(a: Dictionary, b: Dictionary) -> Dictionary:
	for key in b.keys():
		if a.has(key) and a[key] is Dictionary and b[key] is Dictionary:
			a[key] = deep_merge(a[key], b[key])
		else:
			a[key] = b[key]
	return a

# =========================================================
# 🔹 RESOLVE OUTCOME
# =========================================================
func resolve_outcome(chip: Node2D, slot_data: Dictionary, is_correct: bool) -> Dictionary:
	if slot_data.is_empty():
		return {}

	var outcome_key: String
	if slot_data.get("trigger_quiz", false):
		outcome_key = "on_correct" if is_correct else "on_wrong"
	else:
		outcome_key = "on_land"

	var outcome: Dictionary = deep_merge(
		DEFAULT_OUTCOME.duplicate(true),
		slot_data.get(outcome_key, {}).duplicate(true)
	)

	var slot_type: String = slot_data.get("type", "")

	# Extra-turn rule
	if outcome.get("extra_turn", false):
		if not (slot_type in ["yellow", "red"] and is_correct):
			outcome["extra_turn"] = false

	# Goal handling
	if slot_type == "goal" or outcome.get("jump_to_goal", false):
		outcome["is_goal"] = true
		outcome["return_to_start"] = true
		outcome["popup_type"] = "goal"
		outcome["visual_feedback"] = true
		outcome["blocking"] = false
		outcome["extra_turn"] = false

	# Miss popups
	if not is_correct and slot_type in ["kick", "corner", "penalty"]:
		match slot_type:
			"kick": outcome["popup_type"] = "miss_kick"
			"corner": outcome["popup_type"] = "miss_corner"
			"penalty": outcome["popup_type"] = "miss_penalty"

	return {
		"chip": chip,
		"outcome": outcome,
		"outcome_key": outcome_key,
		"slot_type": slot_type,
		"is_correct": is_correct
	}

# =========================================================
# 🔹 TYPE BEHAVIORS
# =========================================================
func _apply_type_behaviors(data: Dictionary) -> Dictionary:
	var vf = func(key: String): return _popup_visual_feedback.get(key, true)

	match data.type:
		
		"ladder":
			data.on_land.do_nothing = false
			data.on_land.move_to = data.extra_info.get("move_to", -1)
			data.on_land.popup_type = "ladder"
			data.on_land.blocking = true
			data.on_land.visual_feedback = vf.call("ladder")
			data.on_land.wait_for_popup = false
			data.on_land.move_duration = 0.3
			data.on_land.extra_turn = false

		"snake":
			data.on_land.do_nothing = false
			data.on_land.move_to = data.extra_info.get("move_to", -1)
			data.on_land.popup_type = "snake"
			data.on_land.blocking = true
			data.on_land.visual_feedback = vf.call("snake")
			data.on_land.wait_for_popup = false
			data.on_land.move_duration = 0.3
			data.on_land.extra_turn = false

		"yellow":
			data.on_correct = deep_merge(DEFAULT_OUTCOME.duplicate(true), {
				"do_nothing": false,
				"extra_turn": true,
				"popup_type": "extra_turn",
				"visual_feedback": vf.call("yellow"),
				"blocking": false,
				"wait_for_popup": false,
				"move_duration": 0.3
			})
			data.on_wrong = deep_merge(DEFAULT_OUTCOME.duplicate(true), {
				"do_nothing": false,
				"return_to_start": true,
				"score": -1,
				"popup_type": "yellow",
				"visual_feedback": vf.call("yellow"),
				"blocking": false,
				"wait_for_popup": false,
				"move_duration": 0.1,
				"extra_turn": false
			})

		"red":
			data.on_correct = deep_merge(DEFAULT_OUTCOME.duplicate(true), {
				"do_nothing": false,
				"extra_turn": true,
				"popup_type": "extra_turn",
				"visual_feedback": vf.call("red"),
				"blocking": false,
				"wait_for_popup": false,
				"move_duration": 0.3
			})
			data.on_wrong = deep_merge(DEFAULT_OUTCOME.duplicate(true), {
				"do_nothing": false,
				"return_to_start": true,
				"reset_score": true,
				"popup_type": "red",
				"visual_feedback": vf.call("red"),
				"blocking": false,
				"wait_for_popup": false,
				"move_duration": 0.1,
				"extra_turn": false
			})

		"kick":
			data.on_correct = deep_merge(DEFAULT_OUTCOME.duplicate(true), {
				"do_nothing": false,
				"jump_to_goal": true,
				"score": 1,
				"wait_for_popup": false,
				"popup_type": "goal",
				"visual_feedback": vf.call("kick"),
				"blocking": false,
				"extra_turn": false
			})
			data.on_wrong = deep_merge(DEFAULT_OUTCOME.duplicate(true), {
				"do_nothing": false,
				"wait_for_popup": false,
				"popup_type": "miss_kick",
				"visual_feedback": vf.call("kick"),
				"blocking": false,
				"extra_turn": false
			})

		"corner":
			data.on_correct = deep_merge(DEFAULT_OUTCOME.duplicate(true), {
				"do_nothing": false,
				"jump_to_goal": true,
				"score": 1,
				"wait_for_popup": false,
				"popup_type": "goal",
				"visual_feedback": vf.call("corner"),
				"blocking": false,
				"extra_turn": false
			})
			data.on_wrong = deep_merge(DEFAULT_OUTCOME.duplicate(true), {
				"do_nothing": false,
				"wait_for_popup": false,
				"popup_type": "miss_corner",
				"visual_feedback": vf.call("corner"),
				"blocking": false,
				"extra_turn": false
			})
			
		"stay":
			# No-op slot: nothing happens; turn should advance via fake no-op popup
			data.on_land = deep_merge(DEFAULT_OUTCOME.duplicate(true), {
				"do_nothing": true,
				"visual_feedback": false,
				"blocking": false,
				"wait_for_popup": false,
				"extra_turn": false
			})
		_:
			pass

	return data
