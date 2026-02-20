extends Panel
# =========================================================
# 🔹 NODE REFERENCES

@onready var shield1: TextureRect = $GridContainer/HBoxContainer/Shield1
@onready var shield2: TextureRect = $GridContainer/HBoxContainer2/Shield2
@onready var name1: Label =  $GridContainer/Name1
@onready var name2: Label = $GridContainer/Name2
@onready var score1: Label = $GridContainer/HBoxContainer/Score1
@onready var score2: Label = $GridContainer/HBoxContainer2/Score2

@onready var continue_button: Button = $ContinueButton

# =========================================================
# 🔹 READY
func _ready() -> void:
	visible = false
	#EventsBus.show_halftime.connect(show_panel)
	continue_button.pressed.connect(_on_continue_button_pressed)
# =========================================================
# 🔹 SHOW PANEL
func show_panel(stats: Dictionary) -> void:
	# print("showing halftime panel")
	update_panel(stats)
	visible = true
# =========================================================
# 🔹 UPDATE PANEL DATA
func update_panel(stats: Dictionary) -> void:
	var teams: Array = stats.get("teams", [])
	if teams.size() >= 2:
		# Player 1
		name1.text = teams[0].get("name", "Unknown")
		score1.text = str(teams[0].get("score", 0))
		_set_shield_texture(shield1, teams[0].get("shield", ""))

		# Player 2
		name2.text = teams[1].get("name", "Unknown")
		score2.text = str(teams[1].get("score", 0))
		_set_shield_texture(shield2, teams[1].get("shield", ""))
# =========================================================
# 🔹 SHIELD LOADER
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
	## print("▶ HUD_Halftime → Continue pressed")
	visible = false
	EventsBus.resume_timer.emit()
	EventsBus.halftime_closed.emit()

func _process(_delta):
	if visible:
		pass
		## print("👀 HALFTIME PANEL STILL VISIBLE")
