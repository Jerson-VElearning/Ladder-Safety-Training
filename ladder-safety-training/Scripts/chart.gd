extends Control
class_name CircularChart

# Chart data structure - using arrays instead of custom class for exports
@export var chart_labels: Array[String] = ["Category A", "Category B", "Category C", "Category D", "Category E"]
@export var chart_values: Array[float] = [30.0, 25.0, 20.0, 15.0, 10.0]
@export var chart_colors: Array[Color] = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE]

# Chart appearance
@export var chart_radius: float = 100.0
@export var center_offset: Vector2 = Vector2(0, 0)
@export var show_labels: bool = true
@export var label_font_size: int = 16
@export var label_color: Color = Color.BLACK
@export var label_offset: float = 20.0

# Chart appearance
@export var stroke_width: float = 2.0
@export var stroke_color: Color = Color.WHITE
@export var use_gradients: bool = true

# Animation
@export var animate_chart: bool = true
@export var animation_duration: float = 1.0
var animation_progress: float = 0.0
var is_animating: bool = false

# Internal chart data
var chart_data: Array[ChartData] = []

# Chart data class
class ChartData:
	var label: String
	var value: float
	var color: Color
	
	func _init(p_label: String, p_value: float, p_color: Color):
		label = p_label
		value = p_value
		color = p_color

func _ready() -> void:
	# Set minimum size for the control
	custom_minimum_size = Vector2(chart_radius * 2 + 100, chart_radius * 2 + 100)
	
	# Create chart data from exported arrays
	_create_chart_data_from_exports()
	
	# Debug output
	print("Chart ready - Data count: ", chart_data.size())
	for data in chart_data:
		print("  ", data.label, ": ", data.value, " (", data.color, ")")
	
	# For debugging: disable animation to see chart immediately
	if animate_chart:
		print("Animation enabled - starting...")
		_start_animation()
	else:
		# If no animation, ensure we draw immediately
		animation_progress = 1.0
		is_animating = false
		print("Animation disabled - drawing immediately")
		queue_redraw()
	
	# Force an initial redraw after a short delay to ensure everything is set up
	await get_tree().process_frame
	ensure_visibility()

func _create_chart_data_from_exports() -> void:
	chart_data.clear()
	
	# Use the exported arrays to create chart data
	var max_items = min(chart_labels.size(), chart_values.size())
	print("Creating chart data from ", max_items, " items")
	
	for i in range(max_items):
		var color = chart_colors[i] if i < chart_colors.size() else _get_default_color(i)
		var data = ChartData.new(chart_labels[i], chart_values[i], color)
		chart_data.append(data)
		print("  Added: ", data.label, " = ", data.value, " color: ", data.color)

func _get_default_color(index: int) -> Color:
	var default_colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE, Color.ORANGE, Color.PINK, Color.CYAN]
	return default_colors[index % default_colors.size()]

func _start_animation() -> void:
	is_animating = true
	animation_progress = 0.0
	print("Starting animation with progress: ", animation_progress)
	
	# Force an initial draw with current progress
	queue_redraw()
	
	var tween = create_tween()
	# Use ease_out for smoother animation
	tween.tween_property(self, "animation_progress", 1.0, animation_duration).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_on_animation_finished)

func _on_animation_finished() -> void:
	is_animating = false
	animation_progress = 1.0
	print("Animation finished, progress: ", animation_progress)
	queue_redraw()

func _draw() -> void:
	print("_draw called - chart_data size: ", chart_data.size(), " animation_progress: ", animation_progress)
	
	if chart_data.is_empty():
		print("No chart data to draw")
		return
	
	# Calculate total value
	var total_value: float = 0.0
	for data in chart_data:
		total_value += data.value
	
	print("Total value: ", total_value)
	
	if total_value <= 0:
		print("Total value is 0 or negative")
		return
	
	# Calculate center position
	var center = size / 2 + center_offset
	print("Drawing at center: ", center, " with size: ", size)
	
	# Draw chart segments
	var current_angle = -PI/2  # Start from top
	var segment_angles: Array[float] = []
	
	# First pass: calculate all segment angles
	for data in chart_data:
		var segment_angle = (data.value / total_value) * TAU
		segment_angles.append(segment_angle)
		print("  Segment ", data.label, ": ", rad_to_deg(segment_angle), " degrees")
	
	# Second pass: draw segments with animation
	for i in range(chart_data.size()):
		var data = chart_data[i]
		var segment_angle = segment_angles[i]
		
		# Apply animation if enabled - use a different animation approach
		var animated_angle = segment_angle
		if is_animating:
			# Use a smoother animation that starts visible
			# Start with the segment at full size but with reduced opacity
			animated_angle = segment_angle
			
			# Apply a fade-in effect by adjusting the color alpha
			var original_color = data.color
			var animated_color = Color(original_color.r, original_color.g, original_color.b, animation_progress)
			
			# Draw segment with animated color
			_draw_segment(center, current_angle, animated_angle, animated_color)
		else:
			# Draw segment normally when not animating
			_draw_segment(center, current_angle, animated_angle, data.color)
		
		print("  Drawing segment ", data.label, " from ", rad_to_deg(current_angle), " to ", rad_to_deg(current_angle + animated_angle))
		
		# Draw label if enabled - show labels during animation too
		if show_labels:
			_draw_label(center, current_angle + animated_angle/2, data.label, data.color)
		
		current_angle += animated_angle

