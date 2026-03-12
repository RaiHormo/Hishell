extends Button
class_name ButtonComponent

var window: BaseWindow

func link_window(with: BaseWindow):
	window = with

func send(message: String, value: Variant):
	window.message(message, value)

func send_value(value: Variant, message: String):
	window.message(message, value)
