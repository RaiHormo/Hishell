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

static func cleanup() -> void:
	rm_rf("~/trash", [".meta", ".icon.svg"])
	rm_rf("~/clipboard", [".meta", ".icon.svg"])

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

static func link(location: String, to: String, new_name = just_the_name(location)) -> void:
	location = abs_path(location)
	to = abs_path(to)
	if exists(to+new_name):
		return link(location, to, new_name + " (Link)")
	var dir := open_folder(to)
	dir.create_link(location, to+new_name)
	print("Linked %s to %s as %s"%[location, to, new_name])

static func move(location: String, to: String) -> void:
	location = abs_path(location)
	to = abs_path(to)
	if location == to:
		System.dialog("Can't move a directory into itself.", "Error Moving Directory")
		return
	if location in to:
		System.dialog("Can't move a directory into one of it's sub-directories.", "Error Moving Directory")
		return
	if await copy(location, to) == OK:
		delete(location)

static func copy(location: String, to: String, overwrite := false, new_name := just_the_name(location)) -> Error:
	location = abs_path(location)
	to = abs_path(to)
	if (location == to or location.get_base_dir() == to.trim_suffix('/')): 
		return ERR_ALREADY_EXISTS
	if not exists(to): 
		DirAccess.make_dir_recursive_absolute(to)
	if is_file(location):
		var new_path = to.path_join(new_name)
		if not overwrite:
			if is_file(new_path):
				if await System.dialog("File '%s' already exists."%[new_path], "Copy", ["Overwrite", "Abort"]):
					return ERR_ALREADY_EXISTS
		var err := DirAccess.copy_absolute(location, new_path)
		return err
	elif is_folder(location):
		print(just_the_name(location))
		if copy_folder(new_name, location, to) == "":
			return ERR_UNAVAILABLE
	else:
		printerr("No such file or directory: ", location)
		return ERR_FILE_NOT_FOUND
	return OK

## Copy the contents of a folder into a new folder, and return the new folders absolute path
static func copy_folder(new_folder_name : String, folder_to_copy : String, new_folder_location : String, overwrite := false, recursively := true) -> String:
	new_folder_location = abs_path(new_folder_location)
	folder_to_copy = abs_path(folder_to_copy)
	print("Copying folder ", folder_to_copy, " to ", new_folder_location)
	
	# Handle path issues
	if not DirAccess.dir_exists_absolute(folder_to_copy):
		printerr("Invalid folder to copy '" + folder_to_copy + "'.")
		return ""
	if not DirAccess.dir_exists_absolute(new_folder_location):
		printerr("Invalid copy location '" + new_folder_location + "'.")
		return ""

	# Get new location contents, folders and files
	var copy_location_contents : PackedStringArray = DirAccess.get_directories_at(new_folder_location)
	copy_location_contents.append_array(DirAccess.get_files_at(new_folder_location))
	
	if not overwrite:
		while new_folder_name in copy_location_contents:
			new_folder_name += " (%d)"%[randi_range(1, 9)]
	
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
		var to_copy := folder_to_copy.path_join(f)
		var new_path := new_dir_path.path_join(f)
		DirAccess.copy_absolute(to_copy, new_path)
	var old_directories : PackedStringArray = dir.get_directories()
	if recursively:
		for d : String in old_directories:
			copy_folder(d, folder_to_copy.path_join(d), new_dir_path)
	
	return new_dir_path

static func delete(location: String):
	if is_file(location):
		DirAccess.remove_absolute(abs_path(location))
	elif is_folder(location):
		delete_folder(location)
	else:
		System.dialog("No such file or directory: "+ location, "Delete")

static func trash(location: String):
	var to := abs_path("~/trash")
	location = abs_path(location)
	if location == to:
		if await System.dialog("Empty trash?", "Trash", ["Yes", "No"]) == 0:
			Filesystem.cleanup()
		return
	if location in to or to in location:
		if await System.dialog("Can't trash '%s'. Delete instead?"%[rel_path(location)], "Trash", ["Yes", "No"]) == 0:
			delete_folder(location)
		return
	if not exists(to): 
		DirAccess.make_dir_absolute(to)
	if is_file(location):
		var err := DirAccess.copy_absolute(location, to+location.get_file())
		if err != OK:
			printerr(err)
		err = DirAccess.remove_absolute(location)
		if err != OK:
			printerr(err)
	elif is_folder(location):
		copy_folder(location.get_file(), location, to)
		delete_folder(location)

static func delete_folder(directory: String, just_empty_it:= false) -> void:
	directory = abs_path(directory)
	if not exists(directory): return
	print("Deleting ", directory)
	if OS.get_name() == "Web":
		rm_rf(directory)
		DirAccess.remove_absolute(directory)
	else: OS.move_to_trash(directory)
	if just_empty_it:
		DirAccess.make_dir_absolute(directory)

static func rm_rf(directory: String, whitelist: Array[String] = [], include_hidden := true) -> void:
	if not is_folder(directory): return
	print("Recursively deleting ", directory)
	directory = abs_path(directory)
	var dir := DirAccess.open(directory)
	dir.include_hidden = include_hidden
	if System.root not in directory: 
		print("Dangerous, aborting")
		return
	for dir_name in dir.get_directories():
		if dir_name in whitelist: continue
		if not dir.is_link(directory):
			rm_rf(directory.path_join(dir_name))
	for file_name in dir.get_files():
		if file_name in whitelist: continue
		if not dir.is_link(directory):
			DirAccess.remove_absolute(directory.path_join(file_name))

static func path_prefix(path: String, with_the_thingy := false) -> String:
	var ex = Utils.regex(path, "^(.*)://")
	var string = ex.get_string() if ex != null else ""
	if not with_the_thingy: string = string.replace("://", "")
	return string

static func abs_path(path: String, fix := true) -> String:
	if path.begins_with("~"):
		path = path.replace("~/", User.user_path())
	if "://" in path and not path.begins_with("user://") and not path.begins_with("res://"):
		var prefix = Utils.regex(path, "^.*://")
		print(prefix.get_string())
		if prefix != null:
			path = path.replace(prefix.get_string(), "")
			if not path.begins_with(System.root_name): path = "/" + path
	if not path.begins_with("res://"):
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
	if path.begins_with("~"):
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

static func just_the_name(location: String) -> String:
	return location.split('/', false)[-1]

static func parent_folder(location: String) -> String:
	var prt := abs_path(location.rstrip("/").get_base_dir())
	return rel_path(prt)
