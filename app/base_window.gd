extends Control
class_name BaseWindow

@export var location:= "user://":
	set(val):
		location = System.rel_path(val)
		if active:
			if has_node("%PathBar"): %PathBar.show_path(location)
			if state == STATE_WINDOWED:
				resize(get_optimal_size())
			location_changed(val)
enum {STATE_WINDOWED, STATE_DRAG, STATE_MAXIMIZED, STATE_LOADING, STATE_RESIZE}
var state:= STATE_LOADING
var title: String
var origin: Vector2
var open_pos: Vector2
var parent: Viewport
@export var animation_speed:= 0.3
@export var draggable = true
var use_windows:= true
var prev_size: Vector2
@onready var background = $Background
var drag_mouse_pos: Vector2
var active := false
signal window_ready

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
	theme = System.theme
	set_tweened("modulate", Color.WHITE)
	set_tweened("scale", Vector2.ONE)
	var timer = get_tree().create_timer(animation_speed)
	if is_root_window(): draggable = false
	if draggable:
		drag_mouse_pos = size/2
		while Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			position = get_viewport().get_mouse_position() - size/2
			await System.wait()
		open_pos = get_viewport().get_mouse_position()
		end_drag()
	while timer.time_left != 0: await System.wait()
	open()

func open():
	setup_window()

func location_changed(_path: String):
	pass

func link_components(node: Node = self):
	for i in node.get_children():
		if i.has_method("link_window"):
			i.link_window(self)
		link_components(i)

func setup_window():
	prev_size = get_optimal_size()
	if not is_root_window():
		await resize(prev_size, open_pos - prev_size/2)
		state = STATE_WINDOWED
	else: state = STATE_MAXIMIZED
	$Splash.hide()
	$Content.show()
	#wrap_controls = true
	_update_layout()
	parent.connect("size_changed", _on_size_changed)
	link_components()
	active = true
	window_ready.emit()
	

func _process(_delta: float) -> void:
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
		STATE_RESIZE:
			$Content.mouse_default_cursor_shape = CursorShape.CURSOR_FDIAGSIZE
			size = get_viewport().get_mouse_position()-position
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				state = STATE_WINDOWED
				$Content.mouse_default_cursor_shape = CursorShape.CURSOR_ARROW
	
func limit_pos(pos: Vector2, siz:Vector2 = size):
	pos.x = clamp(pos.x, 0, get_viewport_rect().size.x-siz.x)
	pos.y = clamp(pos.y, 0, get_viewport_rect().size.y-siz.y)
	return pos

func set_tweened(property: StringName, value: Variant) -> bool:
	match property:
		"size", "position", "scale", "modulate":
			var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			t.tween_property(self, String(property), value, animation_speed)
			await t.finished
			return true
	return false

func enter_drag(mouse_pos: Vector2):
	$Content.mouse_default_cursor_shape = Control.CURSOR_CAN_DROP
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
	_update_layout()

func _update_layout():
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
	#decorations.show()
	update_layout()
	if has_node("%Grid"):
		%Grid.update()

func update_layout():
	pass

func message(type: String, value: Variant):
	call(type, value)

func navigate(path: String, force_local:= false):
	path = System.abs_path(path)
	var foc = parent.gui_get_focus_owner()
	if use_windows and not force_local:
		System.launch(path, foc.global_position + foc.size/2, self)
	else:
		location = path

func window_control(msg: String):
	match msg:
		"maximize":
			prev_size = size
			state = STATE_MAXIMIZED
			var tree = get_tree()
			get_parent().remove_child(self)
			tree.root.add_child(self)
			background.hide()
			_update_layout()
		"unmaximize":
			if not is_root_window():
				get_tree().root.remove_child(self)
				System.root_window().add_child(self)
			state = STATE_WINDOWED
			background.show()
			resize(prev_size, center_position())
			_update_layout()
		"maximize_toggle":
			if STATE_MAXIMIZED: message("window_control", "unmaximize")
			else: message("window_control", "maximize")
		"close": close()

func create(type: String):
	match type:
		"folder":
			var dir = DirAccess.open(location)
			dir.make_dir("New Folder")

func close() -> void:
	set_tweened("modulate", Color.TRANSPARENT)
	await resize(Vector2(200,200), origin)
	if is_root_window():
		get_tree().quit()
	queue_free()

func resize(siz: Vector2, pos: Vector2 = position):
	pos = limit_pos(pos, siz)
	set_tweened("size", siz)
	set_tweened("position", pos)
	await System.wait(animation_speed)

func _icon_size_slider(value: float) -> void:
	%Grid.icon_size = int(value)
	_update_layout()

func _opacity_slider(value: float) -> void:
	background.modulate.a = value/100

func is_root_window() -> bool:
	if self == System.root_window(): return true
	else: return false

func center_position():
	return parent.get_visible_rect().get_center() - Vector2(prev_size/2)

func get_optimal_size():
	var siz:= Vector2i(400, 300)
	return siz

func _on_content_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and state == STATE_WINDOWED:
			enter_drag(get_local_mouse_position())
			$Content.grab_focus()
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and state == STATE_WINDOWED:
			state = STATE_RESIZE
