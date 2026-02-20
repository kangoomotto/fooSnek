#extends Area3D
#
#@export var dice_ref: Node
#
#func _ready():
#
	#if not dice_ref:
		#dice_ref = get_node("../Dice")
	#input_ray_pickable = true
	#
	#input_ray_pickable = true
	#set_process_input(true)
#
#func __unhandled_input(event):
	#if event is InputEventMouseButton and event.pressed:
		### # print("🖱 UnhandledInput — emitting request_dice_roll")
		#EventsBus.request_dice_roll.emit()
#
#func _unhandled_input(event):
	#const GameState = preload("res://Scripts/game_state.gd").GameState
	#var gm = get_tree().get_root().get_node_or_null("MAIN/GameManager")
	#if not gm:
		#push_error("❌ GameManager not found at MAIN/GameManager")
		#return
#
	## Only left mouse click
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#if gm.current_state == GameState.AWAITING_ROLL:
			#EventsBus.request_dice_roll.emit()
		#else:
			## # print("🚫 Dice click blocked — state:", gm.current_state)
