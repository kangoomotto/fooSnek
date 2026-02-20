#chips.gd
extends Node2D
# =========================================================
# 🎯 ROLE
# ---------------------------------------------------------
# Handles all chip movement and positional logic.
# Chips never reposition their own sprite; all movement
# is done by tweening the Node2D transform.
#
# This version introduces a global visual offset to make
# chips appear slightly higher (≈20px) in every slot without
# altering slot or sprite origins.
# =========================================================


# =========================================================
# 🔹 CHIP STATE
# =========================================================
var chip_current_box: int = 0
var score: int = 0
var chip_owner: int = 0	# 0 = Player 1, 1 = Player 2
var team_name: String = ""
var team_shield: Texture2D = null

@onready var board_manager = get_node("/root/MAIN/BoardManager")
@onready var ring_material := $FireRing/RingSprite.material as ShaderMaterial

signal move_finished

## 🔍 DIAGNOSTIC: score setter trap — remove after finding the bug
#var _score_internal: int = 0
#var score: int:
	#get:
		#return _score_internal
	#set(value):
		#if value != _score_internal:
			#print("📊 [SCORE] Player %d: %d → %d" % [chip_owner, _score_internal, value])
			#print(get_stack())
		#_score_internal = value
		#

# =========================================================
# 🔹 GLOBAL POSITION OFFSET
# ---------------------------------------------------------
# This offset is added to every slot position retrieved
# from BoardManager. Negative Y = visually higher on screen.
# Adjust this single value to fine-tune vertical centering.
# =========================================================
#const CHIP_Y_OFFSET := Vector2(0, -50)	# raise chip 20px

const PLAYER_VISUAL_OFFSETS := {
	0: Vector2(-50, 15),	# Pink
	1: Vector2(0, 0)	# Cyan
}

func _ready() -> void:
	EventsBus.active_player_highlight_changed.connect(_on_active_player_changed)
	EventsBus.board_ready.connect(_on_board_ready)

	var mat := $FireRing/RingSprite.material as ShaderMaterial
	if mat == null:
		return

	# Duplicate so each chip has its own instance
	mat = mat.duplicate()
	$FireRing/RingSprite.material = mat
	ring_material = mat

	# Per-player color override
	if chip_owner == 0:
		# Soft inner glow (light pink)
		mat.set_shader_parameter("core_color", Color(1.0, 0.55, 0.75))
		# Intense outer energy (hot magenta)
		mat.set_shader_parameter("edge_color", Color(1.0, 0.15, 0.6))
	else:
		# Soft inner glow (light cyan)
		mat.set_shader_parameter("core_color", Color(0.55, 0.95, 1.0))
		# Intense outer energy (electric cyan)
		mat.set_shader_parameter("edge_color", Color(0.0, 0.85, 1.0))

		
func _on_board_ready() -> void:
	apply_visual_state()

func _get_visual_offset() -> Vector2:
	return PLAYER_VISUAL_OFFSETS.get(chip_owner, Vector2.ZERO)

func _on_active_player_changed(active_player_index: int) -> void:
	# Toggle FireRing visibility
	$FireRing.set_active(chip_owner == active_player_index)
	
	# Update FireTrail color to match active chip
	var fire_trail = $FireTrail/TrailLine as Line2D
	if fire_trail:
		fire_trail.default_color = Color8(0, 255, 255) if chip_owner == 0 else Color8(255, 105, 180)

func apply_visual_state() -> void:
	var bm := get_tree().get_root().get_node("/root/MAIN/BoardManager")
	position = bm.get_box_position(chip_current_box) + _get_visual_offset()

# =========================================================
# 🔹 MOVE CHIP SEQUENTIALLY (FIXED FOR OVERSHOOT)
# ---------------------------------------------------------
# This function now moves the chip forward the correct number
# of times, regardless of overshoot. It does NOT use a
# while loop that checks the current box, as that was
# causing it to move backwards on overshoots.
# =========================================================
func move_to_index(target_index: int, duration := 0.3) -> void:
	#func move_to_index(target_index: int, duration := 0.3, emit_finished := true) -> void:
	
	var steps_to_take = target_index - chip_current_box
	
	# Handle moving backwards
	if steps_to_take < 0:
		while chip_current_box > target_index:
			chip_current_box -= 1
			EventsBus.request_popup_sfx.emit("move_back")
			await move_to_box(chip_current_box, duration)
	# Handle moving forwards (including overshoot)
	else:
		for i in range(steps_to_take):
			chip_current_box += 1
			EventsBus.request_popup_sfx.emit("move")
			await move_to_box(chip_current_box, duration)

	EventsBus.chip_move_finished.emit(chip_owner, chip_current_box)
	#if emit_finished:
		#EventsBus.chip_move_finished.emit(chip_owner, chip_current_box)

# =========================================================
# 🔹 MOVE TO SINGLE BOX (CLEAN VERSION)
# ---------------------------------------------------------
# Moves the chip to the exact position of the index given.
# The BoardManager is responsible for having a position for
# every index, including ghost track indices.
# =========================================================
func move_to_box(index: int, duration := 0.1) -> void:
	var target_position = board_manager.get_box_position(index) + _get_visual_offset()
	var tween := create_tween()
	tween.tween_property(self, "position", target_position, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

# =========================================================
# 🔹 DIRECT JUMP
# ---------------------------------------------------------
# Used for ladders/snakes or teleport-like motion.
# Also applies CHIP_Y_OFFSET consistently.
# =========================================================
func jump_to_index(index: int, duration := 1) -> void:
	$FireTrail.start()
	
	var slot_data = board_manager.get_slot_data(index)
	var target_pos = board_manager.get_box_position(index) +  _get_visual_offset()

	# Pull move_duration from slot data or use default
	var move_duration = slot_data.get("on_land", {}).get("move_duration", duration)

	var tween := create_tween()
	tween.tween_property(self, "position", target_pos, move_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
	$FireTrail.stop()
	
	chip_current_box = index
	move_finished.emit()


# =========================================================
# 🔹 RETURN TO START
# ---------------------------------------------------------
# Moves chip back to slot 0 (spawn/start position).
# If punished, hops fast; otherwise, jumps smoothly.
# =========================================================
func return_to_start(reason := "default") -> void:
	if reason == "punish":
		# Fast backward hop
		for i in range(chip_current_box - 1, -1, -1):
			await move_to_index(i, 0.1)
	else:
		# Smooth full jump
		await jump_to_index(0)

	chip_current_box = 0
	move_finished.emit()

# =========================================================
# 🔹 GOAL ANIMATION (stub)
# ---------------------------------------------------------
# Called when chip reaches goal slot.
# Can be expanded with celebration FX or camera work.
# =========================================================
func go_to_goal() -> void:
	var goal_index = 25 #board_manager.get_final_slot_index()
	await jump_to_index(goal_index)
