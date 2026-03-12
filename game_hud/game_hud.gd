# game_hud.gd
# Create canvas for game_hud.gd”
extends CanvasLayer

signal shield_clicked(player_index: int)

@onready var hud_menu: Control = $HUD_Menu
@onready var hud_quiz: Control = $HUD_Quiz
@onready var hud_score: Control = $HUD_Score
@onready var popup_layer: Node = %PopupLayer

@onready var hud_winner: Control = $HUD_Winner
@onready var hud_halftime: Control = $HUD_Halftime
@onready var hud_timer: Node = $HUD_Score/HBoxContainer/HUD_Timer
@onready var hud_global: CanvasLayer = $HUD_Global

func _ready():
	visible = true
	_start_hud_state()

	# Connect global buttons to HUD events
	if hud_global:
		hud_global.language_changed.connect(func(new_lang: String):
			# Update all HUD panels that support language
			if hud_menu:
				hud_menu._update_language_ui(new_lang)
			if hud_quiz and hud_quiz.has_method("_update_language_ui"):
				hud_quiz._update_language_ui(new_lang)
			if hud_halftime and hud_halftime.has_method("_update_language_ui"):
				hud_halftime._update_language_ui(new_lang)
			if hud_winner and hud_winner.has_method("_update_language_ui"):
				hud_winner._update_language_ui(new_lang)
		)

		# Immediately sync toggle to current language
		var current_lang = hud_global.language_manager.get_language()
		if hud_menu:
			hud_menu._update_language_ui(current_lang)
		if hud_quiz and hud_quiz.has_method("_update_language_ui"):
			hud_quiz._update_language_ui(current_lang)
		if hud_halftime and hud_halftime.has_method("_update_language_ui"):
			hud_halftime._update_language_ui(current_lang)
		if hud_winner and hud_winner.has_method("_update_language_ui"):
			hud_winner._update_language_ui(current_lang)

	# Connect HUD events
	EventsBus.start_pressed.connect(_on_start_pressed)
	EventsBus.popup_ready.connect(_on_popup_ready)
	EventsBus.show_winner.connect(_on_show_winner)
	EventsBus.show_halftime.connect(_on_show_halftime)
	EventsBus.hud_reset_requested.connect(_start_hud_state)

	# Halftime continue button
	if hud_halftime and hud_halftime.has_node("continue_button"):
		hud_halftime.continue_button.pressed.connect(_on_halftime_continue)
		
		# Connect menu's team selections to game_manager
	if hud_menu:
		hud_menu.start_game_pressed.connect(_on_start_game_pressed)
		
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	if $HUD_Menu:
		$HUD_Menu.process_mode = Node.PROCESS_MODE_ALWAYS

	# Score panel visibility
	EventsBus.show_score_requested.connect(func():
		if hud_score:
			hud_score.visible = true
	)
	

func _on_start_game_pressed(mode: String, league: String, team_p1: Dictionary, team_p2: Dictionary) -> void:
	var gm = get_node_or_null("/root/MAIN/GameManager")
	if gm:
		gm.selected_team_id_p1 = team_p1.get("id", "")
		gm.selected_team_id_p2 = team_p2.get("id", "")
		gm.current_teams_list = TeamsDB.get_teams_by_league(league)
		
func _start_hud_state():
	_reset_panels()
	hud_menu.reset_to_main()
	hud_menu.visible = true  # start menu always on reset
	hud_score.visible = false 
	
func _reset_panels():
	hud_score.visible = true
	hud_menu.visible = false
	hud_quiz.visible = false
	hud_winner.visible = false
	hud_halftime.visible = false
	hud_global.visible = true  # ensure global buttons hidden during menu
	hud_timer.reset_timer()

func _on_start_pressed():
	EventsBus.request_ui_click_sfx.emit("start_game") # 🔊
	hud_menu.visible = false
	hud_score.visible = true
	hud_global.visible = true  # ✅ show global buttons only during gameplay
	
	
func _on_show_winner(winner_id: int, stats: Dictionary) -> void:
	if hud_winner:
		hud_winner.show_panel(winner_id, stats)

func _on_show_halftime(stats: Dictionary) -> void:
	EventsBus.request_ui_click_sfx.emit("half_time") # 🔊
	hud_global.visible = true
	if hud_halftime:
		hud_halftime.show_panel(stats)

func _on_halftime_continue():
	hud_global.visible = true
	EventsBus.request_ui_click_sfx.emit("continue") # 🔊

	hud_halftime.visible = false
	EventsBus.resume_timer.emit()
	EventsBus.halftime_closed.emit()


func _on_popup_ready(popup: Node) -> void:
	if popup_layer:
		popup_layer.add_child(popup)
		# print("🟢 Popup added to HUD layer")
	else:
		push_warning("⚠ PopupLayer missing in GameHud")
