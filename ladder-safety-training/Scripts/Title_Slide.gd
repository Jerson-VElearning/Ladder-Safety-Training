extends Control


@export var course_player: PackedScene


func _on_button_pressed() -> void:
	get_tree().change_scene_to_packed(course_player)
