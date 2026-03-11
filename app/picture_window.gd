extends BaseWindow
class_name PictureWindow

func open():
	var image = await Thumbnail.load_image(location)
	%Picture.texture = image
	setup_window()

func _on_size_changed() -> void:
	var image_size = %Picture.texture.get_size()
	var ratio = image_size.x / image_size.y
	size.x = size.y*ratio
	update_layoyt()
