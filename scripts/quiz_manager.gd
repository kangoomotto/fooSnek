extends Control
signal quiz_completed(correct: bool)

# =========================================================
# 🔹 STATE
# =========================================================
var current_chip: Node2D
var can_close: bool = false
var last_is_correct: bool = false

var question_data: Dictionary = {}
var slot_data: Dictionary = {}
var current_slot_type: String = ""

# 🔒 AUTHORITATIVE (ID-based correctness)
var correct_answer_id: String = ""

# =========================================================
# 🔹 NODE REFERENCES
# =========================================================
@onready var answer_buttons := [
	$Answers/Row1/Answer_1,
	$Answers/Row1/Answer_2,
	$Answers/Row2/Answer_3,
	$Answers/Row2/Answer_4
]

@onready var label_question: Label = $label_question
@onready var answer_label: Label = $answer_label
@onready var answer_image: TextureRect = $answer_image
@onready var label_slot: Label = $label_slot
@onready var label_category: Label = $label_category
@onready var slot_badge: TextureRect = $slot_badge
@onready var feedback_label: Label = $feedback_label
@onready var feedback_label2: Label = $feedback_label2
@onready var strip_category: TextureRect = $strip_category
@onready var frame_category: TextureRect = $frame_image
@onready var bg_texture: TextureRect = $bg_texture
@onready var strip_slot: TextureRect = $strip_slot

@onready var language_manager := get_node("/root/LanguageManager")

# =========================================================
# 🔹 LOCALIZATION
# =========================================================
func _localize(base_key: String, fallback_text: String = "") -> String:
	var translations = questions_db.translations_for_current_language
	if translations.has(base_key):
		return translations[base_key]
	return fallback_text if fallback_text != "" else base_key

# =========================================================
# 🔹 LIFECYCLE
# =========================================================
func _ready():
	call_deferred("_connect_language_toggle")
	EventsBus.quiz_requested.connect(_on_quiz_requested)
	start_flash_loop()

	var board_mgr = get_node_or_null("/root/BoardManager")
	if board_mgr:
		var lang_mgr = get_node("/root/LanguageManager")
		lang_mgr.language_changed.connect(func(new_lang: String):
			board_mgr._on_language_changed(new_lang)
			_update_language_ui(new_lang)
		)
	else:
		push_warning("❌ BoardManager not found — language updates will not propagate")

func _connect_language_toggle():
	var hud_global = get_node("/root/GameHud/HUD_Global")
	if hud_global:
		hud_global.language_changed.connect(_update_language_ui)
	else:
		push_warning("HUD_Global not found — check node path")

# =========================================================
# 🔹 LANGUAGE SWITCH
# =========================================================
func _update_language_ui(_lang: String = "") -> void:
	if not visible:
		return

	if label_question.has_meta("lang_key_base"):
		label_question.text = _localize(
			label_question.get_meta("lang_key_base"),
			label_question.get_meta("fallback_text", "")
		)

	if label_category.has_meta("lang_key_base"):
		label_category.text = _localize(
			label_category.get_meta("lang_key_base"),
			label_category.get_meta("fallback_text", "")
		)

	for btn in answer_buttons:
		if btn.has_meta("lang_key_base"):
			btn.text = _localize(
				btn.get_meta("lang_key_base"),
				btn.get_meta("fallback_text", "")
			)

	if answer_label.has_meta("lang_key_base"):
		answer_label.text = _localize(
			answer_label.get_meta("lang_key_base"),
			answer_label.get_meta("fallback_text", "")
		)

	if feedback_label.visible and feedback_label.has_meta("lang_key_base"):
		feedback_label.text = _localize(feedback_label.get_meta("lang_key_base"))

	if slot_data.has("label"):
		label_slot.text = slot_data["label"]
	else:
		label_slot.text = ""

# =========================================================
# 🔹 QUIZ FLOW
# =========================================================
func _on_quiz_requested(chip: Node2D, slot_info: Dictionary) -> void:
	current_chip = chip
	display_question(slot_info)
	visible = true

