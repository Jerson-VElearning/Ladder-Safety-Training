extends Area2D

@export var hover_scale: Vector2 = Vector2(1.2, 1.2)  # Scale multiplier on hover
@export var animation_duration: float = 0.2  # Duration of scale animation
@export var ease_type: Tween.EaseType = Tween.EASE_OUT  # Easing for smooth animation
@export var trans_type: Tween.TransitionType = Tween.TRANS_QUAD  # Transition type

@export var target_panel :Panel

var original_scale: Vector2
var tween: Tween

func _ready() -> void:
	# Store the original scale
	original_scale = scale
	
	# Connect mouse enter/exit signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_scale_to(hover_scale)
	print("mouse entered")

func _on_mouse_exited() -> void:
	_scale_to(original_scale)
	print("mouse exited")

func _scale_to(target_scale: Vector2) -> void:
	# Kill any existing tween
	if tween:
		tween.kill()
	
	# Create new tween
	tween = create_tween()
	tween.set_ease(ease_type)
	tween.set_trans(trans_type)
	tween.tween_property(self, "scale", target_scale, animation_duration)

func _exit_tree() -> void:
	# Clean up tween when node is removed
	if tween:
		tween.kill()


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# Check if it's a left mouse button press
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Hide all nodes in the "Panel" group
		var panel_group = get_tree().get_nodes_in_group("Panels")
		for panel in panel_group:
			panel.visible = false
			print("Hidden panel: ", panel.name)
		
		if target_panel and target_panel.has_method("text_fade_up"):
			# Call the text_fade_up method on the target panel
			target_panel.text_fade_up()
			print(target_panel)
		else:
			print("No target panel assigned or missing text_fade_up method!")
