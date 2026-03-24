extends Component
class_name FolderView

var files: PackedStringArray
var folders: PackedStringArray
var wallpaper: TextureRect
@onready var error: Label = $Error
@onready var grid: Container = %Grid

func init():
	parse_folder()
	if Meta.get_folder_meta(window.location, "Maximized", "LAUNCH"):
		window.send("window_control", "maximize")
	window.prev_size = get_optimal_size()

func parse_folder():
	error.hide()
	wallpaper = window.get_node("Content/Wallpaper")
	if not is_instance_valid(grid): return
	var abs_location = System.abs_path(window.location)
	if abs_location[-1] != '/': abs_location += '/'
	if not DirAccess.dir_exists_absolute(abs_location):
		grid.hide()
		window.title = "404"
		error.text = "404"
		error.show()
		push_error("Folder "+abs_location+ " wasn't found")
		return
	#var location_parts = abs_location.split("/", false)
	window.title = abs_location.get_file()
	files = DirAccess.get_files_at(abs_location).duplicate()
	for i in files.duplicate():
		if i.ends_with(".import"):
			files.erase(i)
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
		slot.window = window
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
	var abs_location = System.abs_path(window.location)
	
	if wallpaper == null: wallpaper.hide()
	var background_file = ".wallpaper"
	for i in System.file_extensions["picture"]:
		var path = abs_location+'/'+background_file+"."+i
		if FileAccess.file_exists(path):
			wallpaper.texture = Thumbnail.load_image(path)
			wallpaper.show()
	
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
	
	send("icon_size_slider", Meta.get_folder_meta(window.location, "GridSize", "LAYOUT", 64))

func get_optimal_size():
	var siz:= Vector2i(350, 250)
	var number_of_files = folders.size() + files.size()
	print("Number of files:", number_of_files)
	if number_of_files > 2: siz.x += 64
	if number_of_files > 4: 
		siz.y += 64
	if number_of_files > 8: 
		#siz.y += 100
		siz.x += 64;
	if number_of_files > 12: siz.y += 64*2
	if number_of_files > 20: siz.y += 64*2
	if number_of_files > 40: siz.x += 64*2
	#siz *= 1 + grid.icon_size / 64
	print("Optimal size:", siz)
	if window.viewport != null:
		siz.x = min(siz.x, window.viewport.get_visible_rect().size.x - 20)
		siz.y = min(siz.y, window.viewport.get_visible_rect().size.y - 50)
	return siz

func location_changed(_path: String):
	parse_folder()

func create(type: String):
	var path = System.abs_path(window.location)
	match type:
		"folder":
			var dir = DirAccess.open(path)
			dir.make_dir("New Folder")
		"text_file":
			var file = FileAccess.open(path+"/New File.txt", FileAccess.WRITE)
			file.close()
	parse_folder()
