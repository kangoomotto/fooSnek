extends RigidBody3D

enum DiceState { IDLE, ROLLING, SETTLING, REPORTED }
var state: DiceState = DiceState.IDLE

signal roll_finished(value: int)

var raycasts: Array[RayCast3D] = []
var start_position: Vector3
var settle_timer  := 0.0
const SETTLE_DURATION := 0.2
var result_locked := false
var can_click     := true   # read by dice_box to block input while charging

# ══════════════════════════════════════════════════════════
# 🎲 CHARGE ANIMATION PARAMETERS
# Tweak these to change how the dice behaves while charging
# ══════════════════════════════════════════════════════════

# ── Vertical float (Y axis, camera approach) ──────────────
# How high above start_position the dice floats at full charge (meters)
# Higher = more dramatic "rising toward camera" feel
const CHARGE_FLOAT_HEIGHT   := 2.0

# How much the Y position bobs up/down randomly while charging
# Higher = more unstable, nervous energy
const CHARGE_FLOAT_WOBBLE   := 0.6

# Speed of the Y bobbing noise. Higher = faster jitter
const CHARGE_FLOAT_SPEED    := 2.8

# ── Slow rotation while charging ─────────────────────────
# Base rotation speed on each axis (radians/sec) at full charge.
# Increase to spin faster. Set an axis to 0 to lock it.
const CHARGE_ROT_X          := 0.30   # forward/back tumble
const CHARGE_ROT_Y          := 0.50   # horizontal spin (most visible)
const CHARGE_ROT_Z          := 0.20   # side roll

# How much random noise modulates the rotation speed (0 = steady, 1 = very erratic)
const CHARGE_ROT_NOISE      := 0.55

# Speed of the rotation noise oscillation. Higher = jerkier spin
const CHARGE_ROT_NOISE_SPEED := 3.5

# ── Return-to-rest smoothing ──────────────────────────────
# How fast the dice lerps back to start_position after release (0–1 per frame).
# Lower = smoother landing; higher = snappier snap-back before physics takes over.
# Not actually used after release — physics takes over immediately.
# (kept here for future tween use)
# const CHARGE_RETURN_SPEED := 12.0

# ══════════════════════════════════════════════════════════
# 🚀 ROLL PHYSICS PARAMETERS
# ══════════════════════════════════════════════════════════

# Power multiplier at minimum charge (tap). 1.0 = base roll_strength
const POWER_MIN     := 0.55   # tap rolls gently
const POWER_MAX     := 1.60   # full charge rolls hard and wild

# How far from center the dice spawns horizontally (meters).
# Full charge adds more scatter for a wilder, less controlled throw.
const SCATTER_MIN   := 0.2    # tap: lands close to center
const SCATTER_MAX   := 0.6    # full charge: more random starting X/Z

# Horizontal spread of the throw vector. More spread = dice bounces sideways.
const H_SPREAD_MIN  := 3.0
const H_SPREAD_MAX  := 8.0

# Vertical/forward spread of the throw vector. More = dice travels farther.
const V_SPREAD_MIN  := 8.0
const V_SPREAD_MAX  := 18.0

# Angular velocity (spin) scale. Higher = dice tumbles more after launch.
const ANG_SCALE_MIN := 0.6    # tap: lazy spin
const ANG_SCALE_MAX := 2.0    # full charge: wild tumble

@export var roll_strength := 250.0   # base impulse magnitude — adjust in Inspector

# ══════════════════════════════════════════════════════════
# INTERNAL STATE
# ══════════════════════════════════════════════════════════
var _shader_materials: Array[ShaderMaterial] = []
var _charge_level:     float = 0.0   # 0–1, driven by dice_box
var _charge_time:      float = 0.0   # raw elapsed seconds, for noise sampling

# ─────────────────────────────────────────────────────────
func _ready() -> void:
	start_position = global_position
	if has_node("RayCasts"):
		for child in $RayCasts.get_children():
			if child is RayCast3D:
				raycasts.append(child)
	_init_shader()

func _init_shader() -> void:
	var mesh_node: MeshInstance3D = $DiceMesh
	if mesh_node == null or mesh_node.mesh == null:
		push_warning("Dice: DiceMesh not found — shader won't apply.")
		return
	var shader := load("res://game_assets/shaders/dice_charge.gdshader") as Shader
	if shader == null:
		push_warning("Dice: shader file not found.")
		return
	var surface_count := mesh_node.mesh.get_surface_count()
	for i in surface_count:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		var existing := mesh_node.mesh.surface_get_material(i)
		if existing and existing is BaseMaterial3D:
			var orig := existing as BaseMaterial3D
			mat.set_shader_parameter("texture_albedo", orig.albedo_texture)
			mat.set_shader_parameter("base_color", orig.albedo_color)
		mesh_node.set_surface_override_material(i, mat)
		_shader_materials.append(mat)
	_set_charge(0.0)

