# res://Script/dice_raycast.gd

extends RayCast3D

	# this is a value that we will set to each raycast in the inspector
# and it is going to be whatever value is on the opposite side of the dice
@export var opposite_side: int

func _ready():
	add_exception(owner)
	# this prevents the dice from detecting the dice itself
	# because we olny want it ti detect the floor and the walls
	
