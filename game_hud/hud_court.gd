extends Control
#res://game_hud/hud_court.gd
signal option_selected(court_data: Dictionary)

@onready var btn_mode_1: Button = $ScrollContainer/MarginContainer/Grid/MC1/btn_mode_1
@onready var btn_mode_2: Button = $ScrollContainer/MarginContainer/Grid/MC2/btn_mode_2
@onready var btn_mode_3: Button = $ScrollContainer/MarginContainer/Grid/MC3/btn_mode_3
@onready var btn_close: Button = $btn_close

var court_layouts: Array = []
var original_font_sizes: Dictionary = {}

func _ready():
	court_layouts = CourtsDB.layouts

	btn_close.pressed.connect(_on_close_pressed)
	btn_close.mouse_entered.connect(func(): _on_button_mouse_entered(btn_close))
	btn_close.mouse_exited.connect(func(): _on_button_mouse_exited(btn_close))
	hide()

func show_menu():
	btn_mode_1.text = court_layouts[0]["name"]
	btn_mode_2.text = court_layouts[1]["name"]
	btn_mode_3.text = court_layouts[2]["name"]

	# 🔹 Clear old connections to avoid duplicates
	for btn in [btn_mode_1, btn_mode_2, btn_mode_3]:
		for c in btn.pressed.get_connections():
			btn.pressed.disconnect(c.callable)

	btn_mode_1.pressed.connect(func(): _emit_mode(0))
	btn_mode_2.pressed.connect(func(): _emit_mode(1))
	btn_mode_3.pressed.connect(func(): _emit_mode(2))

	show()

func _emit_mode(idx: int):
	if idx >= 0 and idx < court_layouts.size():
		EventsBus.court_selected.emit(court_layouts[idx])
		# 🔹 Do NOT hide here — let user keep previewing courts

func _on_close_pressed():
	hide()

func _on_button_mouse_entered(btn: Button):
	if not original_font_sizes.has(btn):
		original_font_sizes[btn] = btn.get_theme_font_size("font_size")
	btn.add_theme_font_size_override("font_size", original_font_sizes[btn] + 10)

func _on_button_mouse_exited(btn: Button):
	if original_font_sizes.has(btn):
		btn.add_theme_font_size_override("font_size", original_font_sizes[btn])
