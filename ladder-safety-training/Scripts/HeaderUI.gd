extends Control

@onready var menu_button: MenuButton = %SlideMenu
var shell: Node

@onready var previous_button: Button = $BottomPanel/HBoxContainer/PreviousButton
@onready var next_button: Button = $BottomPanel/HBoxContainer/NextButton


func _ready() -> void:
	# Get a reference to your shell; if you put the header under the shell:
	shell = get_tree().get_first_node_in_group("CourseShell")  # or get_parent() or: get_tree().get_first_node_in_group("CourseShell")
	var popup := menu_button.get_popup()
	popup.id_pressed.connect(_on_slide_chosen)

	# Build once on ready
	_build_menu()

	# Keep UI in sync with shell changes
	if shell.has_signal("slide_changed"):
		shell.slide_changed.connect(func(_i:int): _refresh_menu_state())
	if shell.has_signal("progress_changed"):
		shell.progress_changed.connect(func(_u:int, _i:int): _refresh_menu_state())
		
	# Connect navigation button signals
	if previous_button:
		previous_button.pressed.connect(_on_previous_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)

func _build_menu() -> void:
	var popup := menu_button.get_popup()
	popup.clear()
	var count: int = shell.slides.size()
	for i in count:
		var title:String= shell.get_slide_title(i)
		popup.add_item("%02d. %s" % [i + 1, title], i)
	_refresh_menu_state()

func _refresh_menu_state() -> void:
	var popup := menu_button.get_popup()
	var item_count := popup.get_item_count()
	for row in item_count:
		var idx := popup.get_item_id(row)
		# Optional gating based on unlocked_max_index; remove if you want free navigation
		var gate_ok :int = (idx <= shell.unlocked_max_index)
		popup.set_item_disabled(row, not gate_ok)
		# Show which slide is active
		popup.set_item_as_radio_checkable(row, true)
		popup.set_item_checked(row, idx == shell.index)
	_check_navigation_button()

func _on_slide_chosen(id: int) -> void:
	shell.go_to(id)

func _on_previous_pressed() -> void:
	if shell:
		shell.go_prev()

func _on_next_pressed() -> void:
	if shell:
		shell.go_next()

# Attempt to retrieve the current slides next_button or previous_property settings to turn on/off the HeaderUI next or previous button.
func _check_navigation_button():
	if not shell or not is_instance_valid(shell.current_slide):
		# Hide both buttons if no valid slide
		next_button.visible = false
		previous_button.visible = false
		return
		
	var current_slide = shell.current_slide
	
	# Check next button visibility
	var show_next = true
	if current_slide.has_method("get") and current_slide.get("next_button") != null:
		show_next = current_slide.get("next_button")
	else:
		# Default behavior - show next button if not on last slide
		show_next = (shell.index < shell.slides.size() - 1)
	
	next_button.visible = show_next
	
	# Check previous button visibility
	var show_previous = true
	if current_slide.has_method("get") and current_slide.get("previous_button") != null:
		show_previous = current_slide.get("previous_button")
	else:
		# Default behavior - show previous button if not on first slide
		show_previous = (shell.index > 0)
	
	previous_button.visible = show_previous
	
	# Debug output
	print("Slide: ", current_slide.name, " - Next: ", show_next, " Previous: ", show_previous)
	
func _lose_focus():
	get_viewport().gui_release_focus()
