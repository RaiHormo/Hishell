extends GridContainer
class_name FileSlot

var window: FolderWindow
var filename: String
@onready var icon: TextureRect = $Icon
@onready var label: Label = $Label
@onready var button: Button = $Icon/Button
var thread: Thread = null


var is_folder:= false
var icon_size:= 64:
	set(val):
		icon.custom_minimum_size = Vector2(val, val)
		icon_size = val
		update_layout.call_deferred()
	get:
		return int(icon.custom_minimum_size.x)

func set_to(new_name: String, path: String = ""):
	if path != "":
		icon.texture = Thumbnail.get_icon_for(path, self)
	else: icon.texture = null
	filename = new_name
	if filename == "":
		filename = "<empty>"
	name = filename
	if "<empty>" in name:
		label.text = ""
	else:
		label.text = filename
	update_layout.call_deferred()


func _ready() -> void:
	set_to("")

func update_layout():
	if label.text == "":
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = null
	else:
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		
	if icon_size < 40:
		columns = 3
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		columns = 1
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = icon_size * 2.0 if columns == 1 else 0.0
	await System.wait()
	button.position = Vector2(-2, -2)
	button.size = size + Vector2(4, 4)


func _on_button_pressed() -> void:
	window.navigate(window.location+filename)

func _exit_tree():
	if thread != null and thread.is_started():
		thread.wait_to_finish()
