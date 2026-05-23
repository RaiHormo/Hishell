extends PopupMenu

enum {
	OPEN,
	COPY, CUT, DUPLICATE, LINK,
	TRASH
}

var location: String
var window: BaseWindow

func draw_menu(for_location: String):
	location = for_location
	var type := Filesystem.get_file_type(location)
	if type == "invalid": return
	clear()
	
	# Open
	if type != "unknown":
		add_item("Open", OPEN, KEY_ENTER)
	# Edit
	add_separator("Edit")
	add_item("Copy", COPY, (KEY_MASK_CMD_OR_CTRL | KEY_C) as Key)
	add_item("Cut", CUT, (KEY_MASK_CMD_OR_CTRL | KEY_X) as Key)
	add_item("Duplicate", DUPLICATE, (KEY_MASK_CMD_OR_CTRL | KEY_D) as Key)
	add_item("Create Link", LINK, (KEY_MASK_CMD_OR_CTRL | KEY_L) as Key)
	# Move To
	add_separator("Move To")
	add_item("Trash", TRASH, (KEY_DELETE) as Key)
	
	popup(Rect2i(get_mouse_position(), size))


func _on_popup_hide() -> void:
	queue_free()


func _on_id_pressed(id: int) -> void:
	match id:
		OPEN:
			System.launch(location, get_mouse_position())
		COPY:
			Filesystem.link(location, "~/clipboard")
		CUT:
			Filesystem.move(location, "~/clipboard")
		DUPLICATE:
			Filesystem.copy(location, Filesystem.parent_folder(location), false, Filesystem.just_the_name(location) + "-copy")
		LINK:
			Filesystem.link(location, Filesystem.parent_folder(location))
		TRASH:
			Filesystem.trash(location)
	System.refresh_all()
