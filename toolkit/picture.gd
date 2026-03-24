extends Component

@export var picture: TextureRect

func init():
	var image = Thumbnail.load_image(window.location)
	picture.texture = image
	window.prev_size = Vector2(400,400)

func size_changed():
	if window.state == window.STATE_WINDOWED:
		if size != get_optimal_size():
			window.set_tweened("size", get_optimal_size())

func get_optimal_size() -> Vector2:
	var image_size = picture.texture.get_size()
	var ratio = image_size.x / image_size.y
	if size.x > size.y:
		return round(Vector2(size.y*ratio, window.size.y))
	else:
		return round(Vector2(window.size.x, size.x/ratio))
