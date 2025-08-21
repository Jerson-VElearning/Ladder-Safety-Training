#@tool
extends Control

#Signals for the menu
signal slide_changed(index:int)
signal progress_changed(unlocked_max_index:int, index:int)


# Drag/drop slide scenes directly here
@export var slides: Array[PackedScene] : set = _set_slides

# Editor-only, visible in Inspector, NOT saved in the scene file (4.4+)
@export_storage var titles_preview: Array[String] = []

#Variables for the Menu
var unlocked_max_index: int = 0  # gate menu items if you want

# Runtime members
@onready var host := $SlideHost
var index: int = 0
var current_slide: Node

func _set_slides(v: Array[PackedScene]) -> void:
	slides = v
	if Engine.is_editor_hint():
		_refresh_titles_preview()

func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_titles_preview()
		return
	_show_slide(0)

func _refresh_titles_preview() -> void:
	titles_preview = _collect_titles_from_packed(slides)
	notify_property_list_changed() # Godot 4.4 name

func _show_slide(i: int) -> void:
	index = clamp(i, 0, slides.size() - 1)
	var packed: PackedScene = slides[index]
	if not packed: return

	if is_instance_valid(current_slide):
		current_slide.queue_free()
	current_slide = packed.instantiate()
	host.add_child(current_slide)

	slide_changed.emit(index)
	progress_changed.emit(unlocked_max_index, index)

func go_to(i: int) -> void:
	if i < 0 or i >= slides.size(): return
	# Gate navigation if desired (comment this out to allow free jumping)
	if i > unlocked_max_index: return
	_show_slide(i)

func go_next() -> void:
	if index < slides.size() - 1:
		_show_slide(index + 1)
	unlocked_max_index += 1
	print (unlocked_max_index)

func go_prev() -> void:
	if index > 0:
		_show_slide(index - 1)
	
	print (unlocked_max_index)

# Call this from a slide when it’s “completed” to unlock the next slide.
func mark_current_complete() -> void:
	unlocked_max_index = max(unlocked_max_index, index + 1)
	progress_changed.emit(unlocked_max_index, index)

func get_slide_title(i: int) -> String:
	if i < 0 or i >= slides.size():
		return "Untitled"
	return _get_title_from_packed(slides[i])

func _collect_titles_from_packed(arr: Array[PackedScene]) -> Array[String]:
	var out: Array[String] = []
	for p in arr:
		out.append(_get_title_from_packed(p))
	return out

# ---- Title extraction (no instancing) ----
# Tries root first, then all nodes, matching "slide_title" OR "res://...:slide_title"
func _get_title_from_packed(packed: PackedScene) -> String:
	if packed == null:
		return "Untitled"
	var state: SceneState = packed.get_state()
	if state == null:
		return _fallback_title_from_path(packed)

	# 1) Root node (index 0)
	var t := _find_export_in_node(state, 0, "slide_title")
	if t != "":
		return t

	# 2) Any node (handles export on a child)
	var node_count: int = state.get_node_count()
	for n in node_count:
		t = _find_export_in_node(state, n, "slide_title")
		if t != "":
			return t

	# 3) Filename fallback
	return _fallback_title_from_path(packed)

# Returns first non-empty string match for short_name on a given node index
func _find_export_in_node(state: SceneState, node_idx: int, short_name: String) -> String:
	var prop_count: int = state.get_node_property_count(node_idx)
	for i in prop_count:
		var name: String = state.get_node_property_name(node_idx, i)
		if name == short_name or name.ends_with(":" + short_name):
			var value: String = str(state.get_node_property_value(node_idx, i))
			if value != "":
				return value
	return ""

func _fallback_title_from_path(packed: PackedScene) -> String:
	return packed.resource_path.get_file().get_basename() if packed.resource_path != "" else "Untitled"
