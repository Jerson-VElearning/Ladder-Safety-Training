extends Control

@onready var menu_button: MenuButton = %SlideMenu
var shell: Node

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

func _on_slide_chosen(id: int) -> void:
	shell.go_to(id)
