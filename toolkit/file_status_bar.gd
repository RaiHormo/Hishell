extends Component

@export var lines_text: Label
@export var size_text: Label
@export var words_text: Label

func init():
	set_from_file()

func update():
	if window.components.has("TextEditor") and is_instance_valid(window.components.has("TextEditor")):
		var text: String = window.components.get("TextEditor").current_text
		set_from_string(text)
		return
	else: set_from_file()

func set_from_file():
	if Filesystem.is_file(window.location):
		var file = Filesystem.open_file(window.location, FileAccess.READ)
		set_from_string(file.get_as_text())

func set_from_string(text: String):
	var lines = text.split('\n')
	lines_text.text = "Lines: " + str(lines.size())
	var file_size: int = text.length()
	size_text.text = "Size: "+ Utils.format_bytes(file_size)
	var words: int = text.split(" ", false).size()
	words_text.text = "Words: " + str(words)
	


func _on_resized() -> void:
	print(size)
	if size.x < 350: 
		words_text.hide()
		size_text.hide()
	else: 
		words_text.show()
		size_text.show()
