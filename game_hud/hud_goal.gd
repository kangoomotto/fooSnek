extends TextureRect

signal animation_finished


func show_popup(player_id: int) -> void:
	visible = true

	# Reset particles
	$GoalParticles.emitting = false
	await get_tree().process_frame
	$GoalParticles.restart()
	$GoalParticles.emitting = true

	# Reset visuals
	modulate.a = 1.0
	position = Vector2((get_viewport_rect().size.x - size.x) / 2, 200)

	# Animate popup
	var tween := create_tween()
	tween.parallel().tween_property(self, "position:y", position.y + 500, 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1).set_delay(1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(self, "_on_fade_complete"))

func _on_fade_complete():
	visible = false
	animation_finished.emit()
	EventsBus.goal_animation_done.emit()

	
	# ✅ Notify GameHud (architecture safe)
	if get_parent().has_signal("goal_animation_done"):
		get_parent().goal_animation_done.emit()
