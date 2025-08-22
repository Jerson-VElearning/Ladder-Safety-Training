# Slide.gd
extends Control
class_name CourseSlide

@export var slide_title: String = "Untitled"
@export var auto_play: bool = true
@export var go_to_next_slide_on_finished: bool = true	
@export var next_button:bool = true
@export var previous_button:bool = true

@onready var animation_player: AnimationPlayer = $AnimationPlayer


signal slide_completed

func _ready() -> void:
	if auto_play == true:
		animation_player.play("Slide_Animation")
	
	
func _auto_complete() -> void:
	slide_completed.emit()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if go_to_next_slide_on_finished:
		_auto_complete()
	


func _on_animation_player_animation_started(anim_name: StringName) -> void:
	print("animation started")
