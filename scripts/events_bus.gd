extends Node
#class_name EventsBus
# In EventsBus.gd

signal popup_settings(enabled: bool, categories: Dictionary)
signal popup_visual_feedback(settings: Dictionary)

# Dice
signal dice_roll_requested()
signal dice_roll_finished(chip: Node2D, roll_value: int)

# Player Movement
signal player_move_requested(player_id: int, steps: int)
signal player_move_started(player_id: int)
signal player_move_finished(player_id: int)

# In EventsBus.gd, add this line with the other signals
signal debug_skip_menus_enabled()

# Game Flow
signal turn_started(player_id: int)
signal turn_ended(player_id: int)
signal quiz_requested(chip: Node2D, slot_data: Dictionary)
signal quiz_answered(is_correct: bool)
signal game_ended(winner_id: int) # Or 0 for a draw

# UI
signal hud_show_panel(panel_name: String) # e.g., "Quiz", "Menu", "Winner"
signal hud_update_scores(player1_score: int, player2_score: int)

# Audio
signal sfx_play_requested(sound_name: String)

# =========================================================
# 🔹 CORE FLOW
# =========================================================
signal start_pressed
signal request_dice_roll
signal dice_roll_started
signal dice_rolled(value: int)
signal dice_roll_enabled(enabled: bool)

signal game_paused
signal game_resumed
signal game_reset
signal board_ready
signal show_score_requested

# =========================================================
# 🔹 POPUPS
# =========================================================
signal show_popup(slot_type: String, position: Vector2, is_correct: bool, outcome: Dictionary)
signal popup_ready(popup: Node)	# ✅ now declared
signal popup_animation_done

# =========================================================
# 🔹 QUIZ
# =========================================================
signal quiz_completed(chip: Node2D, correct: bool)
# =========================================================
# 🔹 MATCH FLOW
# =========================================================
signal halftime_reached
signal halftime_closed
signal match_ended
signal play_again_requested
signal winner_declared(winner_id: int, stats: Dictionary)
signal main_menu
signal hud_reset_requested

# =========================================================
# 🔹 TEAMS & COURTS
# =========================================================
signal team_selected(player_index: int, team_id: String)
signal team_shield_updated(player_index: int, shield_path: String)
signal selecting_player_changed(player_index: int)
signal request_team_menu(player_index: int)

signal court_selected(court_data: Dictionary)
signal game_mode_selected(mode_id: String)

signal cpu_team_assigned(cpu_team: Dictionary)

# =========================================================
# 🔹 SCORE
# =========================================================
signal score_updated(player_id: int, new_score: int)
signal goal_scored(player_index: int)

# =========================================================
# 🔹 TIMER
# =========================================================
signal start_timer
signal pause_timer
signal resume_timer
signal timer_tick(minutes: int, seconds: int)
signal show_halftime(stats: Dictionary)
signal show_winner(winner_id: int, stats: Dictionary)

signal pause_requested
signal resume_pressed

# =========================================================
# 🔹 TURN
# =========================================================
signal turn_updated(current_turn: int)
signal grant_extra_turn(extra: bool)
signal active_player_highlight_changed(player_index: int)


signal overshoot_started(chip: Node2D, overshoot_data: Dictionary)
# =========================================================
# 🔹 MOVEMENT
# =========================================================
# Emitted by the Chip script when it finishes moving to a new index.
# This is the primary trigger for resolving the outcome of a landed slot.
signal chip_move_finished(player_id: int, final_index: int)

# =========================================================
# 🔊 AUDIO BUS SIGNALS
# =========================================================
# General-purpose sound effect and music signals.
# AudioBus.gd listens for these and plays corresponding files.
signal request_popup_sfx(slot_type: String)
signal request_dice_roll_sfx
signal request_dice_impact_sfx
signal request_ui_click_sfx(action_name: String)
signal request_commentary(context: Dictionary)
signal match_started
