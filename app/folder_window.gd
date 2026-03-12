extends BaseWindow
class_name FolderWindow

var files: PackedStringArray
var folders: PackedStringArray
@onready var wallpaper = $Content/Wallpaper
@onready var error = $Content/Error

func open():
	await parse_folder()
	setup_window()
	if Meta.get_folder_meta(location, "Maximized", "LAUNCH"):
		message("window_control", "maximize")

func parse_folder():
	error.hide()
	var grid = %Grid
	if not is_instance_valid(grid): return
	var abs_location = System.abs_path(location)
	if abs_location[-1] != '/': abs_location += '/'
	if not DirAccess.dir_exists_absolute(abs_location):
		grid.hide()
		title = "404"
		error.text = "404"
		error.show()
		push_error("Folder "+abs_location+ " wasn't found")
		return
	var location_parts = abs_location.split("/", false)
	title = location_parts[-1] if not (location_parts.is_empty() or location_parts[-1].is_empty()) else location
	name = title
	files = DirAccess.get_files_at(abs_location).duplicate()
	folders = DirAccess.get_directories_at(abs_location).duplicate()
	if DirAccess.get_open_error():
		error.text = str(DirAccess.get_open_error())
		error.show()
		return
	grid.show()
	for i in grid.get_children(): i.queue_free()
	await get_tree().process_frame
	while grid.get_child_count() < files.size() + folders.size():
		var slot = preload("res://toolkit/FileSlot.tscn").instantiate()
		grid.add_child(slot)
		slot.window = self
	var i := 0
	for slot in grid.get_children():
		slot.set_to("")
	for folder in folders:
		var slot = grid.get_child(i)
		slot.set_to(folder, abs_location+folder)
		i += 1
	for file in files:
		var slot = grid.get_child(i)
		slot.set_to(file, abs_location+file)
		i += 1
		
	view_apply()

func view_apply():
	var abs_location = System.abs_path(location)
	
	wallpaper.hide()
	var background_file = ".wallpaper"
	for i in System.file_extensions["picture"]:
		if FileAccess.file_exists(abs_location+'/'+background_file+"."+i):
			wallpaper.texture = Thumbnail.load_image(abs_location+'/'+background_file+"."+i)
			wallpaper.show()
	
	var grid: Container = %Grid
	
	match Meta.get_folder_meta(abs_location, "GridHorizontalAlign", "LAYOUT"):
		0: grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		1: grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		2: grid.size_flags_horizontal = Control.SIZE_SHRINK_END
		_: grid.size_flags_horizontal = Control.SIZE_FILL
	grid.size_flags_horizontal |= Control.SIZE_EXPAND
	match Meta.get_folder_meta(abs_location, "GridHorizontalAlign", "LAYOUT"):
		0: grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		1: grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		2: grid.size_flags_vertical = Control.SIZE_SHRINK_END
		_: grid.size_flags_vertical = Control.SIZE_FILL
	grid.size_flags_vertical |= Control.SIZE_EXPAND
	
	icon_size_slider(Meta.get_folder_meta(location, "GridSize", "LAYOUT", 64))

func get_optimal_size():
	var siz:= Vector2i(400, 300)
	var number_of_files = folders.size() + files.size()
	print(number_of_files)
	if number_of_files > 2: siz.x += 200
	if number_of_files > 4: siz.y += 100
	if number_of_files > 8: siz.y += 200; siz.x += 200;
	if number_of_files > 12: siz.y += 200
	if number_of_files > 20: siz.y += 200
	if number_of_files > 40: siz.x += 300
	prev_size = siz
	print(siz)
	if viewport != null:
		siz.x = min(siz.x, viewport.get_visible_rect().size.x - 20)
		siz.y = min(siz.y, viewport.get_visible_rect().size.y - 50)
	return siz

func location_changed(_path: String):
	parse_folder()

func create(type: String):
	var path = System.abs_path(location)
	match type:
		"folder":
			var dir = DirAccess.open(path)
			dir.make_dir("New Folder")
		"text_file":
			var file = FileAccess.open(path+"/New File.txt", FileAccess.WRITE)
			file.close()
	parse_folder()

func icon_size_slider(value: float) -> void:
	%Grid.icon_size = int(value)
	_update_layout()
	if value != 64:
		Meta.set_folder_meta(location, "GridSize", "LAYOUT", value)
