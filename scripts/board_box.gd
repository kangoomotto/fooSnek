@tool
extends Marker2D
# res://scripts/board_box.gd
# =========================================================
# 🔹 SLOT TYPE
# =========================================================
@export_enum("stay", "yellow", "red", "kick", "corner", "goal", "ladder", "snake")
var slot_type: String = "stay":
	set(value):
		slot_type = value
		notify_property_list_changed() # ✅ refresh inspector
		_update_metadata()

# Internal variable for ladders/snakes
var target_index: int = -1

# =========================================================
# 🔹 DYNAMIC PROPERTY LIST
# =========================================================
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	if slot_type in ["ladder", "snake"]:
		var slot_count := _get_board_slot_count()
		var max_index = max(slot_count - 1, 0) # last valid index
		properties.append({
			"name": "target_index",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_STORAGE,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,%d,1" % max_index
		})
	return properties

# =========================================================
# 🔹 PROPERTY ACCESSORS
# =========================================================
func _set(property: StringName, value: Variant) -> bool:
	match property:
		"target_index":
			target_index = int(value)
			_update_metadata()
			return true
	return false

func _get(property: StringName) -> Variant:
	match property:
		"target_index":
			return target_index
	return null

# =========================================================
# 🔹 HELPERS
# =========================================================
func _get_board_slot_count() -> int:
	# Count siblings named Box_XX inside parent layout
	var layout = get_parent()
	if not layout:
		return 1
	var count := 0
	for child in layout.get_children():
		if child is Marker2D and child.name.begins_with("Box_"):
			count += 1
	return count

func _update_metadata():
	# Always mark type
	set_meta("type", slot_type)

	# Ladder/snake target
	if slot_type in ["ladder", "snake"] and target_index >= 0:
		set_meta("extra_info", { "move_to": target_index })
	else:
		set_meta("extra_info", {})

	# Auto quiz flag for specific slot types
	if slot_type in ["yellow", "red", "kick", "corner"]:
		set_meta("trigger_quiz", true)
	else:
		set_meta("trigger_quiz", false)

# =========================================================
# 🔹 EDITOR HOOK
# =========================================================
func _ready():
	if Engine.is_editor_hint():
		_update_metadata()
