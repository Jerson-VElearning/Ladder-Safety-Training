@tool
extends Control
# CourseShell.gd (relevant parts)

signal slide_changed(index:int)
signal progress_changed(unlocked_max_index:int, index:int)

@export var slides: Array[PackedScene] = []:
	set(value):
		slides = value
		if Engine.is_editor_hint():
			_refresh_titles_preview()
# Editor-only, visible in Inspector, not saved to the scene file
@export var titles_preview: Array[String] = []

#Progress Bar
@onready var slide_progress_bar: ProgressBar = %SlideProgressBar


@onready var host := $SlideHost

var index: int = 0
var unlocked_max_index: int = 99
var current_slide: Node
var total_length: float

func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_titles_preview()
		return
		
	# Initialize progress bar
	#if slide_progress_bar:
		#slide_progress_bar.max_value = 100
		#slide_progress_bar.value = 0
		#slide_progress_bar.show_percentage = true
	
	_show_slide(0)
	_render_progress_bar()
	
func _process(delta: float) -> void:
	# Only update progress bar if we have a valid slide and animation is playing
	if is_instance_valid(current_slide):
		var current_slide_player = current_slide.get_node_or_null("AnimationPlayer")
		if current_slide_player and current_slide_player.is_playing():
			_update_progress_bar()
	

# Public method to manually refresh titles (useful for editor scripts)
func refresh_titles() -> void:
	if Engine.is_editor_hint():
		_refresh_titles_preview()

func _refresh_titles_preview() -> void:
	titles_preview = _collect_titles_from_packed(slides)
	notify_property_list_changed()  # <-- correct name in Godot 4.4

func _show_slide(i: int) -> void:
	index = clamp(i, 0, slides.size() - 1)
	var packed: PackedScene = slides[index]
	if not packed:
		push_warning("Slide %d is empty" % index)
		return

	if is_instance_valid(current_slide):
		current_slide.queue_free()

	current_slide = packed.instantiate()
	host.add_child(current_slide)

	# Wire slide_completed from this slide (or any child)
	var found := _wire_slide_completed(current_slide)
	if not found:
		# Optional: warn once if nothing exposes the signal
		# push_warning("No 'slide_completed' signal found on slide index %d" % index)
		pass

	slide_changed.emit(index)
	progress_changed.emit(unlocked_max_index, index)
	
	# Initialize progress bar for the new slide
	_render_progress_bar()

func go_next() -> void:
	mark_current_complete()
	if index < slides.size() - 1:
		_show_slide(index + 1)
	

func go_prev() -> void:
	if index > 0:
		_show_slide(index - 1)
		

func go_to(i: int) -> void:
	if i < 0 or i >= slides.size():
		return
	# Optional gating: only allow jumping to <= unlocked_max_index
	# if i > unlocked_max_index: return
	_show_slide(i)

func mark_current_complete() -> void:
	unlocked_max_index = max(unlocked_max_index, index + 1)
	progress_changed.emit(unlocked_max_index, index)

# ---- Signal hookup helpers ----

func _wire_slide_completed(root: Node) -> bool:
	var any_connected := false
	# Connect on the root if present
	any_connected = _try_connect_slide_completed(root) or any_connected
	# Also scan children (some slides emit from a nested node)
	for child in root.get_children():
		any_connected = _wire_slide_completed(child) or any_connected
	return any_connected

func _try_connect_slide_completed(node: Node) -> bool:
	if node.has_signal("slide_completed"):
		var cb := Callable(self, "_on_slide_completed")
		if not node.is_connected("slide_completed", cb):
			node.connect("slide_completed", cb)
		return true
	return false

func _on_slide_completed() -> void:
	# 1) Unlock progress
	mark_current_complete()
	# 2) Optional: auto-advance if there is a next slide
	#    (Comment this out if you want manual Next button only.)
	if index < slides.size() - 1:
		go_next()
		
func get_slide_title(i: int) -> String:
	if i < 0 or i >= slides.size():
		return "Untitled"
	return _get_title_from_packed(slides[i])

func _collect_titles_from_packed(arr: Array[PackedScene]) -> Array[String]:
	var out: Array[String] = []
	for p in arr:
		out.append(_get_title_from_packed(p))
	return out

# --- Core: read exported var from root WITHOUT instancing
func _get_title_from_packed(packed: PackedScene) -> String:
	if packed == null:
		return "Untitled"
	
	var state := packed.get_state() # SceneState
	if state == null:
		return _fallback_title_from_path(packed)

	# Root node is index 0 in SceneState
	# Scan its exported properties for "slide_title"
	var prop_count: int = state.get_node_property_count(0)  # root node = 0
	for i in range(prop_count):
		var name: String = state.get_node_property_name(0, i)
		if name == "slide_title":
			var value = state.get_node_property_value(0, i)
			if value != null and value != "":
				return str(value)

	# Fallbacks
	return _fallback_title_from_path(packed)

func _fallback_title_from_path(packed: PackedScene) -> String:
	# Best-effort: use filename if available; otherwise "Untitled"
	if packed.resource_path != "":
		return packed.resource_path.get_file().get_basename()
	return "Untitled"


func _render_progress_bar():
	if not is_instance_valid(current_slide):
		slide_progress_bar.max_value = 100
		slide_progress_bar.value = 0
		return
		
	var current_slide_player = current_slide.get_node_or_null("AnimationPlayer")
	if not current_slide_player:
		slide_progress_bar.max_value = 100
		slide_progress_bar.value = 0
		return
		
	var current_slide_animation = current_slide_player.get_animation("Slide_Animation")
	if not current_slide_animation:
		slide_progress_bar.max_value = 100
		slide_progress_bar.value = 0
		return
		
	total_length = current_slide_animation.length
	slide_progress_bar.max_value = 100
	slide_progress_bar.value = 0
	print("Progress bar initialized - Total length:", total_length)
	
func _update_progress_bar():
	if not is_instance_valid(current_slide):
		return
		
	var current_slide_player = current_slide.get_node_or_null("AnimationPlayer")
	if not current_slide_player:
		return
		
	var current_slide_animation = current_slide_player.get_animation("Slide_Animation")
	if not current_slide_animation:
		return
		
	# Get current animation position from the AnimationPlayer, not the animation resource
	var current_progress = current_slide_player.current_animation_position
	
	# Calculate progress as a percentage of total length
	if total_length > 0:
		var progress_percentage = (current_progress / total_length) * 100
		slide_progress_bar.value = progress_percentage
		print("Progress: ", progress_percentage, "% (", current_progress, "/", total_length, ")")
