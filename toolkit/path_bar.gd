extends ScrollContainer

var path_folders: PackedStringArray
var window: BaseWindow

func show_path(path: String):
	for i in $Breadcrumbs.get_children():
		if i.name != "Path0": i.queue_free()
	path = Filesystem.rel_path(path)
	path_folders = path.split("/", false)
	if not Filesystem.path_prefix(path).is_empty():
		path_folders.remove_at(0)
	var root_folders: PackedStringArray
	if window.parent is BaseWindow: 
		root_folders = window.parent.location.split("/", false)
		print(root_folders)
		if root_folders.size() >= path_folders.size(): root_folders.clear()
	for i in path_folders:
		if i.ends_with(":"): continue
		var dup: Button = $Breadcrumbs/Path0.duplicate()
		var dir: String = ""
		for j in path_folders:
			dir += j+"/"
			if i == j: break
		var text = Meta.folder_title(dir)
		if i == path_folders[-1]:
			dup.icon = await Thumbnail.get_icon_for(dir, self)
		elif not Meta.get_cutsom_icon(dir).is_empty():
			dup.icon = await Thumbnail.get_icon_for(dir, self)
			text = ""
		dup.text = text
		$Breadcrumbs.add_child(dup)
		if i in root_folders: dup.hide()
		else: dup.show()
		if dup.icon != null:
			dup.custom_minimum_size.x = text.length()*8 + 42
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
		#if path_folders[0] != System.root_name:
			#new_location += "/"
		var count = node.get_index()
		for i in path_folders:
			new_location += i+"/"
			count -= 1
			if count == 0:
				break
		var prefix = Filesystem.path_prefix(window.location)
		if not prefix.is_empty():
			new_location = prefix + "://" + new_location
		print(new_location)
		window.navigate(new_location, "InPlace")
		show_path(new_location)

func _on_edit_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		$Edit.hide()
		$Breadcrumbs.show()

func _on_edit_text_submitted(new_text: String) -> void:
	new_text = Filesystem.rel_path(new_text)
	if Filesystem.exists(new_text):
		window.navigate(new_text, "InPlace")
		$Edit.hide()
		$Breadcrumbs.show()
		$Breadcrumbs.get_children()[-1].set_pressed_no_signal(true)
	else:
		System.dialog("No File or Directory in "+ new_text, "Error")


func _on_resized() -> void:
	scroll_horizontal = 999
