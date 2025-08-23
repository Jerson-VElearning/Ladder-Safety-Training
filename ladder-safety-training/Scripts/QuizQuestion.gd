extends Control
class_name QuizQuestion

# Question Configuration
@export var question_text: String = "Enter your question here"
@export var points: float = 10.0
@export var question_type: QuestionType = QuestionType.MULTIPLE_CHOICE
@export var options: Array[String] = ["Option 1", "Option 2", "Option 3", "Option 4"]
@export var partial_credit: bool = false  # Allow partial credit for multiple choice questions

# Question State
var answered: bool = false
var answer_correct: bool = false
var selected_answers: Array[String] = []
var correct_answers: Array[String] = []

# References
@onready var question_label: Label = $QuestionLabel
@onready var options_container: VBoxContainer = $OptionsContainer
@onready var submit_button: Button = $SubmitButton
@onready var feedback_label: Label = $FeedbackLabel

# Signals
signal question_answered(correct: bool, points: float)
signal question_completed

enum QuestionType {
	MULTIPLE_CHOICE,
	TRUE_FALSE,
	TEXT_INPUT,
	CHECKBOX_GROUP
}

func _ready() -> void:
	_setup_question()
	_connect_signals()

func _setup_question() -> void:
	if question_label:
		question_label.text = question_text
	
	_setup_options()
	_reset_question_state()

func _setup_options() -> void:
	if !options_container:
		return
	
	# Clear existing options
	for child in options_container.get_children():
		child.queue_free()
	
	# Create option controls based on question type
	match question_type:
		QuestionType.MULTIPLE_CHOICE:
			_create_multiple_choice_options()
		QuestionType.TRUE_FALSE:
			_create_true_false_options()
		QuestionType.TEXT_INPUT:
			_create_text_input()
		QuestionType.CHECKBOX_GROUP:
			_create_checkbox_group_options()

func _create_multiple_choice_options() -> void:
	for i in range(options.size()):
		var button = Button.new()
		button.text = options[i]
		button.toggle_mode = true
		button.button_group = ButtonGroup.new()
		button.pressed.connect(_on_option_selected.bind(options[i]))
		options_container.add_child(button)

func _create_true_false_options() -> void:
	var true_button = Button.new()
	true_button.text = "True"
	true_button.toggle_mode = true
	true_button.button_group = ButtonGroup.new()
	true_button.pressed.connect(_on_option_selected.bind("True"))
	options_container.add_child(true_button)
	
	var false_button = Button.new()
	false_button.text = "False"
	false_button.toggle_mode = true
	false_button.button_group = ButtonGroup.new()
	false_button.pressed.connect(_on_option_selected.bind("False"))
	options_container.add_child(false_button)

func _create_text_input() -> void:
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Enter your answer..."
	line_edit.text_changed.connect(_on_text_input_changed)
	options_container.add_child(line_edit)

func _create_checkbox_group_options() -> void:
	# For checkbox groups, we'll use the existing checkboxes in the scene
	# Just connect to their signals and collect the correct answers
	_collect_checkbox_answers()

func _collect_checkbox_answers() -> void:
	# Find all checkboxes in the "correct" group
	var correct_group = get_tree().get_nodes_in_group("correct")
	correct_answers.clear()
	
	for checkbox in correct_group:
		if checkbox is CheckBox:
			# Store the checkbox text as the correct answer
			correct_answers.append(checkbox.text)
			# Connect to the checkbox signal
			checkbox.toggled.connect(_on_checkbox_toggled.bind(checkbox))

func _on_checkbox_toggled(button_pressed: bool, checkbox: CheckBox) -> void:
	var checkbox_text = checkbox.text
	
	if button_pressed:
		if not selected_answers.has(checkbox_text):
			selected_answers.append(checkbox_text)
	else:
		selected_answers.erase(checkbox_text)

func _connect_signals() -> void:
	if submit_button:
		submit_button.pressed.connect(_on_submit_pressed)

func _on_option_selected(option: String) -> void:
	selected_answers.clear()  # Single selection for radio buttons
	selected_answers.append(option)

func _on_text_input_changed(new_text: String) -> void:
	selected_answers.clear()
	selected_answers.append(new_text)

func _on_submit_pressed() -> void:
	if selected_answers.is_empty():
		_show_feedback("Please select an answer!")
		return
	
	_validate_answer()
	_submit_answer()

func _validate_answer() -> void:
	match question_type:
		QuestionType.CHECKBOX_GROUP:
			_validate_checkbox_answer()
		QuestionType.TEXT_INPUT:
			# For text input, you can set correct_answers manually in the inspector
			# or override this method in a child class
			answer_correct = _check_text_answer()
		_:
			# For radio button questions, check against first correct answer
			if correct_answers.size() > 0:
				answer_correct = selected_answers.has(correct_answers[0])

