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

func launch(path: String, position: Vector2 = Vector2.ZERO, parent: Node = get_tree().root, maximized:= false):
	var window = preload("res://lib/FolderWindow.tscn").instantiate()
	parent.add_child.call_deferred(window)
	window.location = path
	window.origin = position
	if maximized: window.state = FolderWindow.STATE_MAXIMIZED
	window.parent = parent.get_viewport()

func wait(time: float = 0):
	await get_tree().create_timer(time).timeout

func root_window():
	for i in get_tree().root.get_children():
		if i is FolderWindow: return i

func abs_path(path: String) -> String:
	path = path.replace(root_name, root)
	path = path.replace("//", "/")
	return path

func get_usernames() -> Array[String]:
	var arr: Array[String]
	for i in users:
		arr.append(i.get("name"))
	return arr
