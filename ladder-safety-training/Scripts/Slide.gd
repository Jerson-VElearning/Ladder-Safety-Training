# Slide.gd
extends Control
class_name CourseSlide

@export var slide_title: String = "Untitled"

func _ready() -> void:
	var shell := get_tree().get_first_node_in_group("CourseShell")  # or pass a ref in
	if shell:
		shell.mark_current_complete()
