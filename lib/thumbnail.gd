extends Node
class_name Thumbnail

static func get_icon_for(path: String, theme: Control) -> Texture2D:
	path = System.abs_path(path)
	var is_folder = DirAccess.dir_exists_absolute(path)
	if is_folder:
		var dir = DirAccess.open(path)
		var icon_name = ".icon.svg"
		if dir.file_exists(icon_name):
			return await load_image(path+"/"+icon_name)
		return theme.get_theme_icon("folder", "Icons")
	else:
		match System.get_file_type(path):
			"picture":
				return theme.get_theme_icon("picture", "Icons")
			"text":
				return theme.get_theme_icon("text", "Icons")
			_:
				return theme.get_theme_icon("file", "Icons")

static func load_image(path: String):
	#var thread = Thread.new()
	#thread.start(load_image)
	#await thread.wait_to_finish()
	path = System.abs_path(path)
	var img = Image.load_from_file(path)
	return ImageTexture.create_from_image(img)
