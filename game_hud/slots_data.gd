#slots_data.gd
static func get_slot_type(index: int) -> String:
	return slot_types.get(index, "DEFAULT")

# =========================================================
# 🔹 SLOT TYPES — now language-aware
# =========================================================
static var slot_types := {
	"corner": {
		"label": {
			"es": "¡Tiro de esquina!",
			"en": "Corner kick!"
		},
		"image_pool": [
			"res://game_assets/images/slot_cards/corner_01.png"
		]
	},
	"penalty": {
		"label": {
			"es": "¡Penal!",
			"en": "Penalty!"
		},
		"image_pool": [
			"res://game_assets/images/slot_cards/penalty_01.png"
		]
	},
	"red": {
		"label": {
			"es": "¡Tarjeta roja!",
			"en": "Red card!"
		},
		"image_pool": [
			"res://game_assets/images/slot_cards/red_01.png",
			"res://game_assets/images/slot_cards/red_02.png"
		]
	},
	"yellow": {
		"label": {
			"es": "¡Tarjeta amarilla!",
			"en": "Yellow card!"
		},
		"image_pool": [
			"res://game_assets/images/slot_cards/yellow_01.png"
		]
	},
	"kick": {
		"label": {
			"es": "¡Tiro libre!",
			"en": "Free kick!"
		},
		"image_pool": [
			"res://game_assets/images/slot_cards/kick_01.png"
		]
	}
}

# =========================================================
# 🔹 HELPER FUNCTION — get localized label
# =========================================================
static func get_slot_label(slot_type: String, lang: String) -> String:
	if slot_types.has(slot_type) and slot_types[slot_type].has("label"):
		return slot_types[slot_type]["label"].get(lang, slot_type.capitalize())
	return slot_type.capitalize()

	
# =========================================================
# 🔹 HELPER FUNCTION — get image pool (unchanged)
# =========================================================
static func get_slot_image_pool(slot_type: String) -> Array:
	if slot_types.has(slot_type) and slot_types[slot_type].has("image_pool"):
		return slot_types[slot_type]["image_pool"]
	return []
