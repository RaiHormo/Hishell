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
	if location[-1] != '/': location += '/'
	if not DirAccess.dir_exists_absolute(location):
		grid.hide()
		title = "404"
		push_error("Folder "+location+ " wasn't found")
		return
	var location_parts = location.split("/", false)
	title = location_parts[-1] if not (location_parts.is_empty() or location_parts[-1].is_empty()) else location
	name = title
	files = DirAccess.get_files_at(location).duplicate()
	folders = DirAccess.get_directories_at(location).duplicate()
	if DirAccess.get_open_error():
		title = "Can't access this folder"
		return
	grid.show()
	for i in grid.get_children(): i.free()
	while grid.get_child_count() < files.size() + folders.size():
		var slot = preload("res://toolkit/FileSlot.tscn").instantiate()
		grid.add_child(slot)
		slot.window = self
	var i := 0
	for slot in grid.get_children():
		slot.set_to("")
	for folder in folders:
		var slot = grid.get_child(i)
		slot.set_to(folder, System.abs_path(location)+folder)
		i += 1
	for file in files:
		var slot = grid.get_child(i)
		slot.set_to(file, System.abs_path(location)+file)
		i += 1

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
