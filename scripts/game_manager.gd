# =========================================================
# GameManager.gd
# ---------------------------------------------------------
# Role: Central orchestrator for the game.
# - Manages the finite state machine (FSM) via GameState.
# - Drives turn flow, dice/quiz/popup coordination, scoring, and CPU behavior.
# - Uses EventsBus for loose coupling; other systems emit/listen here.
# =========================================================

extends Node2D

# =========================================================
# 🔹 CONSTANTS & STATES
# =========================================================
const GameState = preload("res://scripts/game_state.gd").GameState
enum PanelPending { NONE, HALFTIME, WINNER }
const POPUP_SAFETY_TIMEOUT := 15.0

# =========================================================
# 🔹 VARIABLES
# =========================================================
var game_mode: String = "cpu"
var current_state: int = GameState.START_MENU
var current_turn: int = 0
var current_chip: Node2D
var last_slot_result: Dictionary = {}
var chips: Array[Node2D] = []
var timer_started: bool = false

var dice_result_received: bool = false
var pending_panel: int = PanelPending.NONE
var panel_shown: bool = false
var current_teams_list: Array = TeamsDB.liga_mx_teams

var waiting_for_blocking_popup: bool = false

# ✅ NEW — single callback replaces all popup coordination flags
var _post_popup_callback: Callable = Callable()
var _cpu_roll_pending: bool = false

# Teams
var selected_team_id_p1: String = ""
var selected_team_id_p2: String = ""
var selected_court: Dictionary = {}

# Frame guard to prevent duplicate advances in the same frame
var _last_advance_frame: int = 0

# =========================================================
# 🔹 NODE REFERENCES
# =========================================================
@onready var board_manager: BoardManager = get_node("/root/MAIN/BoardManager")
@onready var board_layout: Node2D = get_node("/root/MAIN/BoardLayout")

# =========================================================
# 🔹 DEBUG
# =========================================================
@export var DEBUG_MODE: bool = false
#@export var debug_score_p1: int = 0
#@export var debug_score_p2: int = 0
@export var force_dice: int = 0
@export var cpu_difficulty: float = 0.5
@export var DEBUG_SKIP_MENUS: bool = false
@export var POPUPS_ENABLED: bool = true

@export var POPUP_VISUAL_FEEDBACK: Dictionary = {
	"yellow": true,
	"red": true,
	"goal": true,
	"ladder": true,
	"snake": true,
	"kick": true,
	"corner": true,
	"penalty": true,
}

# =========================================================
# 🔹 READY
# =========================================================
func _ready():
	_initialize_teams_and_court()
	_initialize_team_signals()

	# FSM core connections
	EventsBus.pause_requested.connect(_on_pause_requested)
	EventsBus.resume_pressed.connect(_on_resume_pressed)
	EventsBus.start_pressed.connect(_on_start_pressed)
	EventsBus.request_dice_roll.connect(_on_request_dice_roll)
	EventsBus.dice_roll_started.connect(_on_dice_roll_started)
	EventsBus.dice_rolled.connect(_on_dice_rolled)
	EventsBus.quiz_completed.connect(_on_quiz_completed)
	EventsBus.popup_animation_done.connect(_on_popup_animation_done)
	EventsBus.halftime_closed.connect(_on_halftime_closed)
	EventsBus.play_again_requested.connect(_on_play_again_pressed)
	EventsBus.winner_declared.connect(_on_winner_declared)
	EventsBus.main_menu.connect(_on_main_menu)
	EventsBus.halftime_reached.connect(_on_halftime_reached)
	EventsBus.match_ended.connect(_on_match_ended)
	EventsBus.game_mode_selected.connect(func(mode_id: String): game_mode = mode_id)
	EventsBus.board_ready.connect(_on_board_ready)

	# Movement and outcome signals
	EventsBus.dice_roll_finished.connect(_resolve_dice_movement)
	EventsBus.chip_move_finished.connect(_on_chip_move_finished)

	# Chips manually placed in editor
	var chip_p1 = board_layout.get_node("playerChipPink")
	var chip_p2 = board_layout.get_node("playerChipCyan")
	chip_p1.chip_owner = 0
	chip_p2.chip_owner = 1
	chip_p1.z_index = 100
	chip_p2.z_index = 100
	chips = [chip_p1, chip_p2]
	current_chip = chips[current_turn]

	_reset_chips()

	if DEBUG_SKIP_MENUS:
		EventsBus.debug_skip_menus_enabled.emit()

	EventsBus.popup_visual_feedback.emit(POPUP_VISUAL_FEEDBACK)

	_change_state(GameState.START_MENU)
	_highlight_active_player(current_turn)

	# Only tick _process when debugging
	set_process(DEBUG_MODE)

