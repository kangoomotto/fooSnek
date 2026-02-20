#res://game_hud/hud_global.gd

extends CanvasLayer

@onready var language_toggle: CheckButton = $LanguageToggle
@onready var btn_audio: CheckButton = $Btn_Audio
@onready var language_manager := get_node("/root/LanguageManager")
@onready var audio_brain := get_node("/root/MAIN/AudioBrain")

signal language_changed(new_lang: String)

func _ready() -> void:
	btn_audio.toggled.connect(_on_audio_toggled)
	language_toggle.toggled.connect(_on_language_toggled)

	_sync_audio_button()
	_sync_language_button()

func _on_audio_toggled(enabled: bool) -> void:
	audio_brain.set_audio_enabled(enabled)

func _on_language_toggled(enabled: bool) -> void:
	var lang := "en" if enabled else "es"
	language_manager.set_language(lang)
	emit_signal("language_changed", lang)  # ✅ Notify HUD panels


func _sync_audio_button() -> void:
	btn_audio.set_block_signals(true)
	btn_audio.button_pressed = audio_brain.audio_enabled
	btn_audio.set_block_signals(false)


func _sync_language_button() -> void:
	language_toggle.set_block_signals(true)
	language_toggle.button_pressed = language_manager.get_language() == "en"
	language_toggle.set_block_signals(false)