# ─────────────────────────────────────────────────────────
# PROCESS — charge animation (float + slow rotate)
# ─────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if state != DiceState.IDLE or _charge_level <= 0.0:
		return

	_charge_time += delta

	# ── Y float: rise toward camera + wobbly noise ────────
	# Base rise: lerp from 0 to CHARGE_FLOAT_HEIGHT as charge builds
	var base_rise   := _charge_level * CHARGE_FLOAT_HEIGHT
	# Wobble: noise oscillation that gets larger with charge
	var wobble      := _noise(_charge_time * CHARGE_FLOAT_SPEED) * CHARGE_FLOAT_WOBBLE * _charge_level
	var target_y    := start_position.y + base_rise + wobble

	# ── Slow rotation: noisy, grows with charge ───────────
	# Each axis gets its own noise channel so they feel independent
	var nx := _noise(_charge_time * CHARGE_ROT_NOISE_SPEED + 0.0)
	var ny := _noise(_charge_time * CHARGE_ROT_NOISE_SPEED + 3.7)
	var nz := _noise(_charge_time * CHARGE_ROT_NOISE_SPEED + 7.3)
	# Noise returns 0–1; remap to -1..1 for bidirectional rotation
	var rot_noise_x = lerp(1.0 - CHARGE_ROT_NOISE, 1.0, nx)
	var rot_noise_y = lerp(1.0 - CHARGE_ROT_NOISE, 1.0, ny)
	var rot_noise_z = lerp(1.0 - CHARGE_ROT_NOISE, 1.0, nz)

	var rot_speed   := _charge_level   # rotation only kicks in as charge builds
	rotate_x(CHARGE_ROT_X * rot_noise_x * rot_speed * delta)
	rotate_y(CHARGE_ROT_Y * rot_noise_y * rot_speed * delta)
	rotate_z(CHARGE_ROT_Z * rot_noise_z * rot_speed * delta)

	# Apply position (keep X/Z locked to start while charging)
	global_position = Vector3(start_position.x, target_y, start_position.z)

# ─────────────────────────────────────────────────────────
# PHYSICS PROCESS — settling detection
# ─────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if state == DiceState.ROLLING:
		if linear_velocity.length() < 0.05 and angular_velocity.length() < 0.05:
			settle_timer += delta
			if settle_timer >= SETTLE_DURATION:
				_process_roll_result()
		else:
			settle_timer = 0.0

# ─────────────────────────────────────────────────────────
# ROLL  (called by dice_box)
# ─────────────────────────────────────────────────────────
func _do_roll(charge: float) -> void:
	state         = DiceState.ROLLING
	result_locked = false
	can_click     = false
	sleeping      = false
	freeze        = false
	_charge_time  = 0.0

	_set_charge(0.0)

	var power   = lerp(POWER_MIN,    POWER_MAX,    charge)
	var scatter = lerp(SCATTER_MIN,  SCATTER_MAX,  charge)

	# Launch from slightly above start (the charge may have raised it — reset to known height)
	transform.origin = start_position + Vector3(
		randf_range(-scatter, scatter), 5.0, randf_range(-scatter, scatter)
	)
	linear_velocity  = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	var h_spread  = lerp(H_SPREAD_MIN, H_SPREAD_MAX, charge)
	var v_spread  = lerp(V_SPREAD_MIN, V_SPREAD_MAX, charge)
	var throw_vec = Vector3(
		randf_range(-h_spread, h_spread),
		5.0,
		randf_range(-v_spread, v_spread)
	).normalized() * randf_range(roll_strength * 1.5, roll_strength * 2.5) * power

	apply_impulse(Vector3.ZERO, throw_vec)

	var ang_scale = lerp(ANG_SCALE_MIN, ANG_SCALE_MAX, charge)
	angular_velocity = Vector3(
		randf_range(-10, 10),
		randf_range(-20, 20),
		randf_range(-25, 50)
	) * ang_scale

# ─────────────────────────────────────────────────────────
# RESULT
# ─────────────────────────────────────────────────────────
func _process_roll_result() -> void:
	if result_locked:
		return
	result_locked = true

	var best_ray: RayCast3D = null
	var best_dot := -1.0
	for ray in raycasts:
		if ray.is_colliding():
			var ray_dir := ray.global_transform.basis * ray.target_position.normalized()
			var dot     := ray_dir.dot(Vector3.DOWN)
			if dot > best_dot:
				best_dot = dot
				best_ray = ray

	var value := 1
	if best_ray:
		value = best_ray.opposite_side
	else:
		for ray in raycasts:
			if ray.is_colliding():
				value = ray.opposite_side
				break

	roll_finished.emit(value)
	state        = DiceState.IDLE
	can_click    = true
	settle_timer = 0.0

# ─────────────────────────────────────────────────────────
# SHADER HELPERS  (public — called by dice_box each frame)
# ─────────────────────────────────────────────────────────
func _set_charge(value: float) -> void:
	_charge_level = value
	for mat in _shader_materials:
		mat.set_shader_parameter("charge", value)

func _set_time(t: float) -> void:
	for mat in _shader_materials:
		mat.set_shader_parameter("time_offset", t)

# ─────────────────────────────────────────────────────────
# NOISE HELPER — smooth random value in 0..1
# Same algorithm as the shader so behaviour feels consistent
# ─────────────────────────────────────────────────────────
func _noise(x: float) -> float:
	var i := floorf(x)
	var f := x - i
	var u := f * f * (3.0 - 2.0 * f)   # smoothstep
	return lerpf(_hash(i), _hash(i + 1.0), u)

func _hash(n: float) -> float:
	return fmod(sin(n) * 43758.5453123, 1.0)

# ─────────────────────────────────────────────────────────
# PUBLIC LEGACY — keeps game_manager / any external caller working
# ─────────────────────────────────────────────────────────
func roll() -> void:
	if not can_click or state != DiceState.IDLE:
		return
	_do_roll(0.5)