# =========================================================
# 🔹 CHIP MOVE FINISHED (OVERSHOOT/BOUNCE-BACK)
# ---------------------------------------------------------
# Resolves the chip's final position, translating ghost track
# indices (26–30) back to real board slots via bounce-back.
# Empty/no-op slots advance directly — no fake popups needed.
# =========================================================
func _on_chip_move_finished(player_id: int, final_index: int) -> void:
	# CRITICAL: Only process dice-initiated movement, not callback movement
	if current_state != GameState.MOVING_CHIP:
		return
	if player_id != current_turn:
		return

	var real_index = _translate_overshoot_index(final_index)

	if final_index > 25:
		await current_chip.jump_to_index(real_index)
		current_chip.chip_current_box = real_index

	_change_state(GameState.RESOLVING_SLOT)
	var landed = board_manager.get_slot_data(real_index)

	if landed.is_empty():
		_advance_turn_flow("empty_slot")
		return

	var slot_type = landed.get("type", "")
	if slot_type in ["yellow", "red", "kick", "corner"]:
		_on_quiz_requested(chips[player_id], landed)
		return

	var outcome = board_manager.resolve_outcome(chips[player_id], landed, false)
	#if outcome.get("outcome", {}).get("do_nothing", false):
		#_advance_turn_flow("no_op_slot")
		#return

	_handle_outcome_result(outcome)

func _on_board_ready() -> void:
	_highlight_active_player(current_turn)

# =========================================================
# 🔹 PAUSE/RESUME HANDLERS
# =========================================================
func _on_pause_requested() -> void:
	if current_state == GameState.GAME_PAUSED or current_state == GameState.START_MENU:
		return
	current_state = GameState.GAME_PAUSED
	EventsBus.pause_timer.emit()
	EventsBus.dice_roll_enabled.emit(false)

func _on_resume_pressed() -> void:
	if current_state != GameState.GAME_PAUSED:
		return
	current_state = GameState.AWAITING_ROLL
	EventsBus.resume_timer.emit()
	EventsBus.dice_roll_enabled.emit(true)

# =========================================================
# 🔹 CHIP RESET AND VISUALS
# =========================================================
func _reset_chips():
	for chip in chips:
		chip.apply_visual_state()
		chip.score = 0
		chip.return_to_start("punish")
		var trail_color: Color = Color8(0, 255, 255) if chip.chip_owner == 0 else Color8(255, 105, 180)
		var fire_trail = chip.get_node("FireTrail/TrailLine") as Line2D
		if fire_trail:
			fire_trail.default_color = trail_color
			fire_trail.clear_points()

# =========================================================
# 🔹 TIME PANEL FLAGS (HALFTIME/WINNER)
# =========================================================
func _on_halftime_reached() -> void:
	if panel_shown:
		return
	pending_panel = PanelPending.HALFTIME
	_check_time_panels_idle()
	var audio_brain := get_node_or_null("/root/AudioBrain")
	if audio_brain:
		audio_brain.play_half_time_whistle()

func _on_match_ended() -> void:
	if panel_shown:
		return
	pending_panel = PanelPending.WINNER
	_check_time_panels_idle()
	var audio_brain := get_node_or_null("/root/AudioBrain")
	if audio_brain:
		audio_brain.play_end_game_whistle()

# =========================================================
# 🔹 MATCH FLOW (START, PLAY AGAIN, MAIN MENU)
# =========================================================
func _on_start_pressed() -> void:
	get_tree().paused = false
	var audio_brain := get_node_or_null("/root/AudioBrain")
	if audio_brain:
		audio_brain._resume_ambience()
	_change_state(GameState.AWAITING_ROLL)
	if selected_court.is_empty():
		selected_court = CourtsDB.get_court_by_id("stadium")
	EventsBus.court_selected.emit(selected_court)
	_assign_chip_team_data(current_teams_list)

