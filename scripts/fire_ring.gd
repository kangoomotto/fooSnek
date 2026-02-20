extends Node2D

@export var rotation_speed := 2.0
var active := false

func set_active(active: bool) -> void:
	visible = active
	if not visible:
		return

	var mat = $RingSprite.material
	if mat:
		mat.set_shader_parameter("runtime_speed_boost", 2.0)

func _process(delta: float) -> void:
	if not active:
		return
	rotation += rotation_speed * delta
