extends Node

# =========================================================
# 🔹 AUDIO NODES
# =========================================================
@onready var ambience_player: AudioStreamPlayer2D = $AmbiencePlayer
@onready var sfx_player: AudioStreamPlayer2D = $SFXPlayer
@onready var commentary_player: AudioStreamPlayer2D = $CommentaryPlayer

@onready var ambience_loops: Array = []
var ambience_timer: Timer = null

# HARD GATE — ONLY THIS CONTROLS AMBIENCE + COMMENTARY
var audio_enabled: bool = false


# =========================================================
# 🔹 SFX TABLES (NEVER MUTED)
# =========================================================
var button_sfx = {
	"click": load("res://game_assets/audio/buttons/ui_click_01.ogg"),
	"hover": load("res://game_assets/audio/buttons/6ui_hover_01.ogg")
}

var popup_sfx = {
	"correct": load("res://game_assets/audio/popup_sfx/correct.ogg"),
	"incorrect": load("res://game_assets/audio/popup_sfx/incorrect.ogg"),
	"boo": load("res://game_assets/audio/popup_sfx/boo_01.ogg"),
	"extra_turn": load("res://game_assets/audio/popup_sfx/extra_turn_01.ogg"),
	"goal": load("res://game_assets/audio/popup_sfx/goal_01.ogg"),
	"kick": load("res://game_assets/audio/popup_sfx/kick_01.ogg"),
	"corner": load("res://game_assets/audio/popup_sfx/corner_01.ogg"),
	"yellow": load("res://game_assets/audio/popup_sfx/yellow_01.ogg"),
	"red": load("res://game_assets/audio/popup_sfx/red_01.ogg"),
	"move": load("res://game_assets/audio/popup_sfx/move_chip.ogg"),
	"move_back": load("res://game_assets/audio/popup_sfx/move_back.ogg"),
	"overshoot": load("res://game_assets/audio/popup_sfx/overshoot_01.ogg"),
	"ladder": load("res://game_assets/audio/popup_sfx/ladder_01.ogg"),
	"snake": load("res://game_assets/audio/popup_sfx/snake_01.ogg"),
	"start_timer": load("res://game_assets/audio/popup_sfx/start_timer_01.ogg"),
	"half_time": load("res://game_assets/audio/popup_sfx/half_time.ogg"),
	"end_game": load("res://game_assets/audio/popup_sfx/end_game.ogg"),
	"next_turn": load("res://game_assets/audio/popup_sfx/next_turn_01.ogg")
}

var dice_sfx = {
	"roll": load("res://game_assets/audio/dice/dice_roll_01.ogg"),
	"impact": load("res://game_assets/audio/dice/dice_hit_01.ogg")
}

var commentary_sfx: Array = [
	load("res://game_assets/audio/commentary/commentary_01.ogg"),
	load("res://game_assets/audio/commentary/commentary_02.ogg"),
	load("res://game_assets/audio/commentary/free_kick.ogg")
]


# =========================================================
# 🔹 PUBLIC API
# =========================================================
func set_audio_enabled(enabled: bool) -> void:
	audio_enabled = enabled

	if not audio_enabled:
		if ambience_timer:
			ambience_timer.stop()
			ambience_timer.queue_free()
			ambience_timer = null

		ambience_player.stop()
		commentary_player.stop()
	else:
		if ambience_player.playing:
			return
		_play_random_ambience()

# =========================================================
# 🔹 READY
# =========================================================
func _ready():
	sfx_player.stream = dice_sfx["impact"]
	sfx_player.stop()

	_load_ambience_files()
	_register_signals()

	if audio_enabled:
		_play_random_ambience()


# =========================================================
# 🔹 AMBIENCE FILES
# =========================================================
func _load_ambience_files() -> void:
	var dir = DirAccess.open("res://game_assets/audio/ambience")
	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(".ogg"):
			ambience_loops.append(load("res://game_assets/audio/ambience/" + file_name))
		file_name = dir.get_next()
	dir.list_dir_end()