func display_question(slot_info: Dictionary):
	_reset_quiz_visuals()

	slot_data = slot_info
	question_data = questions_db.cached_question

	if question_data.is_empty():
		push_warning("⚠ Quiz state empty")
		return

	var question_id = question_data["id"]

	# Resolve question fresh from JSON (READ-ONLY, language-safe)
	var question := questions_db.get_question_by_id(question_id)
	if question.is_empty():
		push_error("❌ Question not found for id: " + question_id)
		return

	# -------------------------
	# Question label
	# -------------------------
	label_question.set_meta("lang_key_base", question_id)
	label_question.set_meta("fallback_text", question["question"])
	label_question.text = _localize(question_id, question["question"])

	# -------------------------
	# Category label
	# -------------------------
	label_category.set_meta("lang_key_base", question["category_label_id"])
	label_category.set_meta("fallback_text", question["category_label"])
	label_category.text = _localize(
		question["category_label_id"],
		question["category_label"]
	)

	# -------------------------
	# Answer buttons
	# -------------------------
	var shuffled_answers = question_data["shuffled_answers"]

	for i in range(answer_buttons.size()):
		var btn = answer_buttons[i]

		if i >= shuffled_answers.size():
			btn.visible = false
			btn.disabled = true
			continue

		var ans = shuffled_answers[i]

		btn.visible = true
		btn.disabled = false
		btn.set_meta("lang_key_base", ans["id"])
		btn.set_meta("fallback_text", ans["text"])
		btn.text = _localize(ans["id"], ans["text"])

		for conn in btn.get_signal_connection_list("pressed"):
			btn.disconnect("pressed", conn["callable"])

		var idx := i
		btn.pressed.connect(func():
			_on_answer_selected(idx)
		)

	# -------------------------
	# Correct answer label
	# -------------------------
	correct_answer_id = question_data["correct_answer_id"]

	for ans in shuffled_answers:
		if ans["id"] == correct_answer_id:
			answer_label.set_meta("lang_key_base", ans["id"])
			answer_label.set_meta("fallback_text", ans["text"])
			answer_label.text = _localize(ans["id"], ans["text"])
			break

	feedback_label.visible = false
	_load_question_visuals(question, slot_data)
	_update_language_ui()

# =========================================================
# 🔹 VISUAL LOADING
# =========================================================
func _load_question_visuals(question_data: Dictionary, slot_data: Dictionary):
	var answer_path = question_data.get("answer_image", "")
	answer_image.texture = (
		load(answer_path)
		if ResourceLoader.exists(answer_path)
		else preload("res://game_assets/images/defaults/default_answer.png")
	)
	answer_image.visible = true

	frame_category.texture = preload("res://game_assets/images/defaults/default_frame.png")

	label_slot.text = slot_data.get(
		"label",
		slot_data.get("type", "GENERIC").capitalize()
	)

	var image_pool = slot_data.get("image_pool", [])
	slot_badge.texture = (
		load(image_pool[0])
		if image_pool.size() > 0 and ResourceLoader.exists(image_pool[0])
		else preload("res://game_assets/images/defaults/default_slot.png")
	)

# =========================================================
# 🔹 ANSWER SELECTION & FEEDBACK
# =========================================================
func _on_answer_selected(index: int):
	var chosen = question_data["shuffled_answers"][index]
	last_is_correct = chosen["id"] == correct_answer_id
	show_feedback(last_is_correct)
	can_close = true

func show_feedback(correct: bool) -> void:
	EventsBus.request_popup_sfx.emit("correct" if correct else "incorrect")

	$Answers.visible = false
	label_question.visible = false
	feedback_label.visible = true
	answer_label.visible = true
	answer_image.visible = true

	feedback_label.set_meta("lang_key_base", "Correct!" if correct else "Incorrect!")
	feedback_label.text = _localize(feedback_label.get_meta("lang_key_base"))

	var chosen_path: String = question_data.get("answer_image", "")
	if not correct and slot_data.has("image_pool"):
		for p in slot_data["image_pool"]:
			if p.findn("miss") >= 0:
				chosen_path = p
				break

	answer_image.texture = (
		load(chosen_path)
		if ResourceLoader.exists(chosen_path)
		else preload("res://game_assets/images/defaults/default_answer.png")
	)

# =========================================================
# 🔹 CLOSE QUIZ
# =========================================================
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and can_close:
		if not last_is_correct:
			EventsBus.request_popup_sfx.emit("boo")

		questions_db.preload_next_question()

		if current_chip:
			EventsBus.quiz_completed.emit(current_chip, last_is_correct)

		visible = false

# =========================================================
# 🔹 RESET VISUALS
# =========================================================
func _reset_quiz_visuals():
	$Answers.visible = true
	label_question.visible = true
	feedback_label.visible = false
	answer_label.visible = false
	answer_image.visible = false
	answer_image.modulate = Color(1, 1, 1)
	can_close = false
	last_is_correct = false

# =========================================================
# 🔹 BUTTON FLASH
# =========================================================
func start_flash_loop():
	await get_tree().create_timer(4.0).timeout
	while true:
		flash_buttons()
		await get_tree().create_timer(4.0).timeout

func flash_buttons():
	for button in answer_buttons:
		var original = button.modulate
		var tween = create_tween()
		tween.tween_property(button, "modulate", Color(2, 2, 2, 1.0), 0.2)
		tween.tween_property(button, "modulate", original, 0.5)
