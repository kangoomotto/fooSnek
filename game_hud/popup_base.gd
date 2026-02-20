extends TextureRect
# =========================================================
# 🔹 PopupBase.gd
# Handles visual, audio, and FX presentation for a popup.
# Fully mobile-compatible with safe preloading of assets.
# =========================================================

@export var auto_hide_delay: float = 2.0

# =========================================================
# 🔹 RESOURCE PATH CONSTANTS
# =========================================================
const FX_DIR := "res://game_assets/Particles/"

# =========================================================
# 🔹 NODE REFERENCES
# =========================================================
@onready var particles: GPUParticles2D = $PopupParticles if has_node("PopupParticles") else null
var sfx_player: AudioStreamPlayer
var slot_type: String = ""
var extra_info: Dictionary = {}

# =========================================================
# 🔹 READY
# =========================================================
func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

# =========================================================
# 🔹 SIZE OVERRIDE
# =========================================================
func set_popup_size(size: Vector2) -> void:
	custom_minimum_size = size
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	self.size = size
	stretch_mode = TextureRect.STRETCH_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

# =========================================================
# 🔹 START POPUP
# =========================================================
func start(slot_type: String, screen_pos: Vector2, extra_info: Dictionary = {}, offset: Vector2 = Vector2.ZERO) -> void:
	self.slot_type = slot_type
	self.extra_info = extra_info
	position = screen_pos + offset
	_play_random_sfx(slot_type)
	_set_random_visual(slot_type)
	_load_and_emit_particles(slot_type)
	_show_popup()

# =========================================================
# 🔹 AUDIO FX
# =========================================================
func _play_random_sfx(slot_type: String) -> void:
	if slot_type not in POPUP_SFX:
		return
	var pool = POPUP_SFX[slot_type]
	if pool.is_empty():
		push_warning("⚠ No SFX for slot_type: " + slot_type)
		return
	var stream = pool.pick_random()
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

# =========================================================
# 🔹 SHOW POPUP (FIXED)
# =========================================================
func _show_popup() -> void:
	show()
	await get_tree().create_timer(auto_hide_delay).timeout
	EventsBus.popup_animation_done.emit()
	queue_free()

# =========================================================
# 🔹 VISUAL PNG
# =========================================================
func _set_random_visual(slot_type: String) -> void:
	if slot_type not in POPUP_IMAGES:
		return
	var pool = POPUP_IMAGES[slot_type]
	if pool.is_empty():
		push_warning("⚠ No popup images for slot_type: " + slot_type)
		return
	var tex = pool.pick_random()
	if tex:
		texture = tex

# =========================================================
# 🔹 PARTICLE FX (CLEANED)
# =========================================================
func _load_and_emit_particles(slot_type: String) -> void:
	if not particles:
		return
	var fx_map := {
		"goal": "blast_goal.tres",
		"ladder": "blast_jump_ladder.tres",
		"snake": "blast_jump_snake.tres",
		"kick": "blast_prize.tres",
		"corner": "blast_prize.tres",
		"penalty": "blast_prize.tres",
		"yellow": "blast_yellow.tres",
		"red": "blast_red.tres"
	}
	var fx_file = fx_map.get(slot_type, "")
	if fx_file.is_empty():
		return
	var material = load(FX_DIR + fx_file)
	if material:
		particles.process_material = material
		particles.emitting = true
	else:
		push_warning("⚠ Could not load particle material: " + fx_file)








# =========================================================
# 🔹 SAFE PRELOAD HELPER
# Warns if a resource is missing instead of breaking.
# =========================================================
func safe_load(path: String) -> Resource:
	var res = load(path)
	if res == null:
		push_warning("⚠ Resource missing or failed to load: " + path)
	return res

# =========================================================
# 🔹 PRELOADED POPUP IMAGE ARRAYS
# Each slot type has its images preloaded for Android compatibility
# =========================================================
var POPUP_IMAGES := {
		"miss_corner": [
		safe_load("res://game_assets/images/popup_cards/miss_corner_01.png"),
		safe_load("res://game_assets/images/popup_cards/miss_corner_02.png"),
	],

	"miss_kick": [
		safe_load("res://game_assets/images/popup_cards/miss_kick_01.png"),
	],

	"miss_penalty": [
		safe_load("res://game_assets/images/popup_cards/miss_penalty_01.png"),
	],
	"corner": [ 
		safe_load("res://game_assets/images/popup_cards/miss_corner_01.png"),
		safe_load("res://game_assets/images/popup_cards/miss_corner_02.png"),
		safe_load("res://game_assets/images/popup_cards/corner_01.png"),
		],
	"goal": [ 
		safe_load("res://game_assets/images/popup_cards/goal_01.png"),
		safe_load("res://game_assets/images/popup_cards/goal_02.png"),
		 ],
	"ladder": [ 
		safe_load("res://game_assets/images/popup_cards/ladder_01.png"),
		safe_load("res://game_assets/images/popup_cards/ladder_02.png"), 
		],
	"snake": [ 
		safe_load("res://game_assets/images/popup_cards/snake_01.png"),
		safe_load("res://game_assets/images/popup_cards/snake_02.png"),
		safe_load("res://game_assets/images/popup_cards/snake_03.png"),
		safe_load("res://game_assets/images/popup_cards/snake_04.png"),
		safe_load("res://game_assets/images/popup_cards/snake_05.png"), 
		],
	"kick": [ 
		safe_load("res://game_assets/images/popup_cards/kick_01.png"),
		safe_load("res://game_assets/images/popup_cards/miss_kick_01.png"), 
		],
	"penalty": [ safe_load("res://game_assets/images/popup_cards/penalty_01.png") ],
	"yellow": [ safe_load("res://game_assets/images/popup_cards/yellow_01.png") ],
	"red": [ 
		safe_load("res://game_assets/images/popup_cards/red_01.png"),
		safe_load("res://game_assets/images/popup_cards/red_01.png"), 
		],
	"extra_turn": [ safe_load("res://game_assets/images/popup_cards/extra_turn_01.png") ],
	"overshoot": [ 
		safe_load("res://game_assets/images/popup_cards/overshoot_01.png"),
		safe_load("res://game_assets/images/popup_cards/overshoot_02.png"), 
		]
}

# =========================================================
# 🔹 PRELOADED POPUP SFX ARRAYS
# Each slot type has its sounds preloaded
# =========================================================
var POPUP_SFX := {
	"corner": [ safe_load("res://game_assets/audio/popup_sfx/corner_01.ogg") ],
	"goal": [ safe_load("res://game_assets/audio/popup_sfx/goal_01.ogg") ],
	"ladder": [ safe_load("res://game_assets/audio/popup_sfx/ladder_01.ogg") ],
	"snake": [ safe_load("res://game_assets/audio/popup_sfx/snake_01.ogg") ],
	"kick": [ safe_load("res://game_assets/audio/popup_sfx/kick_01.ogg") ],
	"penalty": [ safe_load("res://game_assets/audio/popup_sfx/penalty_01.ogg") ],
	"yellow": [ safe_load("res://game_assets/audio/popup_sfx/yellow_01.ogg") ],
	"red": [ safe_load("res://game_assets/audio/popup_sfx/red_01.ogg") ],
	"extra_turn": [ safe_load("res://game_assets/audio/popup_sfx/extra_turn_01.ogg") ],
	"overshoot": [ safe_load("res://game_assets/audio/popup_sfx/overshoot_01.ogg") ]
}
