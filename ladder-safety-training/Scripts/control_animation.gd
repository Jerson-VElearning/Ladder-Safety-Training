# FadeUpLabel.gd
class_name ControlAnimation
extends Control

@export var distance := 20.0
@export var duration := 0.35
@export var trans := Tween.TRANS_SINE
@export var ease := Tween.EASE_OUT
#@export var TextAnimation:  #lists the animation functions below.

var _base_pos: Vector2

func _ready():
	_base_pos = position
	visible = false
	modulate.a = 0.0

func play():
	#this function plays the selected text animation from the exported var
	pass


func text_fade_up():
	visible = true
	position = _base_pos + Vector2(0, distance)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "position:y", _base_pos.y, duration).set_trans(trans).set_ease(ease)
	tw.parallel().tween_property(self, "modulate:a", 1.0, duration).set_trans(trans).set_ease(ease)
	
	
func text_fade_down():
	visible = true
	position = _base_pos - Vector2(0, distance)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "position:y", _base_pos.y, duration).set_trans(trans).set_ease(ease)
	tw.parallel().tween_property(self, "modulate:a", 1.0, duration).set_trans(trans).set_ease(ease)
	
func text_fade_right():
	visible = true
	position = _base_pos - Vector2(distance, 0)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "position:x", _base_pos.x, duration).set_trans(trans).set_ease(ease)
	tw.parallel().tween_property(self, "modulate:a", 1.0, duration).set_trans(trans).set_ease(ease)
	
func text_fade_left():
	visible = true
	position = _base_pos + Vector2(distance, 0)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "position:x", _base_pos.x, duration).set_trans(trans).set_ease(ease)
	tw.parallel().tween_property(self, "modulate:a", 1.0, duration).set_trans(trans).set_ease(ease)
