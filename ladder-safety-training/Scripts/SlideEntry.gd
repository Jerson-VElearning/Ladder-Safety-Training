# SlideEntry.gd
extends Resource
class_name SlideEntry

@export var scene: PackedScene
@export var title: String = ""

func get_title() -> String:
	if title != "":
		return title
	if scene:
		var inst := scene.instantiate()
		var t: String = str(inst.get("slide_title")) if inst.has_variable("slide_title") else "Untitled"
		inst.free()
		return t
	return "Untitled"
