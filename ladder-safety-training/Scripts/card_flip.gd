extends Control

@export var animation: AnimationPlayer
@export var movement_offset: Vector2 = Vector2(0, -5)  # Vertical offset on hover (negative = up)
@export var animation_duration: float = 0.2  # Duration of movement animation
@export var ease_type: Tween.EaseType = Tween.EASE_OUT  # Easing for smooth animation
@export var trans_type: Tween.TransitionType = Tween.TRANS_QUAD  # Transition type

var flipped: bool = false

var original_pos: Vector2
var tween: Tween

func _ready() -> void:
	# Store the original position
	original_pos = position
	
	# Connect mouse enter/exit signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_move_to(original_pos + movement_offset)
	print("mouse entered")

func _on_mouse_exited() -> void:
	_move_to(original_pos)
	print("mouse exited")

func _move_to(target_position: Vector2) -> void:
	# Kill any existing tween
	if tween:
		tween.kill()
	
	# Create new tween
	tween = create_tween()
	tween.set_ease(ease_type)
	tween.set_trans(trans_type)
	tween.tween_property(self, "position", target_position, animation_duration)


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Card Flip Animation Started")
		if !flipped:
			animation.play("FlipAnimation")
			flipped = true
		else:
			animation.play_backwards("FlipAnimation")
			flipped = false
		


func _on_area_2d_mouse_entered() -> void:
	print("Mouse Over Card")
