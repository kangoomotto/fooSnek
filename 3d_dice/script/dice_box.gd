extends Node3D
# =========================================================
# 🎲 DICE BOX CONTROLLER — 3D Dice + FSM Gating (Final)
# ---------------------------------------------------------
# Works with dice_3d.gd instead of click area.
# FSM emits dice_roll_enabled(enabled) to allow / block rolls.
# GameManager emits EventsBus.request_dice_roll when roll is allowed.
# =========================================================

@onready var dice: RigidBody3D = $Dice
@onready var result_label: Label = $Result_Label

var rolling: bool = false
var roll_enabled: bool = false	# 🔒 FSM-gated
var dice_ref_ready: bool = false

# =========================================================
# 🔹 READY
# =========================================================
func _ready() -> void:

	# FSM gating signal
	EventsBus.dice_roll_enabled.connect(_set_roll_enabled)
	# Game flow signals
	EventsBus.request_dice_roll.connect(_on_request_dice_roll)
	
	# Connect dice 3D script signal
	if dice.has_signal("roll_finished"):
		dice.roll_finished.connect(_on_dice_roll_finished)
		dice_ref_ready = true

	_setLightParameters()
	#result_label.visible = false
	
	# print("🎲 DiceBox ready | FSM-gated dice control active")

# =========================================================
# 🔹 LIGHTING SETUP
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
	if enabled:
		pass
		# print("🎲 DiceBox → Roll enabled")
	else:
		pass
		# print("⛔ DiceBox → Roll disabled by FSM")

# =========================================================
# 🔹 REQUEST HANDLER (CALLED BY FSM)
# =========================================================
func _on_request_dice_roll() -> void:
	# 🔊 Play dice roll SFX immediately
	EventsBus.request_dice_roll_sfx.emit() 	

	# ✅ Ensure FSM allows roll
	if not roll_enabled:
		return
	if rolling:
		return
	if not dice_ref_ready:
		push_error("❌ Dice reference not ready — check Dice node")
		return

	# 🔒 Start rolling
	rolling = true
	#result_label.visible = false
	dice.roll()	# Directly triggers RigidBody3D physics impulse

	# 🔊 Predictive dice impact SFX (before visual landing)
	var t = Timer.new()
	t.one_shot = true
	t.wait_time = .8  # ~1 frame at 60 FPS; adjust if needed
	add_child(t)
	t.start()
	t.timeout.connect(func():
		EventsBus.request_dice_impact_sfx.emit()  # 🔊 plays before landing
		t.queue_free()
	)


# =========================================================
# 🔹 ROLL FINISH CALLBACK
# =========================================================
func _on_dice_roll_finished(value: int) -> void:
	#print("value: ", value)
	rolling = false
	result_label.visible = true
	result_label.text = "%d" % value #Result:
	EventsBus.dice_rolled.emit(value)
	#EventsBus.request_dice_impact_sfx.emit() 	# 🔊
	# print("✅ DiceBox → Roll complete | value:", value)
