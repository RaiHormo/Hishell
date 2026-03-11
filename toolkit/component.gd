extends Button
class_name ButtonComponent

var window: FolderWindow

func link_window(with: FolderWindow):
	window = with

func send(message: String, value: Variant):
	window.message(message, value)
