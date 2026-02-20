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
	EventsBus.request_dice_roll.connect(_on_request_dice_roll)
	EventsBus.dice_rolled.connect(_on_dice_rolled)
	
		# configure SubViewport to render with transparency
	dice_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	dice_viewport.transparent_bg = true
	dice_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER


	# assign its texture to the UI preview
	#dice_preview.texture = dice_viewport.get_texture()
	
	#dice_preview.texture = dice_viewport.get_texture()
	## print(dice_viewport.transparent_bg, dice_viewport.render_target_clear_mode)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		EventsBus.request_dice_roll.emit()

func _on_request_dice_roll() -> void:
	## print("🎯 Roll requested")
	pass

func _on_dice_rolled(value: int) -> void:
	## print("🎯 Dice result:", value)
	pass
	
	# Dice is only visual; control is handled by GameManager
func set_dice_visibility(visible: bool) -> void:
	dice_viewport_container.visible = visible

func move_display():
	await get_tree().process_frame  # ⏳ Let window fully initialize
	DisplayServer.window_set_current_screen(2)
	DisplayServer.window_set_position(Vector2(3000, 0))
	
	var count = DisplayServer.get_screen_count()
	# print("🖥️ Screen count:", count)
	for i in count:
		var size = DisplayServer.screen_get_size(i)
		var pos = DisplayServer.screen_get_position(i)
		# print("Screen %d: size=%s, position=%s" % [i, size, pos])
		
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

func _input(event):
	if event.is_action_pressed("ui_screenshot"):
		capture_screenshot()

func capture_screenshot(path := "D:/Dropbox/_ PROYECTOS/FooSnek/IMAGEN/screenshots/screenshot.png"):
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	#img.save_png(path)
	
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.png"])
	add_child(dialog)
	dialog.popup_centered()

	dialog.file_selected.connect(func(path):
		img.save_png(path)
	)

func create_world_cup_folders():
	var db = preload("res://data/teams_db.gd").new()
	var base_path = "res://game_assets/images/teams/world_cup/"
	var default_shield = "res://game_assets/images/defaults/shield.png"
	var teams = db.world_cup_teams

	# Ensure base folder exists
	if not DirAccess.dir_exists_absolute(base_path):
		var err = DirAccess.make_dir_absolute(base_path)
		if err != OK:
			print("Failed to create base path: ", base_path)
			return

	for team in teams:
		var team_folder = base_path + team["id"]
		if not DirAccess.dir_exists_absolute(team_folder):
			var err = DirAccess.make_dir_absolute(team_folder)
			if err == OK:
				print("Created folder: ", team_folder)
			else:
				print("Failed to create folder: ", team_folder)
				continue
		else:
			print("Folder already exists: ", team_folder)

		# Copy default shield.png if missing
		var shield_path = team_folder + "/shield.png"
		if not FileAccess.file_exists(shield_path):
			var dir_access = DirAccess.open("res://") # root instance for file operations
			if dir_access:
				var copy_err = dir_access.copy(default_shield, shield_path)
				if copy_err == OK:
					print("Copied default shield to: ", shield_path)
				else:
					print("Failed to copy shield to: ", shield_path)
			else:
				print("Failed to open DirAccess for copying")
		else:
			print("Shield already exists: ", shield_path)

	print("✅ World Cup folders + default shields complete.")