func _on_play_again_pressed():
	_resetGame()
	EventsBus.hud_reset_requested.emit()
	var audio_brain := get_node_or_null("/root/AudioBrain")
	if audio_brain:
		audio_brain._pause_ambience()
	_change_state(GameState.START_MENU)

func _on_main_menu() -> void:
	get_tree().paused = true
	_resetGame()
	EventsBus.hud_reset_requested.emit()
	var audio_brain := get_node_or_null("/root/AudioBrain")
	if audio_brain:
		audio_brain._pause_ambience()
	_change_state(GameState.START_MENU)

func _resetGame() -> void:
	panel_shown = false
	pending_panel = PanelPending.NONE
	waiting_for_blocking_popup = false
	_post_popup_callback = Callable()
	_cpu_roll_pending = false
	timer_started = false
	dice_result_received = false
	last_slot_result.clear()
	current_turn = 0
	current_chip = chips[current_turn]
	_reset_chips()
	_highlight_active_player(current_turn)
	for i in range(chips.size()):
		chips[i].score = 0
		EventsBus.score_updated.emit(i, 0)
	selected_court = CourtsDB.get_court_by_id("stadium")
	_assign_chip_team_data(current_teams_list)

func _on_halftime_closed():
	panel_shown = false
	_change_state(GameState.AWAITING_ROLL)

func _on_winner_declared(winner_id: int, stats: Dictionary):
	_change_state(GameState.SHOWING_WINNER)
	EventsBus.show_winner.emit(winner_id, stats)

# =========================================================
# 🔹 TURN CONTROL
# ---------------------------------------------------------
# _next_turn: switches the active player.
# _advance_turn_flow: THE single gate for all turn advances.
#   Every code path in the game converges here — directly
#   for no-popup slots, or via _on_popup_animation_done for
#   popup slots. No other function may switch turns.
# =========================================================
func _next_turn():
	EventsBus.request_popup_sfx.emit("next_turn")
	current_turn = 1 - current_turn
	current_chip = chips[current_turn]
	_highlight_active_player(current_turn)
	_change_state(GameState.AWAITING_ROLL)

func _advance_turn_flow(source: String) -> void:
	if DEBUG_MODE:
		print("🔀 [TURN] _advance_turn_flow | source: ", source)

	# Frame guard — prevent double-advances in the same frame
	var current_frame = Engine.get_process_frames()
	if current_frame == _last_advance_frame:
		if DEBUG_MODE:
			print("⚠️ [TURN] Blocking duplicate advance in same frame | source: ", source)
		return
	_last_advance_frame = current_frame

	# Never advance while a popup is pending
	if waiting_for_blocking_popup:
		if DEBUG_MODE:
			print("⏸️ [TURN] Blocked by popup | source: ", source)
		return

	# Extra turn: only on correct punish cards (yellow/red)
	if last_slot_result.get("extra_turn", false):
		last_slot_result["extra_turn"] = false
		if DEBUG_MODE:
			print("🌀 [TURN] Extra turn → Player: ", current_turn)
		_change_state(GameState.AWAITING_ROLL)
		_highlight_active_player(current_turn)
		return

	# Normal turn switch
	if DEBUG_MODE:
		print("➡️ [TURN] Switching from player ", current_turn)
	_next_turn()

func _highlight_active_player(player_index: int):
	EventsBus.active_player_highlight_changed.emit(player_index)

# =========================================================
# 🔹 DICE FLOW
# =========================================================
func _on_request_dice_roll():
	if current_state != GameState.AWAITING_ROLL or current_state == GameState.GAME_PAUSED:
		return
	EventsBus.dice_roll_started.emit()

func _on_dice_roll_started():
	if current_state != GameState.AWAITING_ROLL:
		return
	dice_result_received = false
	await get_tree().process_frame
	_change_state(GameState.ROLLING)
	if not timer_started:
		timer_started = true
		EventsBus.start_timer.emit()
	if DEBUG_MODE and force_dice > 0:
		await get_tree().process_frame
		EventsBus.dice_rolled.emit(force_dice)

