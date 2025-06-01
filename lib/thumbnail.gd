extends Node
class_name Thumbnail

static func get_icon_for(path: String, theme: Control) -> Texture2D:
	var is_folder = DirAccess.dir_exists_absolute(path)
	if is_folder:
		return theme.get_theme_icon("folder", "Icons")
	else:
		var filename: String = path.split("/", false)[-1]
		var extension: String = filename.split(".", false)[-1].to_lower()
		match extension:
			"png", "jpg", "jpeg", "svg", "avif", "webp":
				return theme.get_theme_icon("image", "Icons")
			"txt", "md", "cfg", "html", "log", "sh", "ini", "csv", "tres":
				return theme.get_theme_icon("text", "Icons")
			_:
				return theme.get_theme_icon("file", "Icons")

func load_image_preview(path: String):
	var thread = Thread.new()
	thread.start(load_image_preview)
	await thread.wait_to_finish()
	var img = Image.load_from_file(path)
	return ImageTexture.create_from_image(img)
