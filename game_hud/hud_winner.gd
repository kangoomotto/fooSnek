#res://game_hud/hud_winner.gd

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

# =========================================================
# 🔹 READY
# =========================================================
func _ready() -> void:
	visible = false
	EventsBus.show_winner.connect(show_panel)
	play_again_button.pressed.connect(_on_play_again_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	#for child in $GridContainer.get_children():
		## print("✅ Grid child:", child.name)

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
# 🔹 BUTTONS
# =========================================================
func _on_play_again_pressed() -> void:
	visible = false
	EventsBus.play_again_requested.emit()

func _on_main_menu_pressed() -> void:
	visible = false
	EventsBus.main_menu.emit()
