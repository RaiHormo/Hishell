extends Control
class_name BaseWindow

@export var location:= "user://":
	set(val):
		location = Filesystem.rel_path(val)
		if active:
			if has_node("%PathBar"): %PathBar.show_path(location)
			send("location_changed", val)
enum {STATE_WINDOWED, STATE_DRAG, STATE_MAXIMIZED, STATE_LOADING, STATE_RESIZE}
var state:= STATE_LOADING
var title: String:
	set(x):
		title = x
var origin: Vector2
var open_pos: Vector2
var viewport: Viewport
var components: Dictionary[String, Node]
var parent: BaseWindow = null
@export var animation_speed:= 0.3
@export var draggable = true
var use_windows:= true
var prev_size: Vector2 = Vector2(450, 300):
	set(x):
		prev_size = x
@onready var splash: Control  = $Splash
@onready var content: Control = $Content
@onready var background: Control  = $Blur
var drag_mouse_pos: Vector2
var active := false
var resizable:= 0
var config: ConfigFile
signal window_ready

const resize_margin = 24

func _ready() -> void:
	hide()
	set_deferred("size", Vector2(200, 200))
	if origin != Vector2.ZERO:
		position = origin - Vector2(100, 100)
	else: position = center_position()
	if open_pos == Vector2.ZERO: open_pos = origin
	#wrap_controls = false
	#borderless = true
	scale = Vector2(0.5, 0.5)
	modulate = Color.TRANSPARENT
	content.hide()
	title = Meta.folder_title(location)
	name = title
	splash.show()
	if viewport != null:
		focus_entered.connect(focus_window)
	show()
	if splash.has_node("Icon"):
		splash.get_node("Icon").texture = await Thumbnail.get_icon_for(location, self)
		if splash.has_node("Icon/Label"):
			splash.get_node("Icon/Label").text = title
	theme = ConfigManager.theme
	set_tweened("modulate", Color.WHITE)
	set_tweened("scale", Vector2.ONE)
	var timer = get_tree().create_timer(animation_speed)
	if draggable:
		drag_mouse_pos = size/2
		var parent_pos = Vector2.ZERO
		if parent != null:
			parent_pos = parent.position
		while Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			position = get_viewport().get_mouse_position() - size/2 - parent_pos
			check_dragndrop(position)
			await System.wait()
		open_pos = get_viewport().get_mouse_position()
		end_drag()
	while timer.time_left != 0: await System.wait()
	state = STATE_LOADING
	send("open")

func send(message: String, value: Variant = null, target: String = ""):
	if has_method(message):
		if value != null: await call(message, value)
		else: await call(message)
	if not target.is_empty() and components.has(target): 
		if value != null: await components.get(target).call(message, value)
		else: await components.get(target).call(message)
	else:
		for i: String in components.keys():
			var component = components.get(i)
			if not is_instance_valid(component) or component == null: continue
			if component.has_method(message):
				if value != null: await component.call(message, value)
				else: await component.call(message)

func open():
	create_content()
	setup_window()
	if config.get_value("LAUNCH", "Maximized", false):
		send("window_control", "maximize")

func link_components(node: Node = self):
	for i in node.get_children():
		if  i is BaseWindow: continue
		if i.has_method("link_window"):
			i.link_window(self)
			components.set(i.name, i)
		link_components(i)

func create_config(type: String):
	if not Filesystem.exists(ConfigManager.config_path+"layouts/default.cfg"):
		System.dialog("Something went really wrong, default config not found.", "Error")
		close()
		return
	config = ConfigManager.get_config_file("layouts/default.cfg")
	ConfigManager.merge_config(ConfigManager.get_config_file("layouts/"+type+".cfg"), config)
	if config == null: 
		close()
		return
	if not config.get_value("META", "IgnoreMeta", false):
		var meta = Meta.get_folder_config(location)
		if meta != null:
			ConfigManager.merge_config(meta, config)

