#res://game_hud/hud_menu.gd

extends Control

# =========================================================
# 🔹 SIGNALS
# =========================================================
signal start_game_pressed(mode: String, league: String, team_p1: Dictionary, team_p2: Dictionary)

# =========================================================
# 🔹 NODE REFERENCES
# =========================================================
@onready var grid: GridContainer = $ScrollContainer/MarginContainer/Grid
@onready var menu_title: Label = $MenuTitle
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var button_scene: PackedScene = preload("res://game_hud/scenes/menu_button.tscn")
@onready var action_bar: Control = $ActionBar
@onready var action_button: Button = $ActionBar/ContinueButton

# =========================================================
# 🔹 MENU STATE
# =========================================================
enum MenuStep { MAIN, MODE, LEAGUE, TEAMS }
var current_step: MenuStep = MenuStep.MAIN
var selecting_player_index: int = 0

# =========================================================
# 🔹 USER SELECTION DATA
# =========================================================
var selected_mode: String = ""
var selected_league: String = ""
var selected_team_p1: Dictionary = {}
var selected_team_p2: Dictionary = {}

# =========================================================
# 🔹 LIFECYCLE
# =========================================================
func _ready():
	# Escucha cambios de jugador
	EventsBus.selecting_player_changed.connect(func(index):
		selecting_player_index = index
	)

	# Conecta toggle global de idioma
	var hud_global_node = get_node("/root/GameHud/HUD_Global")
	if hud_global_node:
		hud_global_node.language_changed.connect(_update_language_ui)

	# Always show the main menu. The debug logic is handled on button press.
	_show_main_menu()

	# Inicializa idioma
	_update_language_ui(LanguageManager.get_language())

# =========================================================
# 🔹 ACTION BUTTON (CENTRALIZADO)
# =========================================================
func _configure_action_button(base_key: String, enabled: bool, callback: Callable):
	action_bar.visible = true
	action_button.disabled = not enabled

	# Desconecta conexiones anteriores
	for c in action_button.pressed.get_connections():
		action_button.pressed.disconnect(c.callable)

	action_button.pressed.connect(callback)

	# Guardar la clave base para traducción
	action_button.set_meta("lang_key_base", base_key)
	action_button.text = _localize(base_key)

# =========================================================
# 🔹 BOTONES DEL GRID
# =========================================================
func _create_buttons(labels: Array, callbacks: Array, teams_data: Array = []):
	_clear_buttons()

	for i in range(labels.size()):
		var btn: Button = button_scene.instantiate() as Button
		var base_key = str(labels[i])  # siempre clave en inglés
		btn.set_meta("lang_key_base", base_key)
		btn.text = _localize(base_key)

		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.custom_minimum_size = Vector2(600, 250) if current_step == MenuStep.TEAMS else Vector2(600, 200)

		# Icono del equipo
		if btn.has_node("shield_icon"):
			if current_step == MenuStep.TEAMS and i < teams_data.size():
				var team = teams_data[i]
				if team.has("shield_path") and ResourceLoader.exists(team["shield_path"]):
					btn.get_node("shield_icon").texture = load(team["shield_path"])
					btn.get_node("shield_icon").visible = true
				else:
					btn.get_node("shield_icon").visible = false
			else:
				btn.get_node("shield_icon").visible = false

		btn.pressed.connect(callbacks[i])
		grid.add_child(btn)

func _clear_buttons():
	for child in grid.get_children():
		child.queue_free()

# =========================================================
# 🔹 ACTUALIZACIÓN DE IDIOMA
# =========================================================
func _update_language_ui(new_lang: String) -> void:
	# Título
	if menu_title.has_meta("lang_key_base"):
		menu_title.text = _localize(menu_title.get_meta("lang_key_base"))

	# Botón de acción
	if action_button.has_meta("lang_key_base"):
		action_button.text = _localize(action_button.get_meta("lang_key_base"))

	# Botones del grid
	for btn in grid.get_children():
		if btn.has_meta("lang_key_base"):
			btn.text = _localize(btn.get_meta("lang_key_base"))

# =========================================================
# 🔹 FLUJO DE MENÚ
# =========================================================
func _show_main_menu():
	current_step = MenuStep.MAIN
	_update_scroll_state()
	action_bar.visible = false

	# Configura título
	menu_title.set_meta("lang_key_base", "MAIN MENU")
	menu_title.text = _localize("MAIN MENU")

	# Crea botones
	_create_buttons(
		["START", "EXIT"],
		[
			_handle_start_press,  # This single function handles everything
			func(): get_tree().quit()
		]
	)

# =========================================================
# 🔹 START BUTTON HANDLER
# ---------------------------------------------------------
# Checks the debug flag and either starts instantly or
# proceeds to the mode selection menu.
# =========================================================
func _handle_start_press():
	var game_manager = get_node("/root/MAIN/GameManager")
	if game_manager.DEBUG_SKIP_MENUS:
		_debug_start_instant()
	else:
		_show_mode_menu()

# =========================================================
# 🔹 DEBUG: INSTANT START
# ---------------------------------------------------------
# Sets all default values and starts the game immediately,
# bypassing all intermediate menus.
# =========================================================
func _debug_start_instant():
	print("🚀 [DEBUG] Starting game with instant defaults.")
	
	# Set default selections
	selected_mode = "cpu"
	selected_league = "liga_mx"
	var teams_list = TeamsDB.get_teams_by_league(selected_league)
	if teams_list.is_empty():
		print("ERROR: No teams found for league 'liga_mx'. Cannot start debug game.")
		return
	selected_team_p1 = teams_list[0] # First team in the list
	selected_team_p2 = TeamsDB.get_random_team_exclude(teams_list, selected_team_p1["id"])

	# Emit signals as if the user selected everything normally
	EventsBus.game_mode_selected.emit(selected_mode)
	EventsBus.team_shield_updated.emit(0, selected_team_p1["shield_path"])
	EventsBus.team_shield_updated.emit(1, selected_team_p2["shield_path"])

	# Hide the menu and start the game
	visible = false
	emit_signal("start_game_pressed", selected_mode, selected_league, selected_team_p1, selected_team_p2)
	EventsBus.start_pressed.emit()

