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
	if type == "invalid":
		System.dialog("Cannot open %s, no such file or directory."%[path], "Error")
		return
	if type == "unknown":
		System.dialog("Cannot open %s, the file type is unknown."%[path], "Error")
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

func root_window() -> BaseWindow:
	for i in get_tree().root.get_children():
		if i is BaseWindow: return i
	return null

func dialog(message: String, title: String = "Info", options: PackedStringArray = ["OK"], parent: Node = System.root_window()) -> int:
	print(title, ": ", message)
	var window: DialogWindow = (load("res://toolkit/DialogWindow.tscn") as PackedScene).instantiate()
	if parent == null:
		parent = get_tree().root
	parent.add_child(window)
	window.parent = parent
	window.get_node("%ContentLabel").text = message
	window.get_node("%HeaderLabel").text = title
	window.show_options(options)
	return await window.wait_for_awnser()

func open_context_menu(location: String, on_node: Control = null) -> PopupMenu:
	const CONTEXT_MENU = preload("uid://bo2a2bryp5sca")
	var menu: PopupMenu = CONTEXT_MENU.instantiate()
	get_tree().root.add_child(menu)
	menu.draw_menu(location)
	if on_node != null and on_node.has_method("link_window"):
		menu.window = on_node.window
	return menu

func reboot(reinstall := false) -> void:
	for i in windows:
		i.queue_free()
	windows.clear()
	var boot = load("res://lib/Boot.tscn").instantiate()
	boot.reinstall = reinstall
	get_tree().root.add_child(boot)
	

func refresh_all() -> void:
	for i in windows:
		i.send("parse_folder")