func _on_dice_rolled(value: int) -> void:
	if dice_result_received or current_state != GameState.ROLLING:
		return
	dice_result_received = true
	last_slot_result = {}  # Clear stale data before new movement
	_change_state(GameState.MOVING_CHIP)
	var chip = chips[current_turn]
	EventsBus.dice_roll_finished.emit(chip, value)

func _resolve_dice_movement(chip: Node2D, roll_value: int) -> void:
	var start_index = chip.chip_current_box
	var raw_target = start_index + roll_value
	var final_index = min(raw_target, 30)
	if DEBUG_MODE:
		print("🎲 [MOVE] Player ", chip.chip_owner, " rolling ", roll_value, " → index ", final_index)
	await chip.move_to_index(final_index)

func _translate_overshoot_index(ghost_index: int) -> int:
	var final_slot = 25
	if ghost_index <= final_slot:
		return ghost_index
	var overshoot = ghost_index - final_slot
	return final_slot - overshoot

func _force_dice_roll(value: int):
	if current_state == GameState.AWAITING_ROLL:
		EventsBus.dice_roll_started.emit()
		await get_tree().process_frame
		EventsBus.dice_rolled.emit(value)

# =========================================================
# 🔹 QUIZ FLOW (PLAYER + CPU)
# ---------------------------------------------------------
# CPU auto-answers bypass the QUIZ state entirely and feed
# directly into _handle_outcome_result. Player flow pauses
# the timer and waits for quiz_completed from QuizUI.
# =========================================================
func _on_quiz_requested(chip: Node2D, slot_data: Dictionary):
	var slot_type = slot_data.get("type", "")

	if is_cpu_turn():
		var is_correct := false
		if slot_type in ["yellow", "red"]:
			is_correct = false
		elif slot_type in ["kick", "corner"]:
			is_correct = _evaluate_cpu_prize_success()
		var outcome = board_manager.resolve_outcome(chip, slot_data, is_correct)
		await _handle_outcome_result(outcome)
		return

	# Player flow
	EventsBus.pause_timer.emit()
	EventsBus.quiz_requested.emit(chip, slot_data)
	_change_state(GameState.QUIZ)

func _on_quiz_completed(chip: Node2D, correct: bool) -> void:
	if current_state != GameState.QUIZ:
		return

	EventsBus.resume_timer.emit()

	var landed = board_manager.get_slot_data(chip.chip_current_box)
	if landed.is_empty():
		_advance_turn_flow("quiz_empty_slot")
		return

	var outcome = board_manager.resolve_outcome(chip, landed, correct)
	await _handle_outcome_result(outcome)

# =========================================================
# 🔹 OUTCOME PIPELINE
# ---------------------------------------------------------
# _handle_outcome_result routes to exactly ONE handler.
# Each handler is self-contained: it applies its effects,
# optionally shows a blocking popup (with a post-popup
# callback), and the turn advances when the popup closes.
#
# No fall-through. No shared flags. No cross-handler state.
# =========================================================
func _handle_outcome_result(result: Dictionary) -> void:
	if result.is_empty():
		_advance_turn_flow("outcome_empty")
		return

	var chip: Node2D = result["chip"]
	var outcome: Dictionary = result["outcome"]
	var slot_type: String = result["slot_type"]
	var is_correct: bool = result.get("is_correct", false)

	# Record for extra-turn logic (single source of truth)
	last_slot_result = {
		"chip": chip,
		"slot_type": slot_type,
		"is_correct": is_correct,
		"extra_turn": outcome.get("extra_turn", false) and (slot_type in ["yellow", "red"] and is_correct),
	}

	# Route to exactly one handler — order matters
	if outcome.get("is_goal", false):
		await _handle_goal_outcome(chip, outcome, is_correct)
	elif outcome.get("return_to_start", false):
		await _handle_punish_outcome(chip, outcome)
	elif outcome.get("move_to") != null:
		_handle_movement_outcome(chip, outcome, is_correct)
	elif outcome.get("visual_feedback", false):
		_handle_visual_feedback_outcome(chip, outcome, is_correct)
	else:
		# No popup, no movement — just score and advance
		_apply_score(chip, outcome)
		_advance_turn_flow("outcome_no_action")