func create_content(type := Filesystem.get_file_type(location)):
	if type == "unknown":
		System.dialog("No handler for this filetype exists")
		close()
		return
	if type == "invalid":
		System.dialog("Directory isn't valid: ", location)
		close()
		return
	create_config(type)
	for container in config.get_section_keys("LAYOUT"):
		var container_node = get_node_or_null("%"+container)
		if container_node != null:
			var hbox: BoxContainer = container_node.get_child(0)
			for i in hbox.get_children():
				i.queue_free()
			var values: Array = config.get_value("LAYOUT", container)
			for value: String in values:
				if not value.ends_with(".tscn"): value += ".tscn"
				var component: Control
				if value.begins_with("./"):
					var path = Filesystem.abs_path(value.replace("./", location))
					if Filesystem.exists(path):
						var packed := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
						component = packed.instantiate()
						var script_path = path.replace(".tscn", ".gd")
						if Filesystem.is_file(script_path):
							var script: Script = ResourceLoader.load(script_path, "Script", ResourceLoader.CACHE_MODE_IGNORE)
							var error = script.reload()
							if error == Error.OK:
								component.set_script(script)
							else: System.dialog(error_string(error))
					else: System.dialog("Non existant component specified: "+ path, "Error")
				else:
					if ResourceLoader.exists("res://"+value):
						component = (load("res://"+value) as PackedScene).instantiate()
				if component == null:
					System.dialog("Non existant component specified: "+ value, "Error")
				else: hbox.add_child(component)


func setup_window():
	link_components()
	await send("init")
	if state == STATE_LOADING:
		resize(prev_size, open_pos - prev_size/2)
		state = STATE_WINDOWED
	splash.hide()
	content.show()
	#wrap_controls = true
	send("update_layout")
	active = true
	window_ready.emit()


func _process(_delta: float) -> void:
	match state:
		STATE_LOADING:
			pivot_offset = size/2
		STATE_WINDOWED:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): return
			var cursor_pos = get_viewport().get_mouse_position() - position
			if (
				(cursor_pos.x > size.x - resize_margin and cursor_pos.x < size.x) 
				and (cursor_pos.y > size.y - resize_margin and cursor_pos.y < size.y)
			):
				resizable = 3
				content.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
			elif cursor_pos.x > size.x - resize_margin and cursor_pos.x < size.x:
				content.mouse_default_cursor_shape = Control.CURSOR_HSIZE
				resizable = 1
			elif cursor_pos.y > size.y - resize_margin and cursor_pos.y < size.y:
				content.mouse_default_cursor_shape = Control.CURSOR_VSIZE
				resizable = 2
			elif resizable > 0: 
				content.mouse_default_cursor_shape = Control.CURSOR_ARROW
				resizable = 0
			if resizable > 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				state = STATE_RESIZE
		STATE_DRAG:
			pivot_offset = get_local_mouse_position()
			var parent_pos:= Vector2.ZERO
			if parent != null: parent_pos = parent.position
			position = viewport.get_mouse_position() - drag_mouse_pos - parent_pos
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				end_drag()
		STATE_RESIZE:
			match resizable:
				1:
					size.x = get_viewport().get_mouse_position().x-position.x
				2:
					size.y = get_viewport().get_mouse_position().y-position.y
				_:
					$Content.mouse_default_cursor_shape = CursorShape.CURSOR_FDIAGSIZE
					size = get_viewport().get_mouse_position()-position
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				if state == STATE_RESIZE:
					send("size_changed")
				state = STATE_WINDOWED
				$Content.mouse_default_cursor_shape = CursorShape.CURSOR_ARROW

func limit_pos(pos: Vector2, siz:Vector2 = size):
	var parent_pos := Vector2.ZERO
	if parent != null:
		parent_pos = parent.position
	pos.x = clamp(pos.x, -parent_pos.x, get_viewport_rect().size.x-siz.x -parent_pos.x)
	pos.y = clamp(pos.y, -parent_pos.y, get_viewport_rect().size.y-siz.y -parent_pos.y)
	return pos

func set_tweened(property: StringName, value: Variant, node: Node = self) -> void:
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(node, NodePath(property), value, animation_speed)
	await t.finished

func enter_drag(mouse_pos: Vector2):
	$Content.mouse_default_cursor_shape = Control.CURSOR_CAN_DROP
	set_tweened("scale", Vector2(0.9, 0.9))
	state = STATE_DRAG
	drag_mouse_pos = mouse_pos
	focus_window()

