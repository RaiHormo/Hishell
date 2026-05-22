extends BaseWindow
class_name DialogWindow
signal awnsered
var awnser := 0

func _ready() -> void:
	resize(Vector2(400, 200), center_position()/2)
	$Content.show()
	$Splash.hide()
	location = System.root
	state = STATE_WINDOWED

func show_options(options: Array[String] = ["OK"]) -> void:
	if not options.is_empty():
		%OK.show()
		%OK.text = options[0]
	else: %OK.hide()
	
	if options.size() > 1:
		%CANCEL.show()
		%CANCEL.text = options[1]
	else: %CANCEL.hide()

func _on_ok_pressed() -> void:
	awnser = 0
	awnsered.emit()
	close()

func wait_for_awnser() -> int:
	await awnsered
	return awnser


func _on_cancel_pressed() -> void:
	awnser = 1
	close()
	awnsered.emit()
