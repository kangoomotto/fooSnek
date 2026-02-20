extends Control
#res://game_hud/hud_game_mode.gd
signal option_selected(mode_id: String)

@onready var btn_mode_1: Button = $ScrollContainer/MarginContainer/Grid/MC1/btn_mode_1
@onready var btn_mode_2: Button = $ScrollContainer/MarginContainer/Grid/MC2/btn_mode_2
@onready var btn_mode_3: Button = $ScrollContainer/MarginContainer/Grid/MC3/btn_mode_3
@onready var btn_close: Button = $VBoxContainer2/MC5/btn_close

var original_font_sizes: Dictionary = {}

func _ready():
	btn_close.pressed.connect(_on_close_pressed)
	btn_close.mouse_entered.connect(func(): _on_button_mouse_entered(btn_close))
	btn_close.mouse_exited.connect(func(): _on_button_mouse_exited(btn_close))
	hide()

func show_menu():
	var modes = GameModesDB.modes
	btn_mode_1.text = modes[0]["name"]
	btn_mode_2.text = modes[1]["name"]
	btn_mode_3.text = modes[2]["name"]

	# Clear old connections to avoid duplicates
	for btn in [btn_mode_1, btn_mode_2, btn_mode_3]:
		for c in btn.pressed.get_connections():
			btn.pressed.disconnect(c.callable)

	btn_mode_1.pressed.connect(func(): _emit_mode(modes[0]["id"]))
	btn_mode_2.pressed.connect(func(): _emit_mode(modes[1]["id"]))
	btn_mode_3.pressed.connect(func(): _emit_mode(modes[2]["id"]))
	
	show()

func _emit_mode(mode_id: String):
	EventsBus.game_mode_selected.emit(mode_id)
	#hide()

func _on_close_pressed():
	hide()

func _on_button_mouse_entered(btn: Button):
	pass
	#if not original_font_sizes.has(btn):
		#original_font_sizes[btn] = btn.get_theme_font_size("font_size")
	#btn.add_theme_font_size_override("font_size", original_font_sizes[btn] + 10)

func _on_button_mouse_exited(btn: Button):
	pass
	#if original_font_sizes.has(btn):
		#btn.add_theme_font_size_override("font_size", original_font_sizes[btn])
