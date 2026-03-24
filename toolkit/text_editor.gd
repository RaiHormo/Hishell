extends Component
class_name TextEditorComponent

@export var target_file := ""
var location: String
var current_text: String

func init():
	location = System.abs_path(window.location+target_file)
	if FileAccess.file_exists(location):
		var file : FileAccess = FileAccess.open(location, FileAccess.READ)
		$TextEdit.text = file.get_as_text()
	if window.state == window.STATE_LOADING:
		window.prev_size = Vector2(600, 500)

func save():
	if FileAccess.file_exists(location):
		var file : FileAccess = FileAccess.open(location, FileAccess.WRITE)
		file.store_string($TextEdit.text)
		file.close()


func _on_text_edit_text_changed() -> void:
	current_text = $TextEdit.text
	$UpdateTimer.start(0.5)

func _on_update_timer_timeout() -> void:
	send("update")
	send("save")