func _draw_segment(center: Vector2, start_angle: float, angle: float, color: Color) -> void:
	if angle <= 0:
		return
	
	# Create points for the segment
	var points: Array[Vector2] = []
	points.append(center)
	
	# Add points along the arc
	var steps = max(10, int(angle * 20))  # More steps for smoother curves
	for i in range(steps + 1):
		var t = float(i) / steps
		var current_angle = start_angle + t * angle
		var point = center + Vector2(cos(current_angle), sin(current_angle)) * chart_radius
		points.append(point)
	
	# Draw filled segment
	if points.size() > 2:
		draw_colored_polygon(points, color)
		
		# Draw stroke
		if stroke_width > 0:
			draw_polyline(points.slice(1), stroke_color, stroke_width, true)

func _draw_label(center: Vector2, angle: float, label: String, color: Color) -> void:
	# Calculate label position
	var label_distance = chart_radius + label_offset
	var label_pos = center + Vector2(cos(angle), sin(angle)) * label_distance
	
	# Create font for drawing
	var font = ThemeDB.fallback_font
	var font_size = ThemeDB.fallback_font_size
	if font_size <= 0:
		font_size = label_font_size
	
	# Calculate text size for centering
	var text_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	# Adjust position to center text
	label_pos -= text_size / 2
	
	# Draw text with outline for better visibility
	var outline_color = Color.BLACK
	var outline_width = 1.0
	
	# Draw outline
	for x in range(-outline_width, outline_width + 1):
		for y in range(-outline_width, outline_width + 1):
			if x != 0 or y != 0:
				draw_string(font, label_pos + Vector2(x, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_color)
	
	# Draw main text
	draw_string(font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)

# Public methods for updating chart data
func set_chart_data(new_data: Array[ChartData]) -> void:
	chart_data = new_data
	queue_redraw()

func add_data(label: String, value: float, color: Color) -> void:
	chart_data.append(ChartData.new(label, value, color))
	queue_redraw()

func clear_data() -> void:
	chart_data.clear()
	queue_redraw()

func refresh_chart() -> void:
	queue_redraw()

# Method to create chart data from simple arrays
func set_data_from_arrays(labels: Array[String], values: Array[float], colors: Array[Color] = []) -> void:
	chart_data.clear()
	
	var default_colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE, Color.ORANGE, Color.PINK, Color.CYAN]
	
	for i in range(labels.size()):
		var color = colors[i] if i < colors.size() else default_colors[i % default_colors.size()]
		chart_data.append(ChartData.new(labels[i], values[i], color))
	
	queue_redraw()

# Method to animate to new data
func animate_to_data(new_data: Array[ChartData], duration: float = 1.0) -> void:
	chart_data = new_data
	animation_duration = duration
	_start_animation()

# Method to update exported arrays and refresh chart
func update_exported_data() -> void:
	_create_chart_data_from_exports()
	queue_redraw()

# Force the chart to redraw
func force_redraw() -> void:
	queue_redraw()

# Method to ensure chart is visible and properly sized
func ensure_visibility() -> void:
	# Make sure we have a proper size
	if size.x < chart_radius * 2 or size.y < chart_radius * 2:
		custom_minimum_size = Vector2(chart_radius * 2 + 100, chart_radius * 2 + 100)
		size = custom_minimum_size
	
	# Force a redraw
	queue_redraw()

# Override to ensure proper sizing
func _get_minimum_size() -> Vector2:
	return Vector2(chart_radius * 2 + 100, chart_radius * 2 + 100)

# Test method to verify chart is working
func test_chart() -> void:
	print("=== CHART TEST ===")
	print("Control size: ", size)
	print("Custom minimum size: ", custom_minimum_size)
	print("Chart data count: ", chart_data.size())
	print("Animation progress: ", animation_progress)
	print("Is animating: ", is_animating)
	
	if chart_data.is_empty():
		print("ERROR: No chart data!")
		return
	
	var total = 0.0
	for data in chart_data:
		total += data.value
		print("  ", data.label, ": ", data.value, " (", data.color, ")")
	
	print("Total value: ", total)
	print("Chart radius: ", chart_radius)
	print("Center offset: ", center_offset)
	print("================")

# Method to disable animation and show chart immediately
func show_chart_immediately() -> void:
	animate_chart = false
	is_animating = false
	animation_progress = 1.0
	print("Chart animation disabled - showing immediately")
	queue_redraw()

# Method to enable animation
func enable_animation() -> void:
	animate_chart = true
	_start_animation()
