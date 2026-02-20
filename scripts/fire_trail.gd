extends Node2D

@export var max_points: int = 500
@onready var line: Line2D = $TrailLine
@onready var chip: Node2D = get_parent()
@export var noise_strength := 10.0
@export var noise_speed := 30.0
var time := 0.0
var active := false

func _ready() -> void:
	line.set_as_top_level(true)
	line.clear_points()
	

func start() -> void:
	active = true
	line.clear_points()

func stop() -> void:
	active = false
	line.clear_points()

func _process(delta: float) -> void:
	if not active:
		return
	time += delta * noise_speed
	var base_pos := line.to_local(chip.global_position)
	var noise_offset := Vector2(
		sin(time),
		cos(time * 1.3)
	) * noise_strength
	line.add_point(base_pos + noise_offset)
	if line.get_point_count() > max_points:
		line.remove_point(0)
