extends Control
class_name Component

var window: BaseWindow

func link_window(with: BaseWindow):
	window = with

func send(message: String, value: Variant = null):
	window.send(message, value)

func send_value(value: Variant, message: String):
	window.send(message, value)

func recieve(message: String, value: Variant = null) -> bool:
	if has_method(message):
		call(message, value)
		return true
	else: return false
