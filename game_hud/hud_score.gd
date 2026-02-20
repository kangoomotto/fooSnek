extends Panel
signal shield_clicked(player_index: int)
# res://game_hud/hud_score.gd

#@onready var shield_1: TextureRect = $HBoxContainer/Shield_1
#@onready var shield_2: TextureRect = $HBoxContainer/Shield_2
#@onready var highlight_1: Node = $HBoxContainer/Shield_1/Highlight_1
#@onready var highlight_2: Node = $HBoxContainer/Shield_2/Highlight_2
@onready var shield_1: TextureRect = $Shield_1
@onready var shield_2: TextureRect = $Shield_2
@onready var highlight_1: Node = $Shield_1/Highlight_1
@onready var highlight_2: Node = $Shield_2/Highlight_2

@onready var fire_ring_sprite_1: ColorRect = $Shield_1/Highlight_1/FireRing/RingSprite
@onready var fire_ring_sprite_2: ColorRect = $Shield_2/Highlight_2/FireRing/RingSprite

@onready var score_left: Label = $HBoxContainer/ScoreLabel_Left
@onready var score_right: Label = $HBoxContainer/ScoreLabel_Right

@onready var fire_ring_mat_1: ShaderMaterial = \
	$Shield_1/Highlight_1/FireRing/RingSprite.material

@onready var fire_ring_mat_2: ShaderMaterial = \
	$Shield_2/Highlight_2/FireRing/RingSprite.material
	
var current_game_mode: String = "cpu"
var current_selecting_player_index: int = 0

func _ready():
	# =========================================================
	# 🔹 ONE-TIME RESOURCE SETUP (MUST BE IN _ready)
	# ---------------------------------------------------------
	# ShaderMaterials are Resources → shared by default.
	# We duplicate them ONCE so each HUD fire ring
	# can have independent shader parameters.
	# Doing this anywhere else would cause leaks or overwrites.
	# =========================================================

	var mat1 := fire_ring_sprite_1.material as ShaderMaterial
	if mat1:
		mat1 = mat1.duplicate()
		fire_ring_sprite_1.material = mat1
		fire_ring_mat_1 = mat1

	var mat2 := fire_ring_sprite_2.material as ShaderMaterial
	if mat2:
		mat2 = mat2.duplicate()
		fire_ring_sprite_2.material = mat2
		fire_ring_mat_2 = mat2


	# =========================================================
	# 🔹 EVENT WIRING (ONE-TIME)
	# ---------------------------------------------------------
	# Signals are connections, not state.
	# They must be connected exactly once.
	# =========================================================

	# Team shield texture updates
	EventsBus.team_shield_updated.connect(func(player_index, shield_path):
		if player_index == 0 and shield_1:
			shield_1.texture = load(shield_path)
		elif player_index == 1 and shield_2:
			shield_2.texture = load(shield_path)
	)

	# Score changes
	EventsBus.score_updated.connect(_on_score_updated)

	# Active turn highlight (visibility only)
	EventsBus.active_player_highlight_changed.connect(_on_active_player_changed)

	# Game mode + player selection
	EventsBus.game_mode_selected.connect(_on_game_mode_changed)
	EventsBus.selecting_player_changed.connect(_on_selecting_player_changed)


	# =========================================================
	# 🔹 INPUT WIRING (ONE-TIME)
	# ---------------------------------------------------------
	# GUI input connections must never be repeated.
	# =========================================================

	shield_1.gui_input.connect(_on_shield1_input)
	shield_2.gui_input.connect(_on_shield2_input)
	shield_clicked.connect(_on_shield_clicked)


	# =========================================================
	# 🔹 INITIAL STATE (SAFE TO CALL ONCE)
	# ---------------------------------------------------------
	# These functions only SET state.
	# They do NOT allocate or duplicate resources.
	# =========================================================

	current_selecting_player_index = 0
	_disable_shield2_click()

	# Applies shader parameters + visibility
	_update_highlights()

	# Sets labels only
	_reset_scores()

# =========================================================
# 🔹 SCORE
# =========================================================
func _on_score_updated(player_id: int, new_score: int) -> void:
	## # print("🏆 HUD DEBUG → player:", player_id, "| new_score:", new_score)
	if player_id == 0:
		score_left.text = str(new_score)
	elif player_id == 1:
		score_right.text = str(new_score)

func _reset_scores():
	score_left.text = "0"
	score_right.text = "0"
	
# =========================================================
# 🔹 ACTIVE TURN HIGHLIGHT
# =========================================================
func _on_active_player_changed(player_index: int) -> void:
	highlight_1.visible = (player_index == 0)
	highlight_2.visible = (player_index == 1)


# =========================================================
# 🔹 MODE CHANGED
# =========================================================
func _on_game_mode_changed(mode: String) -> void:
	current_game_mode = mode

	# Lock to P1 in CPU mode
	if current_game_mode == "cpu":
		current_selecting_player_index = 0
		EventsBus.selecting_player_changed.emit(0)
		_disable_shield2_click()
	else:
		_enable_shield2_click()

	_update_highlights()


# =========================================================
# 🔹 PLAYER SELECTION CHANGED
# =========================================================
func _on_selecting_player_changed(index: int) -> void:
	current_selecting_player_index = index
	_update_highlights()


# =========================================================
# 🔹 SHIELD INPUT
# =========================================================
func _on_shield1_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		shield_clicked.emit(0)

func _on_shield2_input(event: InputEvent) -> void:
	if not visible:
		return
	if current_game_mode != "pvp":
		return
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		shield_clicked.emit(1)

func set_team_selection_active(active: bool) -> void:
	visible = active
	shield_1.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	shield_2.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE

# =========================================================
# 🔹 SHIELD CLICK HANDLER
# =========================================================
func _on_shield_clicked(player_index: int) -> void:
	# Switch active selection ONLY if player clicked the other shield
	current_selecting_player_index = player_index
	EventsBus.selecting_player_changed.emit(player_index)
	#EventsBus.request_team_menu.emit(player_index)
	_update_highlights()


# =========================================================
# 🔹 HIGHLIGHTS (selection)
# =========================================================
func _update_highlights():
	highlight_1.animation = "selected"
	highlight_1.play()
	highlight_2.animation = "selected"
	highlight_2.play()

	var pink := Color(1.0, 0.5608, 1.0, 1.0) # FF8FFF
	var cyan := Color(0.5333, 1.0, 1.0, 1.0) # 88FFFF

	fire_ring_mat_1.set_shader_parameter("core_color", pink)
	fire_ring_mat_1.set_shader_parameter("edge_color", pink)

	fire_ring_mat_2.set_shader_parameter("core_color", cyan)
	fire_ring_mat_2.set_shader_parameter("edge_color", cyan)

	highlight_1.visible = (current_selecting_player_index == 0)
	highlight_2.visible = (current_selecting_player_index == 1)

# =========================================================
# 🔹 CLICK LOCKS
# =========================================================
func _disable_shield2_click():
	shield_2.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _enable_shield2_click():
	shield_2.mouse_filter = Control.MOUSE_FILTER_STOP


# =========================================================
# 🔹 UPDATE SHIELDS TEXTURE
# =========================================================
func update_shields(shield_left: Texture2D, shield_right: Texture2D) -> void:
	if shield_1:
		shield_1.texture = shield_left
	if shield_2:
		shield_2.texture = shield_right
