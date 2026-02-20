extends Control
signal about_us_opened(url: String)
signal about_us_feedback(text: String)

@onready var btn_option_1 = $MarginContainer/Grid/MC1/btn_option_1
@onready var btn_option_2 = $MarginContainer/Grid/MC2/btn_option_2
@onready var btn_option_3 = $MarginContainer/Grid/MC3/btn_option_3
@onready var btn_close_submit: Button = $btn_close_submit
@onready var text_edit = $MarginContainer/Grid/ScrollContainer/MC5/TextEdit

var text_edit_cleared: bool = false
var links: Array = AboutUsDB.links

var button_list: Array = []
var original_font_sizes: Dictionary = {}

func _ready():
	text_edit.focus_entered.connect(_on_text_edit_focus_entered)

	btn_option_1.pressed.connect(func(): _on_link_pressed(0))
	btn_option_2.pressed.connect(func(): _on_link_pressed(1))
	btn_option_3.pressed.connect(func(): _on_link_pressed(2))
	btn_close_submit.pressed.connect(_on_close_submit_pressed)

	button_list = [btn_option_1, btn_option_2, btn_option_3, btn_close_submit]
	for btn in button_list:
		btn.mouse_entered.connect(func(): _on_button_mouse_entered(btn))
		btn.mouse_exited.connect(func(): _on_button_mouse_exited(btn))
	hide()

func show_menu():
	text_edit_cleared = false
	show()

func _on_text_edit_focus_entered():
	if not text_edit_cleared:
		text_edit.clear()
		text_edit_cleared = true

func _on_link_pressed(idx: int):
	var url = links[idx]
	EventsBus.about_us_opened.emit(url)
	OS.shell_open(url)

func _on_close_submit_pressed():
	#EventsBus.about_us_feedback.emit(text_edit.text)
	hide()

func _on_button_mouse_entered(btn):
	if not original_font_sizes.has(btn): original_font_sizes[btn] = btn.get_theme_font_size("font_size")
	btn.add_theme_font_size_override("font_size", original_font_sizes[btn] + 10)

func _on_button_mouse_exited(btn):
	if original_font_sizes.has(btn): btn.add_theme_font_size_override("font_size", original_font_sizes[btn])
