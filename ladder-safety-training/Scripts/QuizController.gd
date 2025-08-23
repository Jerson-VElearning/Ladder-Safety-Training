extends Control
class_name QuizController

# Quiz Configuration
@export var quiz_manager: QuizManager
@export var questions: Array[PackedScene] = []
@export var auto_advance: bool = true
@export var show_progress: bool = true

# UI References
@onready var question_container: Control = $QuestionContainer
@onready var progress_label: Label = $ProgressLabel
@onready var score_label: Label = $ScoreLabel
@onready var next_button: Button = $NextButton
@onready var finish_button: Button = $FinishButton

# Quiz State
var current_question_index: int = 0
var current_question_instance: QuizQuestion
var questions_answered: int = 0

func _ready() -> void:
	if quiz_manager:
		_setup_quiz_manager()
		_setup_ui()
		_show_question(0)
	else:
		print("Warning: No QuizManager assigned to QuizController")

func _setup_quiz_manager() -> void:
	# Connect to quiz manager signals
	quiz_manager.quiz_started.connect(_on_quiz_started)
	quiz_manager.quiz_completed.connect(_on_quiz_completed)

func _setup_ui() -> void:
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
		next_button.visible = false
	
	if finish_button:
		finish_button.pressed.connect(_on_finish_pressed)
		finish_button.visible = false

func _show_question(index: int) -> void:
	if index < 0 or index >= questions.size():
		print("Invalid question index: ", index)
		return
	
	# Remove current question if it exists
	if current_question_instance:
		current_question_instance.queue_free()
	
	# Instantiate new question
	var question_scene = questions[index]
	if question_scene:
		current_question_instance = question_scene.instantiate()
		question_container.add_child(current_question_instance)
		
		# Connect to question signals
		current_question_instance.question_answered.connect(_on_question_answered)
		current_question_instance.question_completed.connect(_on_question_completed)
		
		current_question_index = index
		_update_progress()
		_update_buttons()
	else:
		print("Failed to instantiate question at index: ", index)

func _on_question_answered(correct: bool, points: float) -> void:
	if quiz_manager:
		quiz_manager.answer_question(correct, points)
	
	questions_answered += 1
	_update_progress()
	_update_buttons()

func _on_question_completed() -> void:
	if auto_advance:
		_advance_question()
	else:
		_show_next_button()

func _advance_question() -> void:
	var next_index = current_question_index + 1
	
	if next_index < questions.size():
		_show_question(next_index)
	else:
		_show_finish_button()

func _show_next_button() -> void:
	if next_button:
		next_button.visible = true
		next_button.disabled = false

func _show_finish_button() -> void:
	if finish_button:
		finish_button.visible = true
		finish_button.disabled = false

func _on_next_pressed() -> void:
	if next_button:
		next_button.visible = false
	_advance_question()

func _on_finish_pressed() -> void:
	if quiz_manager:
		quiz_manager.complete_quiz()
	
	# You can emit a signal here to transition back to results or start scene
	print("Quiz finished!")

func _update_progress() -> void:
	if progress_label and show_progress:
		progress_label.text = "Question " + str(current_question_index + 1) + " of " + str(questions.size())
	
	if score_label and quiz_manager:
		var summary = quiz_manager.get_quiz_summary()
		score_label.text = "Score: " + str(summary.score_percentage) + "%"

func _update_buttons() -> void:
	# Update button states based on current question state
	if current_question_instance and current_question_instance.answered:
		if next_button:
			next_button.disabled = false

# Quiz Manager Signal Handlers
func _on_quiz_started() -> void:
	current_question_index = 0
	questions_answered = 0
	_show_question(0)
	print("Quiz started in controller")

func _on_quiz_completed(passed: bool, final_score: float) -> void:
	print("Quiz completed in controller. Passed: ", passed, " Score: ", final_score)
	# You can emit a signal here to transition to results scene

# Public methods
func get_quiz_progress() -> Dictionary:
	return {
		"current_question": current_question_index + 1,
		"total_questions": questions.size(),
		"questions_answered": questions_answered,
		"progress_percentage": (float(questions_answered) / float(questions.size())) * 100.0
	}

func reset_quiz() -> void:
	current_question_index = 0
	questions_answered = 0
	
	if current_question_instance:
		current_question_instance.queue_free()
		current_question_instance = null
	
	if next_button:
		next_button.visible = false
	
	if finish_button:
		finish_button.visible = false
	
	_show_question(0)