# --- NORMAL MENU FLOW (UNCHANGED) ---
func _show_mode_menu():
	current_step = MenuStep.MODE
	_update_scroll_state()
	menu_title.set_meta("lang_key_base", "SELECT MODE")
	menu_title.text = _localize("SELECT MODE")

	_create_buttons(
		["SINGLE PLAYER", "2 PLAYERS"],
		[func(): _select_mode("cpu"), func(): _select_mode("pvp")]
	)

	_configure_action_button("CONTINUE", selected_mode != "", Callable(self, "_on_mode_continue"))

func _select_mode(mode: String):
	selected_mode = mode
	EventsBus.game_mode_selected.emit(mode)
	_configure_action_button("CONTINUE", selected_mode != "", Callable(self, "_on_mode_continue"))

func _on_mode_continue():
	_show_league_menu()

func _show_league_menu():
	current_step = MenuStep.LEAGUE
	_update_scroll_state()
	menu_title.set_meta("lang_key_base", "SELECT LEAGUE")
	menu_title.text = _localize("SELECT LEAGUE")

	var league_ids = TeamsDB.leagues.keys()
	var labels: Array = []
	var callbacks: Array = []

	for l in league_ids:
		labels.append(l.capitalize().replace("_", " "))
		callbacks.append(Callable(self, "_select_league").bind(l))

	_create_buttons(labels, callbacks)
	_configure_action_button("CONTINUE", selected_league != "", Callable(self, "_on_league_continue"))

func _select_league(league: String):
	selected_league = league
	_configure_action_button("CONTINUE", selected_league != "", Callable(self, "_on_league_continue"))

func _on_league_continue():
	_show_teams_menu()

func _show_teams_menu():
	current_step = MenuStep.TEAMS
	EventsBus.show_score_requested.emit()
	_update_scroll_state()
	menu_title.set_meta("lang_key_base", "SELECT TEAMS")
	menu_title.text = _localize("SELECT TEAMS")

	selected_team_p1 = {}
	selected_team_p2 = {}

	var teams_list: Array = TeamsDB.get_teams_by_league(selected_league)
	var labels: Array = []
	var callbacks: Array = []

	for team in teams_list:
		labels.append(team["name"])
		callbacks.append(Callable(self, "_select_team").bind(team))

	_create_buttons(labels, callbacks, teams_list)
	_configure_action_button("PLAY", false, Callable(self, "_on_play_pressed"))

func _select_team(team_data: Dictionary):
	if current_step != MenuStep.TEAMS:
		return

	if selected_mode == "cpu":
		selected_team_p1 = team_data
		var teams_list = TeamsDB.get_teams_by_league(selected_league)
		selected_team_p2 = TeamsDB.get_random_team_exclude(teams_list, team_data["id"])
	else:
		if selecting_player_index == 0:
			selected_team_p1 = team_data
		else:
			selected_team_p2 = team_data

	if not selected_team_p1.is_empty():
		EventsBus.team_shield_updated.emit(0, selected_team_p1["shield_path"])
	if not selected_team_p2.is_empty():
		EventsBus.team_shield_updated.emit(1, selected_team_p2["shield_path"])

	_configure_action_button("PLAY", not selected_team_p1.is_empty() and not selected_team_p2.is_empty(), Callable(self, "_on_play_pressed"))

func _on_play_pressed():
	visible = false
	emit_signal("start_game_pressed", selected_mode, selected_league, selected_team_p1, selected_team_p2)
	EventsBus.start_pressed.emit()
# --- END NORMAL MENU FLOW ---

# =========================================================
# 🔹 SCROLL
# =========================================================
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and current_step != MenuStep.TEAMS:
			get_viewport().set_input_as_handled()

func _update_scroll_state():
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if current_step == MenuStep.TEAMS else ScrollContainer.SCROLL_MODE_DISABLED
	if current_step != MenuStep.TEAMS:
		scroll_container.scroll_vertical = 0

# =========================================================
# 🔹 LOCALIZACIÓN
# =========================================================
func _localize(text: String) -> String:
	var translations = {
		"es": {
			"MAIN MENU": "MENÚ PRINCIPAL",
			"START": "INICIAR",
			"EXIT": "SALIR",
			"SELECT MODE": "SELECCIONAR MODO",
			"SINGLE PLAYER": "UN JUGADOR",
			"2 PLAYERS": "2 JUGADORES",
			"CONTINUE": "CONTINUAR",
			"SELECT LEAGUE": "SELECCIONAR LIGA",
			"Liga mx": "Liga MX",
			"World cup": "Copa Mundial",
			"SELECT TEAMS": "SELECCIONAR EQUIPOS",
			"PLAY": "JUGAR"
		},
		"en": {
			"MAIN MENU": "MAIN MENU",
			"START": "START",
			"EXIT": "EXIT",
			"SELECT MODE": "SELECT MODE",
			"SINGLE PLAYER": "SINGLE PLAYER",
			"2 PLAYERS": "2 PLAYERS",
			"CONTINUE": "CONTINUE",
			"SELECT LEAGUE": "SELECT LEAGUE",
			"Liga mx": "Liga MX",
			"World cup": "World cup",
			"SELECT TEAMS": "SELECT TEAMS",
			"PLAY": "PLAY"
		}
	}
	return str(translations.get(LanguageManager.get_language(), {}).get(text, text))