func _validate_checkbox_answer() -> void:
	if correct_answers.size() == 0:
		# If no correct answers defined, assume all selected are correct
		answer_correct = true
		return
	
	# Check if all correct answers are selected and no incorrect ones
	var all_correct_selected = true
	var no_incorrect_selected = true
	
	# Check if all correct answers are selected
	for correct_answer in correct_answers:
		if not selected_answers.has(correct_answer):
			all_correct_selected = false
			break
	
	# Check if no incorrect answers are selected
	for selected_answer in selected_answers:
		if not correct_answers.has(selected_answer):
			no_incorrect_selected = false
			break
	
	answer_correct = all_correct_selected and no_incorrect_selected

func _check_text_answer() -> bool:
	if correct_answers.size() == 0:
		return false
	
	# Check if any selected answer matches any correct answer (case-insensitive)
	for selected_answer in selected_answers:
		for correct_answer in correct_answers:
			if selected_answer.to_lower() == correct_answer.to_lower():
				return true
	
	return false

func _submit_answer() -> void:
	if answered:
		return
	
	answered = true
	
	_show_feedback()
	_disable_input()
	
	# Calculate points based on answer correctness
	var earned_points = 0.0
	if answer_correct:
		earned_points = points
	elif partial_credit and question_type == QuestionType.CHECKBOX_GROUP:
		# Calculate partial credit for checkbox questions
		earned_points = _calculate_partial_credit()
	
	emit_signal("question_answered", answer_correct, earned_points)
	emit_signal("question_completed")

func _calculate_partial_credit() -> float:
	if correct_answers.size() == 0:
		return 0.0
	
	var correct_selected = 0
	var incorrect_selected = 0
	
	# Count correct and incorrect selections
	for selected_answer in selected_answers:
		if correct_answers.has(selected_answer):
			correct_selected += 1
		else:
			incorrect_selected += 1
	
	# Calculate partial credit: (correct_selected - incorrect_selected) / total_correct * points
	var partial_score = float(correct_selected - incorrect_selected) / float(correct_answers.size())
	return max(0.0, partial_score * points)

func _show_feedback(message: String = "") -> void:
	if !feedback_label:
		return
	
	if message.is_empty():
		if answer_correct:
			feedback_label.text = "Correct! +" + str(points) + " points"
			feedback_label.modulate = Color.GREEN
		else:
			if question_type == QuestionType.CHECKBOX_GROUP and partial_credit:
				var partial_points = _calculate_partial_credit()
				if partial_points > 0:
					feedback_label.text = "Partially correct. +" + str(partial_points) + " points"
					feedback_label.modulate = Color.YELLOW
				else:
					feedback_label.text = "Incorrect. The correct answers were: " + _format_correct_answers()
					feedback_label.modulate = Color.RED
			else:
				feedback_label.text = "Incorrect. The correct answer was: " + _format_correct_answers()
				feedback_label.modulate = Color.RED
	else:
		feedback_label.text = message
		feedback_label.modulate = Color.YELLOW
	
	feedback_label.visible = true

func _format_correct_answers() -> String:
	if correct_answers.size() == 0:
		return "No correct answers defined"
	elif correct_answers.size() == 1:
		return correct_answers[0]
	else:
		return ", ".join(correct_answers)

func _disable_input() -> void:
	# Disable all option controls
	for child in options_container.get_children():
		if child is Button:
			child.disabled = true
		elif child is LineEdit:
			child.editable = false
	
	# Disable all checkboxes in the correct group
	var correct_group = get_tree().get_nodes_in_group("correct")
	for checkbox in correct_group:
		if checkbox is CheckBox:
			checkbox.disabled = true
	
	if submit_button:
		submit_button.disabled = true

func _reset_question_state() -> void:
	answered = false
	answer_correct = false
	selected_answers.clear()
	
	if feedback_label:
		feedback_label.visible = false
	
	# Re-enable input
	for child in options_container.get_children():
		if child is Button:
			child.disabled = false
		elif child is LineEdit:
			child.editable = true
			child.text = ""
	
	# Re-enable all checkboxes in the correct group
	var correct_group = get_tree().get_nodes_in_group("correct")
	for checkbox in correct_group:
		if checkbox is CheckBox:
			checkbox.disabled = false
			checkbox.button_pressed = false
	
	if submit_button:
		submit_button.disabled = false

# Public methods
func get_question_summary() -> Dictionary:
	return {
		"question_text": question_text,
		"correct_answers": correct_answers,
		"selected_answers": selected_answers,
		"answered": answered,
		"correct": answer_correct,
		"points": points if answer_correct else 0.0
	}

func reset_question() -> void:
	_reset_question_state()

# Method to manually set correct answers (useful for text input questions)
func set_correct_answers(answers: Array[String]) -> void:
	correct_answers = answers
