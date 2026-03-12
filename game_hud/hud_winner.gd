# res://game_hud/hud_winner.gd
extends Panel

# =========================================================
# 🔹 NODE REFERENCES
# =========================================================
@onready var name1: Label = $GridContainer/Name1
@onready var name2: Label = $GridContainer/Name2
@onready var shield1: TextureRect = $GridContainer/HBoxContainer/Shield1
@onready var shield2: TextureRect = $GridContainer/HBoxContainer2/Shield2
@onready var score1: Label = $GridContainer/HBoxContainer/Score1
@onready var score2: Label = $GridContainer/HBoxContainer2/Score2
@onready var play_again_button: Button = $PlayAgainButton
@onready var main_menu_button: Button = $MainMenuButton
@onready var winner_title: Label = $WinnerOrDraw

# =========================================================
# 🔹 READY
# =========================================================
# =========================================================
# 🔹 READY
# =========================================================
func _ready() -> void:
	visible = false
	EventsBus.show_winner.connect(show_panel)
	play_again_button.pressed.connect(_on_play_again_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	# Store base keys for localization
	play_again_button.set_meta("lang_key_base", "PLAY AGAIN")
	main_menu_button.set_meta("lang_key_base", "MAIN MENU")
	winner_title.set_meta("lang_key_base", "WINNER")
	
	_update_language_ui(LanguageManager.get_language())

	# Wire live language updates directly to LanguageManager
	LanguageManager.language_changed.connect(_update_language_ui)

# =========================================================
# 🔹 SHOW PANEL
# =========================================================
func show_panel(winner_id: int, stats: Dictionary) -> void:
	stats["winner_id"] = winner_id
	update_panel(stats)
	visible = true

# =========================================================
# 🔹 UPDATE PANEL DATA
# =========================================================
func update_panel(stats: Dictionary) -> void:
	var teams: Array = stats.get("teams", [])
	var winner_id: int = stats.get("winner_id", -1)
	if teams.size() < 2:
		return
	# Set Winner/Draw label
	var is_draw = winner_id == -1
	winner_title.set_meta("lang_key_base", "DRAW" if is_draw else "WINNER")
	_update_language_ui(LanguageManager.get_language())
	
	# Put winner on top, loser on bottom (swap if player 2 wins)
	var top = 0 if winner_id != 1 else 1
	var bottom = 1 - top
	
	name1.text = teams[top].get("name", "Unknown")
	score1.text = str(teams[top].get("score", 0))
	_set_shield_texture(shield1, teams[top].get("shield", ""))

	name2.text = teams[bottom].get("name", "Unknown")
	score2.text = str(teams[bottom].get("score", 0))
	_set_shield_texture(shield2, teams[bottom].get("shield", ""))

# =========================================================
# 🔹 SHIELD LOADER
# =========================================================
func _set_shield_texture(node: TextureRect, shield_source) -> void:
	if shield_source is String and ResourceLoader.exists(shield_source):
		node.texture = load(shield_source)
	elif shield_source is Texture2D:
		node.texture = shield_source
	else:
		node.texture = null

# =========================================================
# 🔹 BUTTONS
# =========================================================
func _on_play_again_pressed() -> void:
	visible = false
	EventsBus.play_again_requested.emit()

func _on_main_menu_pressed() -> void:
	visible = false
	EventsBus.main_menu.emit()

# =========================================================
# 🔹 LIVE LOCALIZATION
# =========================================================
func _update_language_ui(new_lang: String) -> void:
	var translations = {
		"es": {
			"PLAY AGAIN": "JUGAR DE NUEVO",
			"MAIN MENU": "MENÚ PRINCIPAL",
			"WINNER": "GANADOR",
			"DRAW": "EMPATE",
		},
		"en": {
			"PLAY AGAIN": "PLAY AGAIN",
			"MAIN MENU": "MAIN MENU",
			"WINNER": "WINNER",
			"DRAW": "DRAW"
		}
	}

	var tr : Dictionary = translations.get(new_lang, {})
	for node in [play_again_button, main_menu_button,winner_title]:
		if node.has_meta("lang_key_base"):
			var key = node.get_meta("lang_key_base")
			node.text = tr.get(key, key)
