extends Node
# res://scripts/questions_db.gd

var questions_by_category: Dictionary = {}
var remaining_questions: Dictionary = {}
var cached_question: Dictionary = {}
var _current_language: String = ""

var translations_for_current_language: Dictionary = {}

func _ready():
	LanguageManager.language_changed.connect(_on_language_changed)
	_load_questions_for_current_language()
	reset_remaining_pools()
	preload_next_question()

# =========================================================
# 🔹 LANGUAGE
# =========================================================
func _on_language_changed(lang: String) -> void:
	if lang == _current_language:
		return
	_load_questions_for_current_language()
	# ❌ NO rebinding

# =========================================================
# 🔹 LOAD QUESTIONS
# =========================================================
func _load_questions_for_current_language() -> void:
	_current_language = LanguageManager.get_language()
	var path := "res://data/quiz_%s.json" % _current_language

	if not FileAccess.file_exists(path):
		push_error("❌ Missing quiz file: " + path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("❌ Invalid quiz JSON")
		return

	var validated := {}

	for category_id in parsed.keys():
		validated[category_id] = []

		for q in parsed[category_id]:
			if not q.has("id") or not q.has("question") or q.get("answers", []).size() < 4:
				continue

			# 🔹 AUTHORITATIVE RUNTIME QUESTION ID
			var runtime_id := "%s_%s" % [category_id, q["id"]]

			q["runtime_id"] = runtime_id
			q["category_id"] = category_id
			q["category_label_id"] = q.get("category_label_id", category_id + "_LABEL")
			q["category_label"] = q.get("category_label", category_id.capitalize())

			validated[category_id].append(q)

	questions_by_category = validated
	_update_translations_cache()

# =========================================================
# 🔹 TRANSLATIONS CACHE
# =========================================================
func _update_translations_cache():
	translations_for_current_language.clear()

	for category in questions_by_category.keys():
		for q in questions_by_category[category]:
			var qid = q["runtime_id"]

			translations_for_current_language[qid] = q["question"]
			translations_for_current_language[q["category_label_id"]] = q["category_label"]

			for i in range(q["answers"].size()):
				var aid := "%s_ANS_%d" % [qid, i]
				translations_for_current_language[aid] = q["answers"][i]

	var lang = LanguageManager.get_language()
	translations_for_current_language["Correct!"] = {"es":"¡Correcto!","en":"Correct!"}.get(lang, "Correct!")
	translations_for_current_language["Incorrect!"] = {"es":"¡Incorrecto!","en":"Incorrect!"}.get(lang, "Incorrect!")

# =========================================================
# 🔹 POOLS
# =========================================================
func reset_remaining_pools():
	remaining_questions.clear()
	for cat in questions_by_category.keys():
		remaining_questions[cat] = questions_by_category[cat].duplicate(true)

# =========================================================
# 🔹 PRELOAD QUESTION
# =========================================================
# =========================================================
# 🔹 PRELOAD QUESTION (FINAL / SAFE)
# =========================================================
func preload_next_question():
	var categories = remaining_questions.keys()
	if categories.is_empty():
		cached_question = {}
		return

	var category_id = categories.pick_random()
	var pool = remaining_questions[category_id]

	if pool.is_empty():
		remaining_questions[category_id] = questions_by_category[category_id].duplicate(true)
		pool = remaining_questions[category_id]

	var q = pool.pop_at(randi() % pool.size())

	var runtime_id: String = q["runtime_id"]
	var answers: Array = q["answers"]

	# ---------------------------------------------------------
	# DATA CONTRACT
	# answers[0] is ALWAYS the correct answer
	# ---------------------------------------------------------
	if answers.size() < 4:
		push_error("Question '%s' has fewer than 4 answers" % runtime_id)
		cached_question = {}
		return

	var correct_answer_index := 0

	# ---------------------------------------------------------
	# Build WRONG answers pool (exclude index 0)
	# ---------------------------------------------------------
	var wrong_indices: Array[int] = []
	for i in range(1, answers.size()):
		wrong_indices.append(i)

	wrong_indices.shuffle()

	# ---------------------------------------------------------
	# Select exactly 3 wrong answers + correct one
	# ---------------------------------------------------------
	var selected_indices: Array[int] = [correct_answer_index]
	selected_indices.append_array(wrong_indices.slice(0, 3))

	# Shuffle for UI display only
	selected_indices.shuffle()

	# ---------------------------------------------------------
	# Build shuffled answers with STABLE IDS
	# ---------------------------------------------------------
	var shuffled: Array = []
	for idx in selected_indices:
		var aid := "%s_ANS_%d" % [runtime_id, idx]
		shuffled.append({
			"id": aid,
			"text": answers[idx]
		})

	# ---------------------------------------------------------
	# Cache runtime question
	# ---------------------------------------------------------
	cached_question = {
		"id": runtime_id,
		"category_id": category_id,
		"category_label_id": q["category_label_id"],
		"category_label": q["category_label"],
		"question": q["question"],
		"shuffled_answers": shuffled,
		"correct_answer_id": "%s_ANS_%d" % [runtime_id, correct_answer_index]
	}

# =========================================================
# 🔹 LOOKUP
# =========================================================
func get_question_by_id(runtime_id: String) -> Dictionary:
	for category in questions_by_category.values():
		for q in category:
			if q.get("runtime_id") == runtime_id:
				return q.duplicate(true)
	return {}