# =========================================================
# 🔹 GOAL OUTCOME
# ---------------------------------------------------------
# Score first, then show popup. After popup closes, the
# callback returns the chip to start, then turn advances.
# =========================================================
func _handle_goal_outcome(chip: Node2D, outcome: Dictionary, is_correct: bool) -> void:
	# Kick/corner correct: chip must visually travel to goal first
	if outcome.get("jump_to_goal", false):
		await chip.go_to_goal()

	chip.score += outcome.get("score", 1)
	EventsBus.request_commentary.emit({"slot_type": "goal"})
	EventsBus.score_updated.emit(chip.chip_owner, chip.score)

	_show_blocking_popup("goal", chip.global_position, is_correct, outcome, func():
		await chip.return_to_start()
	)

# =========================================================
# 🔹 PUNISH OUTCOME (return to start)
# ---------------------------------------------------------
# Show popup first. After popup closes, the callback moves
# the chip to start and applies score penalties.
# =========================================================
func _handle_punish_outcome(chip: Node2D, outcome: Dictionary) -> void:
	var popup_type = outcome.get("popup_type", "")
	var is_correct = last_slot_result.get("is_correct", false)
	var move_speed = outcome.get("move_duration", 0.3)
	
		# Apply score IMMEDIATELY — before popup can modify outcome dict
		# Score applied ONCE, here, before popup
	_apply_score(chip, outcome)
	
	_show_blocking_popup(popup_type, chip.global_position, is_correct, outcome, func():
		await chip.move_to_index(0, move_speed)
		chip.chip_current_box = 0
		#_apply_score(chip, outcome) # NO _apply_score here — already applied above
	)

# =========================================================
# 🔹 MOVEMENT OUTCOME (ladder/snake)
# ---------------------------------------------------------
# Jump fires concurrently with the popup (preserving the
# original visual behavior). No post-popup callback needed.
# =========================================================
func _handle_movement_outcome(chip: Node2D, outcome: Dictionary, is_correct: bool) -> void:
	var target_index = outcome["move_to"]
	var popup_type = outcome.get("popup_type", "")

	# Fire jump concurrently — don't await
	chip.jump_to_index(target_index)

	_apply_score(chip, outcome)

	if popup_type != "":
		_show_blocking_popup(popup_type, chip.global_position, is_correct, outcome)
	else:
		_advance_turn_flow("movement_no_popup")

# =========================================================
# 🔹 VISUAL FEEDBACK OUTCOME (prize cards, etc.)
# ---------------------------------------------------------
# Apply score, show popup, turn advances when popup closes.
# =========================================================
func _handle_visual_feedback_outcome(chip: Node2D, outcome: Dictionary, is_correct: bool) -> void:
	var popup_type = outcome.get("popup_type", "")

	_apply_score(chip, outcome)

	if popup_type != "":
		_show_blocking_popup(popup_type, chip.global_position, is_correct, outcome)
	else:
		_advance_turn_flow("visual_no_popup")

# =========================================================
# 🔹 SCORE HELPER
# =========================================================
func _apply_score(chip: Node2D, outcome: Dictionary) -> void:
	if outcome.get("reset_score", false):
		chip.score = 0
	elif outcome.has("score") and not outcome.get("is_goal", false):
		chip.score = max(chip.score + outcome["score"], 0)
	EventsBus.score_updated.emit(chip.chip_owner, chip.score)

# =========================================================
# 🔹 BLOCKING POPUP — THE CORE ABSTRACTION
# ---------------------------------------------------------
# Every popup in the game goes through this function.
# It stores an optional callback (what to do AFTER the popup
# closes), sets the blocking flag, transitions to POPUP
# state, and emits the popup signal.
#
# When popup_animation_done fires, _on_popup_animation_done
# runs the callback (if any) and then advances the turn.
#
# Safety timeout prevents permanent freezes if a popup
# fails to emit popup_animation_done.
# =========================================================
func _show_blocking_popup(
	popup_type: String,
	position: Vector2,
	is_correct: bool,
	outcome: Dictionary,
	on_done: Callable = Callable()
) -> void:
	_post_popup_callback = on_done
	waiting_for_blocking_popup = true
	_change_state(GameState.POPUP)
	EventsBus.show_popup.emit(popup_type, position, is_correct, outcome)

	# Safety net: force-unblock if popup never responds
	get_tree().create_timer(POPUP_SAFETY_TIMEOUT).timeout.connect(func():
		if waiting_for_blocking_popup:
			push_warning("⚠️ Popup safety timeout fired — forcing turn advance")
			_on_popup_animation_done()
	, CONNECT_ONE_SHOT)

