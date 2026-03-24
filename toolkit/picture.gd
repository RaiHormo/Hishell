extends Component

@export var picture: TextureRect

func init():
	var image = Thumbnail.load_image(window.location)
	picture.texture = image
	window.prev_size = get_optimal_size()

func size_changed():
	if size != get_optimal_size():
		send("resize", get_optimal_size())

func get_optimal_size() -> Vector2:
	var image_size = picture.texture.get_size()
	var ratio = image_size.x / image_size.y
	return Vector2(size.y*ratio, window.size.y)
