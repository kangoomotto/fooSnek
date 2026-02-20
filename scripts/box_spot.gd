# This script was previously attached to BoardBox.tscn
# and used for exporting box-specific metadata like jump size
# or movement direction. Currently unused by gameplay logic.
# Retained for potential future dynamic slot behavior extensions.

extends Marker2D

# @export var chip_direction := ChipDirection.boxWichWay.FORWARD
# @export var jump := 0

@onready var boxJumpSize: int  # Optional — unused
