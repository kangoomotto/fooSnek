extends Node3D
# =========================================================
# 🎲 DICE BOX CONTROLLER — Press-and-Hold Charge Mechanic
# ---------------------------------------------------------
# Human player: press anywhere → charge → release → emits
#               request_dice_roll with stored charge level
# CPU player:   request_dice_roll arrives → rolls at 0.5
#
# game_manager always hears request_dice_roll first and
# transitions the FSM. dice_box then does the physics roll.
# =========================================================

@onready var dice: RigidBody3D = $Dice
@onready var result_label: Label = $Result_Label

var rolling: bool = false
var roll_enabled: bool = false
var dice_ref_ready: bool = false

# ── Charge state ──────────────────────────────────────────
var _charging: bool = false
var _charge_elapsed: float = 0.0
var _pending_charge: float = 0.5   # charge level stored at release, used when signal fires
const CHARGE_TIME_MAX := 2.5

# =========================================================
func _ready() -> void:
	EventsBus.dice_roll_enabled.connect(_set_roll_enabled)
	EventsBus.request_dice_roll.connect(_on_request_dice_roll)

	if dice.has_signal("roll_finished"):
		dice.roll_finished.connect(_on_dice_roll_finished)
		dice_ref_ready = true

	_setLightParameters()

# =========================================================
func _setLightParameters() -> void:
	if get_viewport().world_3d == null:
		get_viewport().world_3d = World3D.new()
	for light in get_children():
		if light is DirectionalLight3D or light is SpotLight3D:
			light.shadow_enabled = true
			light.shadow_bias = 0.05

# =========================================================
# 🔹 FSM CONTROL
# =========================================================
func _set_roll_enabled(enabled: bool) -> void:
	roll_enabled = enabled
	if not enabled:
		_cancel_charge()

# =========================================================
# 🔹 HUMAN INPUT — press anywhere to charge, release to roll
# =========================================================
func _unhandled_input(event: InputEvent) -> void:
	if not roll_enabled or rolling or not dice_ref_ready:
		return

	var pressed  := false
	var released := false

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed  = event.pressed
		released = not event.pressed
	elif event is InputEventScreenTouch:
		pressed  = event.pressed
		released = not event.pressed

	if pressed and not _charging:
		_begin_charge()
		get_viewport().set_input_as_handled()
	elif released and _charging:
		_release_roll()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if _charging:
		_charge_elapsed = min(_charge_elapsed + delta, CHARGE_TIME_MAX)
		dice._set_charge(_charge_elapsed / CHARGE_TIME_MAX)
		dice._set_time(Time.get_ticks_msec() / 1000.0)

func _begin_charge() -> void:
	_charging = true
	_charge_elapsed = 0.0
	dice._set_charge(0.0)

func _release_roll() -> void:
	if not _charging:
		return
	# Store charge level — will be consumed when request_dice_roll fires back
	_pending_charge = _charge_elapsed / CHARGE_TIME_MAX
	_cancel_charge()
	# Emit the signal — game_manager transitions FSM, then our handler fires
	EventsBus.request_dice_roll.emit()

func _cancel_charge() -> void:
	_charging = false
	_charge_elapsed = 0.0
	if dice_ref_ready:
		dice._set_charge(0.0)

# =========================================================
# 🔹 ROLL HANDLER — fires for BOTH human and CPU
#    game_manager has already transitioned FSM by this point
# =========================================================
func _on_request_dice_roll() -> void:
	EventsBus.request_dice_roll_sfx.emit()

	if not roll_enabled or rolling or not dice_ref_ready:
		return

	rolling = true
	result_label.visible = false

	# Use stored charge for human, default 0.5 for CPU
	var charge := _pending_charge
	_pending_charge = 0.5   # reset to default for next CPU turn

	dice._do_roll(charge)

	# Predictive impact SFX
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = 0.8
	add_child(t)
	t.start()
	t.timeout.connect(func():
		EventsBus.request_dice_impact_sfx.emit()
		t.queue_free()
	)

# =========================================================
# 🔹 ROLL FINISH
# =========================================================
func _on_dice_roll_finished(value: int) -> void:
	rolling = false
	result_label.visible = true
	result_label.text = "%d" % value
	EventsBus.dice_rolled.emit(value)
