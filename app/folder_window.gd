extends BaseWindow
class_name FolderWindow

var files: PackedStringArray
var folders: PackedStringArray

func open():
	await parse_folder()
	setup_window()

func parse_folder():
	var grid = %Grid
	if not is_instance_valid(grid): return
	var abs_location = System.abs_path(location)
	if abs_location[-1] != '/': abs_location += '/'
	if not DirAccess.dir_exists_absolute(abs_location):
		grid.hide()
		title = "404"
		push_error("Folder "+abs_location+ " wasn't found")
		return
	var location_parts = abs_location.split("/", false)
	title = location_parts[-1] if not (location_parts.is_empty() or location_parts[-1].is_empty()) else location
	name = title
	files = DirAccess.get_files_at(abs_location).duplicate()
	folders = DirAccess.get_directories_at(abs_location).duplicate()
	if DirAccess.get_open_error():
		title = "Can't access this folder"
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
	
	var background_file = ".wallpaper.png"
	if FileAccess.file_exists(abs_location+'/'+background_file):
		$Wallpaper.texture = Thumbnail.load_image(abs_location+'/'+background_file)
		$Wallpaper.show()
		$Blur.hide()
	else:
		$Wallpaper.hide()
		$Blur.show()
		

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
	if parent != null:
		siz.x = min(siz.x, parent.get_visible_rect().size.x - 20)
		siz.y = min(siz.y, parent.get_visible_rect().size.y - 50)
	return siz

func location_changed(_path: String):
	parse_folder()
