extends Node
var init: Node

var root = OS.get_user_data_dir()+"/filesystem"
var root_name:= "hishell-root"
var users: Array[Dictionary] = [
	{
		"name": "Iris",
		"password": "",
	}
]
var user: Dictionary
var file_extensions: Dictionary[StringName, PackedStringArray] = {
	"picture": ["png", "jpg", "jpeg", "svg", "avif", "webp"],
	"text": ["txt", "md", "cfg", "html", "log", "sh", "ini", "csv", "tres"]
}
var theme: Theme = preload("res://assets/themes/Default.tres")
var config_path := "~/config/"

var focused_window: BaseWindow = null

func launch(path: String, position: Vector2 = Vector2.ZERO, parent: Node = get_tree().root, maximized:= false):
	path = abs_path(path)
	var type = get_file_type(path)
	if type == "invalid" or type == "unknown":
		System.dialog("Cannot open %s, the type is set to \"%s\"."%[path, type], "Error")
		return
	var window = (preload("uid://0fthgyrf0xj8") as PackedScene).instantiate()
	window.location = path
	window.origin = position
	window.open_pos = position
	if parent is BaseWindow:
		window.parent = parent
	else: parent = get_tree().root
	window.viewport = parent.get_viewport()
	parent.add_child(window)
	if maximized: window.state = BaseWindow.STATE_MAXIMIZED
	await window.window_ready

func wait(time: float = 0):
	await get_tree().create_timer(time).timeout

func get_config(path: String, data: String, section: String, default: Variant = null) -> Variant:
	var real_path := abs_path(config_path+path)
	var config = ConfigFile.new()
	config.load(real_path)
	return config.get_value(section, data, default)

func set_config(path: String, data: String, section: String, set_to: Variant = null):
	var real_path := abs_path(config_path+path)
	var config = ConfigFile.new()
	if FileAccess.file_exists(real_path):
		config.load(real_path)
	config.set_value(section, data, set_to)
	config.save(real_path)

func get_config_file(path: String) -> ConfigFile:
	var real_path := abs_path(config_path+path)
	if FileAccess.file_exists(real_path):
		var config = ConfigFile.new()
		config.load(real_path)
		return config
	else:
		dialog("Failed to get config: %s"%[path], "Error")
		return null

func root_window():
	for i in get_tree().root.get_children():
		if i is BaseWindow: return i

func abs_path(path: String) -> String:
	path = ProjectSettings.globalize_path(path)
	path = path.replace(root_name, root)
	path = path.replace("//", "/")
	path = path.replace("~/", user_path())
	if path.ends_with("/"):
		if FileAccess.file_exists(path.left(-1)):
			path = path.left(-1)
	elif DirAccess.dir_exists_absolute(path) or path == root_name:
		path += "/"
	return path

func rel_path(path: String) -> String:
	path = path.replace(root, root_name+"/")
	path = path.replace("//", "/")
	return path

func get_usernames() -> Array[String]:
	var arr: Array[String]
	for i in users:
		arr.append(i.get("name"))
	return arr

func user_path() -> String:
	if user.is_empty(): return root
	else: return "%s/%s/"%[root, user.get("name")]

func get_file_type(location: String) -> String:
	location = System.abs_path(location)
	if DirAccess.dir_exists_absolute(location):
		return "folder"
	elif FileAccess.file_exists(location):
		var extension = location.get_extension()
		if extension.contains("/"):
			return "unknown"
		for i in file_extensions:
			if extension in file_extensions[i]:
				return i
		return "unknown"
	return "invalid"

## Copy the contents of a folder into a new folder, and return the new folders absolute path
func copy_folder(new_folder_name : String, folder_to_copy : String, new_folder_location : String) -> String:
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
	var new_dir_path : String = new_folder_location + "/" + new_folder_name
	DirAccess.make_dir_absolute(new_dir_path)
	
	var dir := DirAccess.open(folder_to_copy)
	dir.include_hidden = true
	
	#Copy each file and folder into the new folder
	var old_files : PackedStringArray = dir.get_files()
	print(old_files)
	for f : String in old_files:
		if f.ends_with(".uid"): continue
		if f.ends_with(".import"): continue
		DirAccess.copy_absolute(folder_to_copy + "/" + f, new_dir_path + "/" + f)
	var old_directories : PackedStringArray = dir.get_directories()
	for d : String in old_directories:
		copy_folder(d, folder_to_copy + "/" + d, new_dir_path)
	
	return new_dir_path

func delete_folder(directory: String) -> void:
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

func create_user_folder(username: String) -> String:
	print("Creating user folder for ", username)
	return copy_folder(username, "res://filesystem/default-user", "user://filesystem")

func dialog(message: String, title: String = "Info", _options: PackedStringArray = ["OK"]) -> int:
	print(title, ": ", message)
	OS.alert(message, title)
	return 0

func format_bytes(bytes: float) -> String:
	var units = ["bytes", "KB", "MB", "GB", "TB"]
	var unit_index = 0
	
	while bytes >= 1000 and unit_index < units.size() - 1:
		bytes /= 1000.0
		unit_index += 1
		
	return str(int(snapped(bytes, 0.01))) + " " + units[unit_index]
	
func merge_config(source: ConfigFile, destination: ConfigFile) -> ConfigFile:
	for section in source.get_sections():
		for key in source.get_section_keys(section):
			var value = source.get_value(section, key)
			destination.set_value(section, key, value)
	return destination

func current_path(scene: Node) -> String:
	var window = scene
	var repeats := 0
	while window is not BaseWindow or repeats > 10:
		if window == get_tree().root: break
		window = window.get_parent()
		repeats += 1
	if window is BaseWindow:
		return window.location
	else: return ""
