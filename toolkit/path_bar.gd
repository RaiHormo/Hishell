extends ScrollContainer

var path_folders: PackedStringArray
var window: BaseWindow

func show_path(path: String):
	for i in $Breadcrumbs.get_children():
		if i.name != "Path0": i.queue_free()
	path = System.rel_path(path)
	path_folders = path.split("/", false)
	var root_folders: PackedStringArray
	if window.parent != null: 
		root_folders = window.parent.location.split("/")
		print(root_folders.size(), " ",path_folders.size())
		if root_folders.size() >= path_folders.size(): root_folders.clear()
	for i in path_folders:
		var dup = $Breadcrumbs/Path0.duplicate()
		if i == System.root_name:
			dup.icon = preload("res://assets/higameos_logo.png")
			dup.text = ""
		else:
			dup.text = i
		$Breadcrumbs.add_child(dup)
		if i in root_folders: dup.hide()
		else: dup.show()
	$Edit.text = path
	$Breadcrumbs.get_children()[-1].set_pressed_no_signal(true)
	await System.wait(0.01)
	set_deferred("scroll_horizontal", 999999)

func link_window(with: BaseWindow):
	window = with
	show_path(window.location)

func _on_breadcrumb_pressed() -> void:
	var node: Button = get_viewport().gui_get_focus_owner()
	if path_folders[node.get_index()-1] == path_folders[-1]:
		$Edit.show()
		$Breadcrumbs.hide()
	else:
		var new_location: String = ""
		if path_folders[0] != System.root_name:
			new_location += "/"
		var count = node.get_index()
		print(count)
		for i in path_folders:
			new_location += i+"/"
			count -= 1
			if count == 0:
				break
		print(new_location)
		window.navigate(System.abs_path(new_location), true)
		show_path(new_location)

func _on_edit_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		$Edit.hide()
		$Breadcrumbs.show()

func _on_edit_text_submitted(new_text: String) -> void:
	if DirAccess.dir_exists_absolute(System.abs_path(new_text)):
		window.navigate(new_text, true)
	$Edit.hide()
	$Breadcrumbs.show()
	$Breadcrumbs.get_children()[-1].set_pressed_no_signal(true)


func _on_resized() -> void:
	scroll_horizontal = 999
