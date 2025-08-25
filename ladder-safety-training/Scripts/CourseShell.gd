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
var unlocked_max_index: int = 0
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

# Helper function to stop all audio streams in a node tree
# This is especially important for web exports where audio can continue playing
# even after the parent node is removed, causing audio overlap between slides
func _stop_all_audio_streams(node: Node) -> void:
	# Get all AudioStreamPlayer nodes in the "AudioStreams" group
	var audio_players = get_tree().get_nodes_in_group("AudioStreams")
	print("Found ", audio_players.size(), " audio players in AudioStreams group")  # Debug output
	
	for audio_player in audio_players:
		# Only stop audio players that belong to the current slide
		if audio_player.is_inside_tree() and audio_player.get_parent() == node:
			print("Stopping audio player: ", audio_player.name)  # Debug output
			audio_player.stop()
		else:
			print("Audio player ", audio_player.name, " not in current slide")  # Debug output

# Stop audio tracks in animations (some audio might be playing through animation tracks)
func _stop_animation_audio_tracks(animation_player: AnimationPlayer) -> void:
	if not animation_player:
		return
		
	var current_animation = animation_player.get_current_animation()
	if current_animation:
		var animation = animation_player.get_animation(current_animation)
		if animation:
			# Check for audio tracks in the animation
			for i in range(animation.get_track_count()):
				if animation.track_get_type(i) == Animation.TYPE_AUDIO:
					var track_path = animation.track_get_path(i)
					# Try to get the node, but handle cases where it might not exist
					var target_node = null
					if track_path.is_absolute_path():
						target_node = get_node(track_path)
					else:
						target_node = animation_player.get_node_or_null(track_path)
					
					if target_node and target_node is AudioStreamPlayer:
						print("Stopping animation audio track: ", target_node.name)  # Debug output
						target_node.volume_db = -80.0
						target_node.stop()
						target_node.stream = null
						target_node.volume_db = 0.0

func _show_slide(i: int) -> void:
	index = clamp(i, 0, slides.size() - 1)
	var packed: PackedScene = slides[index]
	if not packed:
		push_warning("Slide %d is empty" % index)
		return

	if is_instance_valid(current_slide):
		print("Stopping audio for slide ", index)  # Debug output
		
		# Call the slide's own audio cleanup method
		if current_slide.has_method("stop_slide_audio"):
			current_slide.stop_slide_audio()
		
		# Use global audio stop for web exports to ensure complete cleanup
		if OS.get_name() == "Web":
			stop_all_audio_globally()
		else:
			# Stop all audio streams before removing the old slide
			_stop_all_audio_streams(current_slide)
		
		# Also stop the animation player
		var old_animation_player = current_slide.get_node_or_null("AnimationPlayer")
		if old_animation_player:
			old_animation_player.stop()
		
		# Longer delay for web exports to ensure complete audio cleanup
		if OS.get_name() == "Web":
			await get_tree().create_timer(0.1).timeout  # 100ms delay for web
		else:
			await get_tree().process_frame
		
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
	# Immediately stop all audio when user presses next
	if OS.get_name() == "Web":
		stop_all_audio_globally()
	
	mark_current_complete()
	if index < slides.size() - 1:
		_show_slide(index + 1)
	

func go_prev() -> void:
	# Immediately stop all audio when user presses previous
	if OS.get_name() == "Web":
		stop_all_audio_globally()
	
	if index > 0:
		_show_slide(index - 1)
		

func go_to(i: int) -> void:
	if i < 0 or i >= slides.size():
		return
	# Optional gating: only allow jumping to <= unlocked_max_index
	# if i > unlocked_max_index: return
	_show_slide(i)

# Public method to manually stop all audio (useful for external control)
func stop_all_audio() -> void:
	if is_instance_valid(current_slide):
		_stop_all_audio_streams(current_slide)
		var animation_player = current_slide.get_node_or_null("AnimationPlayer")
		if animation_player:
			animation_player.stop()

# Force stop all audio streams globally (useful for web exports)
func force_stop_all_audio() -> void:
	var audio_players = get_tree().get_nodes_in_group("AudioStreams")
	print("Force stopping ", audio_players.size(), " audio players")  # Debug output
	
	for audio_player in audio_players:
		if audio_player.is_inside_tree():
			print("Force stopping: ", audio_player.name)  # Debug output
			# Set volume to 0 first to immediately silence audio
			audio_player.volume_db = -80.0
			audio_player.stop()
			# Also try to set the stream to null to completely clear it
			audio_player.stream = null
			# Reset volume for future use
			audio_player.volume_db = 0.0

# Global audio stop that works regardless of node structure
func stop_all_audio_globally() -> void:
	# Get all AudioStreamPlayer nodes in the scene tree
	var all_nodes = get_tree().get_nodes_in_group("AudioStreams")
	print("Stopping all audio globally: ", all_nodes.size(), " players found")
	
	for node in all_nodes:
		if node is AudioStreamPlayer and node.is_inside_tree():
			print("Global stop: ", node.name)
			node.volume_db = -80.0
			node.stop()
			node.stream = null
			node.volume_db = 0.0
	
	# Also try to stop any playing animations that might have audio
	var animation_players = get_tree().get_nodes_in_group("")
	for anim_player in animation_players:
		if anim_player is AnimationPlayer and anim_player.is_playing():
			anim_player.stop()

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
	#print("Progress bar initialized - Total length:", total_length)
	
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
		#print("Progress: ", progress_percentage, "% (", current_progress, "/", total_length, ")")


func _on_play_pause_toggled(toggled_on: bool) -> void:
	var slide_player = current_slide.get_node_or_null("AnimationPlayer")
	if toggled_on:
		slide_player.pause()
	else:
		slide_player.play()
		

func _on_replay_pressed() -> void:
	var slide_player = current_slide.get_node_or_null("AnimationPlayer")
	slide_player.stop()
	slide_player.play()
