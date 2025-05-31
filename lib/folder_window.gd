extends Control
class_name FolderWindow

@export var location:= "user://":
	set(val):
		location = System.abs_path(val)
		parse_folder()
		if state == STATE_WINDOWED:
			resize(get_optimal_size())
			print("mio")
enum {STATE_WINDOWED, STATE_DRAG, STATE_MAXIMIZED, STATE_LOADING}
var state:= STATE_LOADING
var title: String
var origin: Vector2
var open_pos: Vector2
var parent: Viewport
@export var animation_speed:= 0.3
@export var draggable = true
var use_windows:= true
var prev_size: Vector2
var files: PackedStringArray
var folders: PackedStringArray
@onready var decorations: Control = $Decorations
@onready var background = $Background
@onready var grid = %Grid
var grid_icon_size:= 64
var drag_mouse_pos: Vector2

func _ready() -> void:
	size = Vector2(200, 200)
	if origin != Vector2.ZERO:
		position = origin - Vector2(100, 100)
	else: position = center_position()
	if open_pos == Vector2.ZERO: open_pos = origin
	#wrap_controls = false
	#borderless = true
	scale = Vector2(0.5, 0.5)
	modulate = Color.TRANSPARENT
	$Content.hide()
	$Splash.show()
	set_tweened("modulate", Color.WHITE)
	set_tweened("scale", Vector2.ONE)
	if is_root_window(): draggable = false
	if draggable:
		drag_mouse_pos = size/2
		while Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			position = get_viewport().get_mouse_position() - size/2
			await System.wait()
		open_pos = get_viewport().get_mouse_position()
		end_drag()
	open()

func open():
	print("as")
	await parse_folder()
	#borderless = false
	prev_size = get_optimal_size()
	if not is_root_window():
		await resize(prev_size, open_pos - prev_size/2)
		state = STATE_WINDOWED
	else: _on_maximize_pressed()
	$Splash.hide()
	$Content.show()
	#wrap_controls = true
	update_layoyt()
	parent.connect("size_changed", _on_size_changed)
	%PathBar.window = self
	%ViewMenu.window = self
	%ViewMenu.do_connections()
	

func _process(_delta: float) -> void:
	#var i = 0
	#while decorations.get_child_count() < get_embedded_subwindows().size():
		#var dec = decorations.get_child(0).duplicate()
		#decorations.add_child(dec)
	#for dec in decorations.get_children():
		#dec.hide()
	#for window in get_embedded_subwindows():
		#var dec = decorations.get_child(i)
		#dec.position = window.position
		#dec.size = window.size
		#dec.show()
		#i += 1
	match state:
		STATE_LOADING:
			pivot_offset = size/2
		STATE_WINDOWED:
			pass
		STATE_DRAG:
			pivot_offset = get_local_mouse_position()
			position = parent.get_mouse_position() - drag_mouse_pos
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				end_drag()
	
func limit_pos(pos: Vector2, siz:Vector2 = size):
	pos.x = clamp(pos.x, 0, get_viewport_rect().size.x-siz.x)
	pos.y = clamp(pos.y, 0, get_viewport_rect().size.y-siz.y)
	return pos

func set_tweened(property: StringName, value: Variant) -> bool:
	match property:
		"size", "position", "scale", "modulate":
			var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			t.tween_property(self, String(property), value, animation_speed)
			await t.finished
			return true
	return false

func enter_drag(mouse_pos: Vector2):
	$Content.mouse_default_cursor_shape = Control.CURSOR_DRAG
	set_tweened("scale", Vector2(0.9, 0.9))
	state = STATE_DRAG
	drag_mouse_pos = mouse_pos
	move_to_front()

func end_drag():
	state = STATE_WINDOWED
	$Content.mouse_default_cursor_shape = Control.CURSOR_ARROW
	set_tweened("scale", Vector2.ONE)
	set_tweened("position", limit_pos(position))

func _on_size_changed() -> void:
	if is_instance_valid(grid) and grid.visible:
		update_layoyt()

