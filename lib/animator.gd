extends Node
class_name Animator

static func set_tweened(property: StringName, value: Variant, node: Node, speed = 0.3) -> void:
	var t = System.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(node, NodePath(property), value, speed)
	await t.finished

static func fade_and_hide(node: CanvasItem, speed = 0.3) -> void:
	await set_tweened("modulate:a", 0, node, speed)
	node.hide()

static func show_and_fade(node: CanvasItem, speed = 0.3) -> void:
	node.modulate.a = 0
	node.show()
	await set_tweened("modulate:a", 1, node, speed)