# =========================================================
# 🔹 POPUP ANIMATION DONE — CENTRAL TURN ADVANCE
# ---------------------------------------------------------
# This is 10 lines instead of 50. No slot-type branching.
# No magic dictionary flags. Just:
#   1. Unblock
#   2. Run the callback (if any)
#   3. Advance the turn
# =========================================================
func _on_popup_animation_done() -> void:
	if not waiting_for_blocking_popup:
		return
	waiting_for_blocking_popup = false

	if _post_popup_callback.is_valid():
		var cb = _post_popup_callback
		_post_popup_callback = Callable()
		var chip = last_slot_result.get("chip")
		if chip and not is_instance_valid(chip):
			push_warning("⚠️ Post-popup callback skipped: chip freed")
		else:
			await cb.call()
		if current_state == GameState.START_MENU:
			return

	_check_time_panels_idle()
	if pending_panel != PanelPending.NONE:
		return

	_advance_turn_flow("popup_done")

	var audio_brain := get_node_or_null("/root/AudioBrain")
	if audio_brain:
		audio_brain.play_continue_whistle()

# =========================================================
# 🔹 STATE MANAGEMENT
# ---------------------------------------------------------
# _change_state is PURE — no awaits, no side effects that
# could desync the FSM. Deferred calls handle async needs.
# =========================================================
func _change_state(new_state: int) -> void:
	current_state = new_state
	EventsBus.dice_roll_enabled.emit(new_state == GameState.AWAITING_ROLL)

	if new_state == GameState.AWAITING_ROLL:
		if is_cpu_turn():
			_auto_roll_for_cpu()
		# Deferred — not await — so _change_state returns immediately
		call_deferred("_check_time_panels_idle")

func _check_time_panels_idle():
	if waiting_for_blocking_popup or panel_shown or pending_panel == PanelPending.NONE or current_state != GameState.AWAITING_ROLL:
		return
	match pending_panel:
		PanelPending.HALFTIME:
			panel_shown = true
			pending_panel = PanelPending.NONE
			EventsBus.request_popup_sfx.emit("half_time")
			_change_state(GameState.SHOWING_HALFTIME)
			EventsBus.show_halftime.emit(emit_stats())
		PanelPending.WINNER:
			panel_shown = true
			pending_panel = PanelPending.NONE
			EventsBus.request_popup_sfx.emit("end_game")
			_change_state(GameState.SHOWING_WINNER)
			EventsBus.show_winner.emit(_get_winner_index(), emit_stats())

func _get_winner_index() -> int:
	if chips[0].score > chips[1].score:
		return 0
	if chips[1].score > chips[0].score:
		return 1
	return -1

func emit_stats() -> Dictionary:
	return {
		"winner_index": _get_winner_index(),
		"teams": [
			{"name": chips[0].team_name, "shield": chips[0].team_shield, "score": chips[0].score},
			{"name": chips[1].team_name, "shield": chips[1].team_shield, "score": chips[1].score}
		]
	}

# =========================================================
# 🎮 CPU MODE BEHAVIOR
# ---------------------------------------------------------
# _cpu_roll_pending prevents multiple coroutines from
# stacking. No while-loop — if state isn't right after the
# delay, the roll is simply discarded.
# =========================================================
func is_cpu_turn() -> bool:
	return current_turn == 1 and game_mode == "cpu"

func _auto_roll_for_cpu() -> void:
	if not is_cpu_turn() or _cpu_roll_pending:
		return
	_cpu_roll_pending = true
	await get_tree().create_timer(randf_range(0.5, 1.0)).timeout
	_cpu_roll_pending = false
	# Final safety: still CPU's turn and in the right state?
	if is_cpu_turn() and current_state == GameState.AWAITING_ROLL and not waiting_for_blocking_popup:
		if DEBUG_MODE:
			print("🧠 CPU auto-roll triggered")
		EventsBus.request_dice_roll.emit()

