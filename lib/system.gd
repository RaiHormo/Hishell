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
var file_associations: Dictionary[StringName, String] = {
	"folder": "res://app/FolderWindow.tscn",
	"picture": "res://app/PictureWindow.tscn",
	"unknown": "",
	"invalid": "",
}
var theme: Theme = preload("res://assets/themes/Default.tres")

func launch(path: String, position: Vector2 = Vector2.ZERO, parent: Node = get_tree().root, maximized:= false):
	path = abs_path(path)
	var runner = file_associations.get(get_file_type(path))
	if runner == "" or runner == null: return
	var window = (load(runner) as PackedScene).instantiate()
	window.location = path
	window.origin = position
	window.open_pos = position
	window.parent = parent.get_viewport()
	parent.add_child(window)
	if maximized: window.state = FolderWindow.STATE_MAXIMIZED
	await window.window_ready

func wait(time: float = 0):
	await get_tree().create_timer(time).timeout

func root_window():
	for i in get_tree().root.get_children():
		if i is FolderWindow: return i

func abs_path(path: String) -> String:
	path = path.replace(root_name, root)
	path = path.replace("//", "/")
	return path

func rel_path(path: String) -> String:
	path = path.replace(root, root_name)
	path = path.replace("//", "/")
	return path

func get_usernames() -> Array[String]:
	var arr: Array[String]
	for i in users:
		arr.append(i.get("name"))
	return arr

func get_file_type(location: String) -> String:
	location = System.abs_path(location)
	if DirAccess.dir_exists_absolute(location):
		return "folder"
	elif FileAccess.file_exists(location):
		var extension = location.split(".", false)[-1].to_lower()
		if extension.contains("/"):
			return "unknown"
		for i in file_extensions:
			if extension in file_extensions[i]:
				return i
		return "unknown"
	return "invalid"
