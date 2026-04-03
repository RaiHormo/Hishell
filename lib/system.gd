extends Node
var init: Node

var root = OS.get_user_data_dir()+"/filesystem"
var root_name:= "hishell-root"
var file_extensions: Dictionary[StringName, PackedStringArray] = {
	"picture": ["png", "jpg", "jpeg", "svg", "avif", "webp"],
	"text": ["txt", "md", "cfg", "html", "log", "sh", "ini", "csv", "tres", "tscn", "meta", "gd"]
}

var focused_window: BaseWindow = null
var windows: Array[BaseWindow]

func launch(path: String, position: Vector2 = Vector2.ZERO, parent: Node = root_window(), maximized:= false):
	var type = Filesystem.get_file_type(path)
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
	windows.append(window)

func wait(time: float = 0):
	await get_tree().create_timer(time).timeout

func root_window():
	for i in get_tree().root.get_children():
		if i is BaseWindow: return i

func dialog(message: String, title: String = "Info", _options: PackedStringArray = ["OK"]) -> int:
	print(title, ": ", message)
	OS.alert(message, title)
	return 0
