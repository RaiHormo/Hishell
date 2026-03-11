extends FlowContainer

var window: FolderWindow
@export var icon_size: int = 64

func update():
	for i: FileSlot in get_children():
		i.icon_size = icon_size


func link_window(with: FolderWindow):
	window = with
