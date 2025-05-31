extends Button

var window: FolderWindow
@onready var dropdown: PanelContainer = $Dropdown


func _ready() -> void:
	dropdown.hide()

func do_connections():
	dropdown.get_node("List/Maximize").connect("pressed", window._on_maximize_pressed)
	dropdown.get_node("List/IconSize").connect("value_changed", window._icon_size_slider)

func toggle(toggled_on: bool) -> void:
	if toggled_on:
		dropdown.reparent(get_tree().root, true)
		dropdown.show()
		dropdown.global_position.y = global_position.y + size.y
		dropdown.global_position.x = global_position.x -dropdown.size.x + size.x
	else:
		dropdown.reparent(self, true)
		dropdown.hide()



func _on_focus_exited() -> void:
	while Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): await System.wait()
	button_pressed = false
	toggle(false)
