extends RigidBody3D

enum DiceState { IDLE, ROLLING, SETTLING, REPORTED }
var state: DiceState = DiceState.IDLE

signal roll_finished(value: int)

var raycasts: Array[RayCast3D] = []
var start_position: Vector3
var settle_timer := 0.0
const SETTLE_DURATION := 0.2
var result_locked := false
var can_click := true

@export var roll_strength := 250.0

func _ready() -> void:
	start_position = global_position
	if has_node("RayCasts"):
		for child in $RayCasts.get_children():
			if child is RayCast3D:
				raycasts.append(child)

func roll() -> void:
	if not can_click or state != DiceState.IDLE:
		return
	state = DiceState.ROLLING
	result_locked = false
	can_click = false
	sleeping = false
	freeze = false
	transform.origin = start_position + Vector3(randf_range(-0.3, 0.3), 5, randf_range(-0.3, 0.3))
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	var throw_vector = Vector3(randf_range(-5, 5), 5, randf_range(-15, 15)).normalized() * randf_range(roll_strength * 1.5, roll_strength * 2.5)
	apply_impulse(Vector3.ZERO, throw_vector)
	angular_velocity = Vector3(randf_range(-10, 10), randf_range(-20, 20), randf_range(-25, 50))

func _physics_process(delta: float) -> void:
	if state == DiceState.ROLLING:
		if linear_velocity.length() < 0.05 and angular_velocity.length() < 0.05:
			settle_timer += delta
			if settle_timer >= SETTLE_DURATION:
				_process_roll_result()
		else:
			settle_timer = 0.0

func _process_roll_result() -> void:
	if result_locked:
		return
	result_locked = true
	var value := 1
	for ray in raycasts:
		if ray.is_colliding():
			value = ray.opposite_side
			break
	roll_finished.emit(value)
	state = DiceState.IDLE
	can_click = true
	settle_timer = 0.0