# =========================================================
# 🔹 SIGNAL CONNECTIONS
# =========================================================
func _register_signals():
	EventsBus.request_popup_sfx.connect(_on_popup_sfx)
	EventsBus.request_dice_roll_sfx.connect(_on_dice_roll_sfx)
	EventsBus.request_dice_impact_sfx.connect(_on_dice_impact_sfx)
	EventsBus.request_ui_click_sfx.connect(_on_ui_click_sfx)
	EventsBus.request_commentary.connect(_on_commentary)
	EventsBus.start_timer.connect(_on_start_timer)
	EventsBus.halftime_reached.connect(_on_halftime_commentary)
	EventsBus.match_ended.connect(_on_final_commentary)


# =========================================================
# 🔹 AMBIENCE (ABSOLUTELY HARD-GATED)
# =========================================================
func _play_random_ambience():
	if not audio_enabled:
		return
	if ambience_loops.is_empty():
		return

	var stream = ambience_loops.pick_random()

	ambience_player.stop()
	ambience_player.stream = stream
	ambience_player.play()

	if ambience_timer:
		ambience_timer.stop()
		ambience_timer.queue_free()

	ambience_timer = Timer.new()
	ambience_timer.one_shot = true
	ambience_timer.wait_time = stream.get_length() + randf_range(5.0, 10.0)
	add_child(ambience_timer)

	ambience_timer.timeout.connect(func():
		if audio_enabled:
			_play_random_ambience()
	)

	ambience_timer.start()

# =========================================================
# 🔹 COMMENTARY EVENTS
# =========================================================
func _on_halftime_commentary():
	if not audio_enabled or commentary_sfx.is_empty():
		return

	commentary_player.stop()
	commentary_player.stream = commentary_sfx.pick_random()
	commentary_player.play()


func _on_final_commentary():
	if not audio_enabled or commentary_sfx.is_empty():
		return

	commentary_player.stop()
	commentary_player.stream = commentary_sfx.pick_random()
	commentary_player.play()


# =========================================================
# 🔹 POPUP / SLOT SFX
# =========================================================
func _on_popup_sfx(slot_type: String) -> void:
	if popup_sfx.has(slot_type):
		sfx_player.stop()
		sfx_player.stream = popup_sfx[slot_type]
		sfx_player.play()


# =========================================================
# 🔹 DICE SFX
# =========================================================
func _on_dice_roll_sfx():
	sfx_player.stream = dice_sfx["roll"]
	sfx_player.play()


func _on_dice_impact_sfx():
	sfx_player.stream = dice_sfx["impact"]
	sfx_player.play()


# =========================================================
# 🔹 UI BUTTON SFX
# =========================================================
func _on_ui_click_sfx(action_name: String):
	if button_sfx.has(action_name):
		sfx_player.stream = button_sfx[action_name]
		sfx_player.play()


# =========================================================
# 🔹 COMMENTARY (HARD-GATED)
# =========================================================
func _on_commentary(context: Dictionary):
	if not audio_enabled:
		return

	var slot_type = context.get("slot_type", "")
	if popup_sfx.has(slot_type):
		sfx_player.stream = popup_sfx[slot_type]
		sfx_player.play()
	elif not commentary_sfx.is_empty():
		commentary_player.stream = commentary_sfx.pick_random()
		commentary_player.play()


# =========================================================
# 🔹 TIMER / PANEL SFX
# =========================================================
func _on_start_timer():
	if popup_sfx.has("start_timer"):
		sfx_player.stream = popup_sfx["start_timer"]
		sfx_player.play()


func play_half_time_whistle():
	if popup_sfx.has("half_time"):
		sfx_player.stream = popup_sfx["half_time"]
		sfx_player.play()


func play_end_game_whistle():
	if popup_sfx.has("end_game"):
		sfx_player.stream = popup_sfx["end_game"]
		sfx_player.play()
