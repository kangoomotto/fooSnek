extends Node

@onready var dice_viewport_container = $DiceViewportContainer
@onready var dice_viewport: SubViewport = $DiceViewportContainer/DiceViewport
@onready var dice = $DiceViewportContainer/DiceViewport/Dice_Box/Dice
@onready var dice_preview: TextureRect = $DicePreview

func _ready():
	#create_world_cup_folders()
	# print("✅ MAIN READY — Dice initialized:", dice)
	#print_node_tree(get_tree().root, 0)
	#_print_scene_tree(get_tree().root, 0)
	#await print_directory_structure("res://")
	#list_assets()

	
		# configure SubViewport to render with transparency
	dice_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	dice_viewport.transparent_bg = true
	dice_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER

	# Dice is only visual; control is handled by GameManager
func set_dice_visibility(visible: bool) -> void:
	dice_viewport_container.visible = visible


func _input(event):
	if event.is_action_pressed("ui_screenshot"):
		capture_screenshot()

func capture_screenshot(path := "D:/Dropbox/_ PROYECTOS/FooSnek/IMAGEN/screenshots/screenshot.png"):
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.png"])
	add_child(dialog)
	dialog.popup_centered()
	dialog.file_selected.connect(func(path):
		img.save_png(path)
	)


func print_node_tree(node: Node, indent: int) -> void:
	var prefix = "├── " if indent > 0 else ""
	var indentation = "    ".repeat(indent)
	var line = "%s%s (%s)" % [indentation + prefix, node.name, node.get_class()]
	print(line)

	for child in node.get_children():
		if child is Node:
			print_node_tree(child, indent + 1)

func _print_scene_tree(node: Node, indent: int = 0):
	print("  ".repeat(indent) + node.name)  # Print node with indentation
	for child in node.get_children():
		_print_scene_tree(child, indent + 1)

func print_directory_structure(path: String = "res://", indent_level: int = 0) -> void:
	var dir = DirAccess.open(path)
	if dir == null:
		print("❌ Failed to open directory:", path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path = path + "/" + file_name
		var indent = "  ".repeat(indent_level)

		if dir.current_is_dir():
			print(indent + "📁 " + file_name)
			print_directory_structure(full_path, indent_level + 1)
		else:
			if not file_name.ends_with(".import"):
				pass
				print(indent + "📄 " + file_name)

		file_name = dir.get_next()

	dir.list_dir_end()

func list_assets() -> void:
	print("\n📂 Listing all assets in res://game_assets/")
	_scan_dir("res://game_assets/")

func _scan_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("❌ Cannot open directory: " + path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if file_name not in [".", ".."]:
				_scan_dir(path + "/" + file_name)
		else:
			if not file_name.ends_with(".import"):
				pass
				print(path + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
