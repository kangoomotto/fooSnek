# In PopupManager.gd
extends Node
# =========================================================
# 🔹 ROLE
# A simple factory for creating popups.
# It instantiates a popup, shows it, and lets the calling system
# (e.g., GameManager) handle all blocking and awaiting.
# =========================================================

const PopupBaseScene := preload("res://game_hud/scenes/PopupBase.tscn")

# Offsets and size scales are kept from the original
var _slot_offsets := {
	"goal": Vector2(-250,-1000),
	"overshoot": Vector2(-250,-200),
	"red": Vector2(-250,-200),
	"yellow": Vector2(-250,-200),
	"ladder": Vector2(-250,-200),
	"snake": Vector2(-250,-200),
	"default": Vector2(-250,-200),
}
var _slot_size_scale := {
	"default": 0.5, "goal": 0.5, "ladder": 0.5, "snake": 0.5,
	"kick": 0.5, "corner": 0.5, "penalty": 0.5, "yellow": 0.5,
	"red": 0.5, "overshoot": 0.5
}
var _popups_enabled: bool = true

func _ready():
	# We now only listen for the request to show a popup.
	EventsBus.show_popup.connect(_show_popup)
	
# This is now the main, and only, function.
func _show_popup(slot_type: String, position: Vector2, is_correct: bool = true, extra_info: Dictionary = {}) -> void:
	
	if not _popups_enabled:
		# Emit done immediately so GameManager doesn't stall
		EventsBus.popup_animation_done.emit()
		return

	if slot_type.is_empty():
		push_warning("⚠ PopupManager: Empty slot_type ignored")
		EventsBus.popup_animation_done.emit()
		return

	var popup: Node = PopupBaseScene.instantiate()
	var popup_layer := get_tree().get_root().get_node("/root/MAIN/PopupLayer")
	if not popup_layer:
		push_error("❌ PopupManager: Cannot find PopupLayer")
		return

	popup_layer.add_child(popup)
	popup.z_index = 10

	# Position + Size logic (same as before)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var screen_pos: Vector2 = viewport_size * 0.5
	var slot_offset: Vector2 = _slot_offsets.get(slot_type, _slot_offsets.get("default", Vector2.ZERO))
	var scale_factor = _slot_size_scale.get(slot_type, _slot_size_scale["default"])
	var popup_width = viewport_size.x * scale_factor
	var popup_height = popup_width * 0.75

	if popup.has_method("set_popup_size"):
		popup.set_popup_size(Vector2(popup_width, popup_height))

	if popup.has_method("start"):
		popup.start(slot_type, screen_pos, extra_info, slot_offset)
