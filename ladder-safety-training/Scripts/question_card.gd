# res://scenes/components/QuestionCard.gd
extends Control
class_name QuestionCard

@export var question: Question : set = set_question

var _group: ButtonGroup

func _ready() -> void:
	if question:
		_render()

func set_question(q: Question) -> void:
	question = q
	if is_inside_tree():
		_render()

func _render() -> void:
	%Prompt.text = question.prompt
	for c in %Choices.get_children():
		c.queue_free()

	match question.qtype:
		"single":
			_group = ButtonGroup.new()
			_group.allow_unpress = false
			for ch in question.choices:
				var btn := CheckBox.new()
				btn.text = ch.text
				btn.button_group = _group      # radio behavior + radio look
				%Choices.add_child(btn)

		"multiple":
			for ch in question.choices:
				var cb := CheckBox.new()
				cb.text = ch.text               # plain checkboxes (no group)
				%Choices.add_child(cb)

		"true_false":
			_group = ButtonGroup.new()
			_group.allow_unpress = false
			for label in ["True", "False"]:
				var btn := CheckBox.new()
				btn.text = label
				btn.button_group = _group
				%Choices.add_child(btn)

		_:
			pass

func get_response() -> Dictionary:
	var indices: Array[int] = []
	var i := 0
	for node in %Choices.get_children():
		if node is CheckBox and node.button_pressed:
			indices.append(i)
		i += 1
	return {"indices": indices}
