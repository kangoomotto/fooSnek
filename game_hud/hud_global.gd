# res://game_hud/hud_global.gd
extends CanvasLayer

# =========================================================
# 🔹 NODE REFERENCES
# =========================================================
@onready var language_toggle: Button = $LanguageToggle
@onready var btn_audio: Button = $Btn_Audio
@onready var btn_pause: TextureButton = $Btn_Pause
@onready var options_panel: Control = $options_panel
@onready var btn_reset: Button = $options_panel/Center/Grid/MC1/btn_reset
@onready var btn_close: Button = $options_panel/Center/Grid/MC2/btn_close

# Localizable labels inside the pause panel
@onready var options_title: Label = $options_panel/OptionsTitle

@onready var language_manager := get_node("/root/LanguageManager")
@onready var audio_brain := get_node("/root/MAIN/AudioBrain")

signal language_changed(new_lang: String)

# =========================================================
# 🔹 READY
# =========================================================
func _ready() -> void:
	# Audio and language toggles
	btn_audio.toggled.connect(_on_audio_toggled)
	language_toggle.toggled.connect(_on_language_toggled)

	# Pause panel buttons
	btn_pause.pressed.connect(_on_btn_pause_pressed)
	btn_close.pressed.connect(_on_btn_close_pressed)
	btn_reset.pressed.connect(_on_btn_reset_pressed)

	# Start with options panel hidden
	options_panel.visible = false
	btn_pause.visible = false

	var audio_brain = get_node_or_null("/root/AudioBrain")
	if audio_brain:
		_sync_audio_button()  # only runs if audio_brain exists
		
	_sync_language_button()

	# Wire live language updates
	var hud_global_node = self  # self reference for the lambda
	hud_global_node.language_changed.connect(_update_language_ui)

	# Store base keys for localization
	options_title.set_meta("lang_key_base", "OPTIONS")
	btn_reset.set_meta("lang_key_base", "RESET")
	btn_close.set_meta("lang_key_base", "CLOSE")
	_update_language_ui(language_manager.get_language())

	# Hide pause button when not in active gameplay
	EventsBus.start_pressed.connect(func(): btn_pause.visible = true)
	EventsBus.main_menu.connect(func(): btn_pause.visible = false)
	#EventsBus.play_again_requested.connect(func(): btn_pause.visible = false)
	EventsBus.show_halftime.connect(func(_stats): btn_pause.visible = false)
	EventsBus.halftime_closed.connect(func(): btn_pause.visible = true)
	EventsBus.show_winner.connect(func(_id, _stats): btn_pause.visible = false)

# =========================================================
# 🔹 PAUSE / RESUME / RESET
# =========================================================
func _on_btn_pause_pressed() -> void:
	options_panel.visible = true
	btn_pause.visible = false
	EventsBus.pause_requested.emit()

func _on_btn_close_pressed() -> void:
	options_panel.visible = false
	btn_pause.visible = true
	EventsBus.resume_pressed.emit()

func _on_btn_reset_pressed() -> void:
	options_panel.visible = false
	btn_pause.visible = true
	EventsBus.main_menu.emit()

# =========================================================
# 🔹 AUDIO
# =========================================================
func _on_audio_toggled(enabled: bool) -> void:
	audio_brain.set_audio_enabled(enabled)

func _sync_audio_button() -> void:
	btn_audio.set_block_signals(true)
	btn_audio.button_pressed = audio_brain.audio_enabled
	btn_audio.set_block_signals(false)

# =========================================================
# 🔹 LANGUAGE
# =========================================================
func _on_language_toggled(enabled: bool) -> void:
	var lang := "en" if enabled else "es"
	language_manager.set_language(lang)
	emit_signal("language_changed", lang)

func _sync_language_button() -> void:
	language_toggle.set_block_signals(true)
	language_toggle.button_pressed = language_manager.get_language() == "en"
	language_toggle.set_block_signals(false)

# =========================================================
# 🔹 LIVE LOCALIZATION
# =========================================================
func _update_language_ui(new_lang: String) -> void:
	var translations = {
		"es": {
			"OPTIONS": "OPCIONES",
			"RESET": "REINICIAR",
			"CLOSE": "CERRAR"
		},
		"en": {
			"OPTIONS": "OPTIONS",
			"RESET": "RESET",
			"CLOSE": "CLOSE"
		}
	}

	var tr = translations.get(new_lang, {})
	for node in [options_title, btn_reset, btn_close]:
		if node.has_meta("lang_key_base"):
			var key = node.get_meta("lang_key_base")
			node.text = tr.get(key, key)
