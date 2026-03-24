extends Control

@export var spin = 0.1

func _ready() -> void:
	$TextureRect.texture = Thumbnail.load_image(System.current_path(self)+"banana.webp")

func _physics_process(_delta: float) -> void:
	$TextureRect.rotation += spin
