# res://resources/Question.gd
extends Resource
class_name Question
@export_enum("single","multiple","true_false","short_answer") var qtype := "single"
@export var prompt : String = ""
@export var choices : Array[Choice] = []
@export var points : int = 1
