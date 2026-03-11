extends Button

var window: BaseWindow

func link_window(with: FolderWindow):
	window = with

func close():
	window.message("window_control", "close")
