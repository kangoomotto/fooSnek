extends Node

signal language_changed(language_code: String)

var _current_language: String = "es"

func get_language() -> String:
	return _current_language

func set_language(language_code: String) -> void:
	#print("  🔹 Current language:", LanguageManager.get_language())
	if _current_language == language_code:
		return
	_current_language = language_code
	language_changed.emit(_current_language)