func update_layoyt():
	if not is_instance_valid(grid): return
	for i: FileSlot in grid.get_children():
		i.icon_size = grid_icon_size
	if state == STATE_MAXIMIZED:
		resize(parent.get_visible_rect().size, Vector2i(0,0))
		use_windows = true
	else:
		use_windows = false
	if state == STATE_WINDOWED:
		prev_size = size
	if position.x < 0:
		position.x = max(position.x, 0)
	if position.y < 0:
		position.y = max(position.y, 48)
	decorations.show()
	if is_root_window():
		$Wallpaper.show()
		$Background.hide()
		$Blur.hide()
	else:
		$Background.show()
		$Wallpaper.hide()
		$Blur.show()

func parse_folder():
	if not is_instance_valid(grid): return
	if location[-1] != '/': location += '/'
	if not DirAccess.dir_exists_absolute(location):
		grid.hide()
		title = "404"
		push_error("Folder "+location+ " wasn't found")
		return
	var location_parts = location.split("/", false)
	title = location_parts[-1] if not (location_parts.is_empty() or location_parts[-1].is_empty()) else location
	name = title
	%PathBar.show_path(location)
	files = DirAccess.get_files_at(location).duplicate()
	folders = DirAccess.get_directories_at(location).duplicate()
	if DirAccess.get_open_error():
		title = "Can't access this folder"
		return
	grid.show()
	while grid.get_child_count() < files.size() + folders.size():
		var slot = preload("res://lib/FileSlot.tscn").instantiate()
		grid.add_child(slot)
		slot.window = self
	var i := 0
	for slot in grid.get_children():
		slot.set_to("")
	for folder in folders:
		var slot = grid.get_child(i)
		slot.set_to(folder, true)
		i += 1
	for file in files:
		var slot = grid.get_child(i)
		slot.set_to(file, false)
		i += 1

func navigate(path: String, force_local:= false):
	if use_windows and not force_local:
		var foc = parent.gui_get_focus_owner()
		System.launch(path, foc.global_position + foc.size/2, self)
	else:
		if DirAccess.dir_exists_absolute(System.abs_path(path)):
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				await System.wait(animation_speed)
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					var foc = parent.gui_get_focus_owner()
					System.launch(path, get_viewport().get_mouse_position(), System.root_window())
				else:
					location = path
			else:
				location = path

func _on_close_requested() -> void:
	if is_root_window():
		get_tree().quit()
	set_tweened("modulate", Color.TRANSPARENT)
	await resize(Vector2(200,200), origin)
	queue_free()

func _on_maximize_pressed() -> void:
	match state:
		STATE_MAXIMIZED:
			if not is_root_window():
				get_tree().root.remove_child(self)
				System.root_window().add_child(self)
			state = STATE_WINDOWED
			resize(prev_size, center_position())
			update_layoyt()
		_:
			prev_size = size
			state = STATE_MAXIMIZED
			var tree = get_tree()
			get_parent().remove_child(self)
			tree.root.add_child(self)
			update_layoyt()

func resize(siz: Vector2, pos: Vector2 = position):
	pos = limit_pos(pos, siz)
	set_tweened("size", siz)
	set_tweened("position", pos)
	await System.wait(animation_speed)

func _icon_size_slider(value: float) -> void:
	grid_icon_size = int(value)
	update_layoyt()

func _opacity_slider(value: float) -> void:
	background.modulate.a = value/100

func is_root_window() -> bool:
	if self == System.root_window(): return true
	else: return false

func center_position():
	return parent.get_visible_rect().get_center() - Vector2(prev_size/2)

func get_optimal_size():
	var siz:= Vector2i(400, 300)
	var number_of_files = folders.size() + files.size()
	print(number_of_files)
	if number_of_files > 2: siz.x += 200
	if number_of_files > 4: siz.y += 100
	if number_of_files > 8: siz.y += 200; siz.x += 200;
	if number_of_files > 12: siz.y += 200
	if number_of_files > 20: siz.y += 200
	if number_of_files > 40: siz.x += 300
	prev_size = siz
	print(siz)
	if parent != null:
		siz.x = min(siz.x, parent.get_visible_rect().size.x - 20)
		siz.y = min(siz.y, parent.get_visible_rect().size.y - 50)
	return siz


func _on_content_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and state == STATE_WINDOWED:
			enter_drag(get_local_mouse_position())
