# res://game_hud/hud_halftime.gd
extends Panel

# =========================================================
# 🔹 NODE REFERENCES
# =========================================================
@onready var shield1: TextureRect = $GridContainer/HBoxContainer/Shield1
@onready var shield2: TextureRect = $GridContainer/HBoxContainer2/Shield2
@onready var name1: Label = $GridContainer/Name1
@onready var name2: Label = $GridContainer/Name2
@onready var score1: Label = $GridContainer/HBoxContainer/Score1
@onready var score2: Label = $GridContainer/HBoxContainer2/Score2
@onready var continue_button: Button = $ContinueButton
@onready var halftime_title: Label = $hud_title

# =========================================================
# 🔹 READY
# =========================================================
# =========================================================
# 🔹 READY
# =========================================================
func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue_button_pressed)

	# Store base key for localization
	continue_button.set_meta("lang_key_base", "CONTINUE")
	halftime_title.set_meta("lang_key_base", "HALFTIME")
	
	_update_language_ui(LanguageManager.get_language())

	# Wire live language updates directly to LanguageManager
	LanguageManager.language_changed.connect(_update_language_ui)

# =========================================================
# 🔹 SHOW PANEL
# =========================================================
func show_panel(stats: Dictionary) -> void:
	update_panel(stats)
	visible = true

# =========================================================
# 🔹 UPDATE PANEL DATA
# =========================================================
func update_panel(stats: Dictionary) -> void:
	var teams: Array = stats.get("teams", [])
	if teams.size() >= 2:
		name1.text = teams[0].get("name", "Unknown")
		score1.text = str(teams[0].get("score", 0))
		_set_shield_texture(shield1, teams[0].get("shield", ""))

		name2.text = teams[1].get("name", "Unknown")
		score2.text = str(teams[1].get("score", 0))
		_set_shield_texture(shield2, teams[1].get("shield", ""))

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
# 🔹 CONTINUE BUTTON
# =========================================================
func _on_continue_button_pressed() -> void:
	visible = false
	EventsBus.resume_timer.emit()
	EventsBus.halftime_closed.emit()

# =========================================================
# 🔹 LIVE LOCALIZATION
# =========================================================
func _update_language_ui(new_lang: String) -> void:
	var translations = {
		"es": {
			"CONTINUE": "CONTINUAR",
			"HALFTIME": "MEDIO TIEMPO"
		},
		"en": {
			"CONTINUE": "CONTINUE",
			"HALFTIME": "HALFTIME"
		}
	}

	var tr = translations.get(new_lang, {})
	for node in [continue_button, halftime_title]:
		if node.has_meta("lang_key_base"):
			var key = node.get_meta("lang_key_base")
			node.text = tr.get(key, key)