func end_drag():
	state = STATE_WINDOWED
	$Content.mouse_default_cursor_shape = Control.CURSOR_ARROW
	set_tweened("scale", Vector2.ONE)
	set_tweened("position", limit_pos(position))

func size_changed() -> void:
	send("update_layout")

func check_dragndrop(pos := position):
	for window: BaseWindow in System.windows:
		if window.get_rect().has_point(pos):
			print(window.title)
			break

func update_layout():
	if state == STATE_MAXIMIZED:
		resize(viewport.get_visible_rect().size, Vector2i(0,0))
		use_windows = true
		draggable = false
		#background.hide()
	else:
		use_windows = false
		draggable = true
		#background.show()
	if position.x < 0:
		position.x = max(position.x, 0)
	if position.y < 0:
		position.y = max(position.y, 48)
	#decorations.show()
	
	send("update")


func navigate(path: String, type: String = "Auto", foc: Node = null):
	if type == "Auto":
		type = config.get_value("NAVIGATION", "NavigationType", "Auto")
		if type == "Auto" and state == STATE_MAXIMIZED:
			type = "Window"
	path = Filesystem.rel_path(path)
	if foc == null:
		foc = viewport.gui_get_focus_owner()
	match type:
		"InPlace":
			navigate_in_place(path)
			return 0
		"Window":
			if foc.has_method("fade"): foc.fade()
			await System.launch(Filesystem.abs_path(path), foc.global_position + foc.size/2)
			return 1
		_:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				await System.wait(animation_speed/2)
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					if foc.has_method("fade"): foc.fade()
					await System.launch(Filesystem.abs_path(path), get_viewport().get_mouse_position())
					return 1
				else:
					navigate_in_place(path)
					return 0
			else:
				navigate_in_place(path)
				return 0


func navigate_in_place(path: String):
	if Filesystem.get_file_type(location) != Filesystem.get_file_type(path):
		for i in components.duplicate():
			components.erase(i)
		create_content(Filesystem.get_file_type(path))
		link_components()
		await get_tree().process_frame
		cleanup_components()
	location = path
	send.call_deferred("open")

func cleanup_components():
	for i in components.duplicate():
			if not is_instance_valid(components.get(i)) or components.get(i) == null:
				components.erase(i)

func window_control(msg: String):
	match msg:
		"maximize":
			prev_size = size
			state = STATE_MAXIMIZED
			draggable = false
			#var tree = get_tree()
			#get_parent().remove_child(self)
			#tree.root.add_child(self)
			send("update_layout")
		"unmaximize":
			#if not is_root_window():
				#get_tree().root.remove_child(self)
				#System.root_window().add_child(self)
			state = STATE_WINDOWED
			resize(prev_size, center_position())
			send("update_layout")
		"maximize_toggle":
			if state == STATE_MAXIMIZED: send("window_control", "unmaximize")
			else: send("window_control", "maximize")
		"close": close()

func close() -> void:
	await send("save")
	cleanup_components()
	set_tweened("modulate", Color.TRANSPARENT)
	await resize(Vector2(200,200), origin)
	System.windows.erase(self)
	if is_root_window():
		get_tree().quit()
	queue_free()

func _exit_tree() -> void:
	System.windows.erase(self)

func resize(siz: Vector2, pos: Vector2 = position):
	pos = limit_pos(pos, siz)
	set_tweened("size", siz)
	set_tweened("position", pos)
	await System.wait(animation_speed)
	send("size_changed")

func opacity_slider(value: float) -> void:
	background.modulate.a = value/100

func is_root_window() -> bool:
	return parent == null

func center_position():
	return viewport.get_visible_rect().get_center() - Vector2(prev_size/2)

func _on_content_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and state == STATE_WINDOWED:
			focus_window()
			if resizable > 0:
				state = STATE_RESIZE
			else:
				enter_drag(get_local_mouse_position())
			$Content.grab_focus()
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and state == STATE_WINDOWED:
			state = STATE_RESIZE

func focus_window():
	System.focused_window = self
	move_to_front()
	System.windows.erase(self)
	System.windows.push_front(self)
	if parent != null:
		parent.move_child(self, -1)

func add_prefix(prefix: String) -> void:
	var prev = Filesystem.path_prefix(location, true)
	navigate(prefix + "://" + location.replace(prev, ""))
