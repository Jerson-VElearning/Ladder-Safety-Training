extends Area2D

@export var target_object: Control



func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# Check if it's a left mouse button press
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		target_object.visible = false
