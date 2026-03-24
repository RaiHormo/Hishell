extends FlowContainer

var window: BaseWindow
@export var icon_size: int = 64

func update_layout():
	for i: FileSlot in get_children():
		i.icon_size = icon_size

func link_window(with: BaseWindow):
	window = with

func icon_size_slider(value: float) -> void:
	icon_size = int(value)
	window.send("update_layout")
	if value != 64:
		Meta.set_folder_meta(window.location, "GridSize", "LAYOUT", value)
