extends Node
class_name Filesystem

static func current_path(scene: Node) -> String:
	var window = scene
	var repeats := 0
	while window is not BaseWindow or repeats > 10:
		if window == System.get_tree().root: break
		window = window.get_parent()
		repeats += 1
	if window is BaseWindow:
		return window.location
	else: return ""
	
static func get_file_type(location: String) -> String:
	if "://" in location:
		var prefix := path_prefix(location)
		if not prefix.is_empty(): return prefix
	if is_folder(location):
		return "folder"
	elif is_file(location):
		var extension = location.get_extension()
		if extension.contains("/"):
			return "unknown"
		for i in System.file_extensions:
			if extension in System.file_extensions[i]:
				return i
		return "unknown"
	return "invalid"

## Copy the contents of a folder into a new folder, and return the new folders absolute path
static func copy_folder(new_folder_name : String, folder_to_copy : String, new_folder_location : String) -> String:
	new_folder_location = abs_path(new_folder_location)
	print("Copying folder ", folder_to_copy, " to ", new_folder_location)
	
	# Handle path issues
	if not DirAccess.dir_exists_absolute(folder_to_copy):
		printerr("Invalid folder to copy '" + folder_to_copy + ".")
		return ""
	if not DirAccess.dir_exists_absolute(new_folder_location):
		printerr("Invalid copy location '" + new_folder_location + ".")
		return ""

	# Get new location contents, folders and files
	var copy_location_contents : PackedStringArray = DirAccess.get_directories_at(new_folder_location)
	copy_location_contents.append_array(DirAccess.get_files_at(new_folder_location))
	
	# Make sure new name is valid by adding numbers to the end,
	# so we won't overrite any existing files / folders
	while new_folder_name in copy_location_contents:
		new_folder_name += str(randi_range(0, 9))
	
	# Make new directory 
	var new_dir_path : String = new_folder_location + new_folder_name
	DirAccess.make_dir_absolute(new_dir_path)
	
	var dir := DirAccess.open(folder_to_copy)
	dir.include_hidden = true
	
	#Copy each file and folder into the new folder
	var old_files : PackedStringArray = dir.get_files()
	print(old_files)
	for f : String in old_files:
		if f.ends_with(".uid"): continue
		if f.ends_with(".import"): continue
		if f.ends_with(".remap"): continue
		var to_copy := folder_to_copy + "/" + f
		var new_path := new_dir_path + "/" + f
		DirAccess.copy_absolute(to_copy, new_path)
	var old_directories : PackedStringArray = dir.get_directories()
	for d : String in old_directories:
		copy_folder(d, folder_to_copy + "/" + d, new_dir_path)
	
	return new_dir_path

static func delete_folder(directory: String) -> void:
	directory = abs_path(directory)
	print("Deleting ", directory)
	if OS.get_name() == "Web":
		var dir := DirAccess.open(directory)
		dir.include_hidden = true
		for dir_name in dir.get_directories():
			if not dir.is_link(directory):
				delete_folder(directory.path_join(dir_name))
		for file_name in dir.get_files():
			if not dir.is_link(directory):
				DirAccess.remove_absolute(directory.path_join(file_name))
		if dir.remove(directory) == 1:
			print("Directory not empty: ", dir.get_directories())
	else: OS.move_to_trash(directory)

static func path_prefix(path: String, with_the_thingy := false) -> String:
	var ex = Utils.regex(path, "^(.*)://")
	var string = ex.get_string() if ex != null else ""
	if not with_the_thingy: string = string.replace("://", "")
	return string

static func abs_path(path: String, fix := true) -> String:
	if "://" in path and not path.begins_with("user://") and not path.begins_with("res://"):
		var prefix = Utils.regex(path, "^.*://")
		print(prefix.get_string())
		if prefix != null:
			path = path.replace(prefix.get_string(), "")
			if not path.begins_with(System.root_name): path = "/" + path
	path = ProjectSettings.globalize_path(path)
	path = path.replace(System.root_name, System.root)
	if fix:
		path = fix_path(path)
	return path

static func rel_path(path: String) -> String:
	path = path.replace(System.root, System.root_name)
	path = fix_path(path)
	return path

static func fix_path(path: String) -> String:
	if '~' in path:
		path = path.replace("~/", User.user_path())
	if path.ends_with("/"):
		if is_file(path.left(-1)):
			path = path.left(-1)
	elif Filesystem.is_folder(path) or path == System.root_name:
		path += "/"
	return path

static func exists(path: String) -> bool:
	return is_file(path) or is_folder(path)

static func is_file(path: String) -> bool:
	if not path.begins_with("/"):
		path = abs_path(path)
	return FileAccess.file_exists(path)

static func is_folder(path: String) -> bool:
	if not path.begins_with("/"):
		path = abs_path(path, false)
	return DirAccess.dir_exists_absolute(path)

static func open_folder(path: String) -> DirAccess:
	if not path.begins_with("/"):
		path = abs_path(path)
	return DirAccess.open(path)

static func open_file(path: String, mode: FileAccess.ModeFlags = FileAccess.READ) -> FileAccess:
	if not path.begins_with("/"):
		path = abs_path(path)
	return FileAccess.open(path, mode)