func _evaluate_cpu_prize_success() -> bool:
	var success = randf() <= cpu_difficulty
	if DEBUG_MODE:
		print("🎁 CPU prize roll → difficulty:", cpu_difficulty, "| success:", success)
	return success

# =========================================================
# 🔹 TEAM/COURT INITIALIZATION
# =========================================================
func _initialize_teams_and_court():
	selected_team_id_p1 = current_teams_list[0]["id"]
	if game_mode == "cpu":
		var cpu_team = TeamsDB.get_random_team_exclude(current_teams_list, selected_team_id_p1)
		selected_team_id_p2 = cpu_team["id"]
	else:
		selected_team_id_p2 = current_teams_list[1]["id"]
	EventsBus.team_shield_updated.emit(0, TeamsDB.get_team_by_id(current_teams_list, selected_team_id_p1)["shield_path"])
	EventsBus.team_shield_updated.emit(1, TeamsDB.get_team_by_id(current_teams_list, selected_team_id_p2)["shield_path"])
	selected_court = CourtsDB.get_court_by_id("stadium")

func _initialize_team_signals():
	EventsBus.team_selected.connect(_on_team_selected)
	EventsBus.court_selected.connect(func(court_data: Dictionary):
		selected_court = court_data
		board_manager._collect_slots(get_node("/root/MAIN/BoardLayout"))
	)

func _on_team_selected(player_index: int, team_id: String):
	if player_index == 0:
		selected_team_id_p1 = team_id
	else:
		selected_team_id_p2 = team_id
	var team_data = TeamsDB.get_team_by_id(current_teams_list, team_id)
	if team_data.has("shield_path"):
		EventsBus.team_shield_updated.emit(player_index, team_data["shield_path"])

func _assign_chip_team_data(teams_list: Array):
	if chips.size() < 2:
		push_error("❌ Chips not initialized before assigning team data.")
		return
	var team1 = TeamsDB.get_team_by_id(teams_list, selected_team_id_p1)
	var team2 = TeamsDB.get_team_by_id(teams_list, selected_team_id_p2)
	chips[0].team_name = team1.get("name", "Unknown")
	chips[0].team_shield = load(team1.get("shield_path", "")) if ResourceLoader.exists(team1.get("shield_path", "")) else null
	chips[1].team_name = team2.get("name", "Unknown")
	chips[1].team_shield = load(team2.get("shield_path", "")) if ResourceLoader.exists(team2.get("shield_path", "")) else null

# =========================================================
# 🔹 DEBUG HELPERS
# =========================================================
func _input(event: InputEvent) -> void:
	if not DEBUG_MODE:
		return
	if event is InputEventKey and event.pressed:
		if current_state == GameState.AWAITING_ROLL:
			match event.keycode:
				KEY_1: _force_dice_roll(1)
				KEY_2: _force_dice_roll(2)
				KEY_3: _force_dice_roll(3)
				KEY_4: _force_dice_roll(4)
				KEY_5: _force_dice_roll(5)
				KEY_6: _force_dice_roll(6)
		if event.keycode == KEY_Q: _adjust_score(0, +1)
		if event.keycode == KEY_A: _adjust_score(0, -1)
		if event.keycode == KEY_W: _adjust_score(1, +1)
		if event.keycode == KEY_S: _adjust_score(1, -1)
		if event.keycode == KEY_P:
			POPUPS_ENABLED = not POPUPS_ENABLED
			print("🔇 POPUPS_ENABLED: ", POPUPS_ENABLED)

func _process(_delta: float) -> void:
	# Debug score override removed — it fights with actual game logic.
	# Use Q/A/W/S keys to adjust scores manually instead.
	pass
		

func _is_safe_debug_state() -> bool:
	return current_state in [GameState.AWAITING_ROLL, GameState.START_MENU] and not waiting_for_blocking_popup

func _adjust_score(player_id: int, delta: int):
	chips[player_id].score += delta
	EventsBus.score_updated.emit(player_id, chips[player_id].score)
