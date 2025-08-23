extends Control
class_name QuizStartScene

# Quiz Configuration (visible in Inspector)
@export var quiz_manager: QuizManager
@export var start_button_text: String = "Start Quiz"
@export var show_quiz_info: bool = true
@export var show_attempt_info: bool = true
@export var show_score_info: bool = true

# UI References
@onready var quiz_name_label: Label = $QuizInfo/QuizName
@onready var required_score_label: Label = $QuizInfo/RequiredScore
@onready var total_questions_label: Label = $QuizInfo/TotalQuestions
@onready var max_attempts_label: Label = $QuizInfo/MaxAttempts
@onready var current_attempt_label: Label = $QuizInfo/CurrentAttempt
@onready var start_button: Button = $StartButton
@onready var retake_button: Button = $RetakeButton
@onready var quiz_info_container: Control = $QuizInfo

# Quiz State Display
@onready var score_display: Label = $ScoreDisplay
@onready var attempt_display: Label = $AttemptDisplay

func _ready() -> void:
	if quiz_manager:
		_setup_quiz_manager()
		_update_ui()
	else:
		print("Warning: No QuizManager assigned to QuizStartScene")

func _setup_quiz_manager() -> void:
	# Connect to quiz manager signals
	quiz_manager.quiz_started.connect(_on_quiz_started)
	quiz_manager.quiz_completed.connect(_on_quiz_completed)
	quiz_manager.attempt_used.connect(_on_attempt_used)
	quiz_manager.score_updated.connect(_on_score_updated)

func _update_ui() -> void:
	if !quiz_manager:
		return
	
	var summary = quiz_manager.get_quiz_summary()
	
	# Update quiz info
	if quiz_name_label:
		quiz_name_label.text = "Quiz: " + summary.quiz_name
	
	if required_score_label:
		var score_text = "Required Score: "
		if quiz_manager.score_type == QuizManager.ScoreType.PERCENTAGE:
			score_text += str(summary.required_score) + "%"
		else:
			score_text += str(summary.required_score) + "%"
		required_score_label.text = score_text
	
	if total_questions_label:
		total_questions_label.text = "Total Questions: " + str(summary.total_questions)
	
	if max_attempts_label:
		max_attempts_label.text = "Max Attempts: " + str(summary.max_attempts)
	
	if current_attempt_label:
		current_attempt_label.text = "Current Attempt: " + str(summary.current_attempt)
	
	# Update buttons
	if start_button:
		start_button.text = start_button_text
		start_button.disabled = !quiz_manager.can_retake()
	
	if retake_button:
		retake_button.visible = quiz_manager.quiz_completed and quiz_manager.can_retake()
		retake_button.disabled = !quiz_manager.can_retake()
	
	# Update score and attempt display
	if score_display:
		score_display.text = "Score: " + str(summary.score_percentage) + "%"
	
	if attempt_display:
		attempt_display.text = "Attempts: " + str(summary.current_attempt) + "/" + str(summary.max_attempts)

func _on_start_button_pressed() -> void:
	if quiz_manager and quiz_manager.can_retake():
		quiz_manager.start_quiz()
		# You can emit a signal here to transition to the quiz scene
		print("Starting quiz...")

func _on_retake_button_pressed() -> void:
	if quiz_manager and quiz_manager.can_retake():
		quiz_manager.start_quiz()
		# You can emit a signal here to transition to the quiz scene
		print("Retaking quiz...")

# Quiz Manager Signal Handlers
func _on_quiz_started() -> void:
	_update_ui()
	print("Quiz started from start scene")

func _on_quiz_completed(passed: bool, final_score: float) -> void:
	_update_ui()
	print("Quiz completed. Passed: ", passed, " Score: ", final_score)

func _on_attempt_used(attempt_number: int, remaining_attempts: int) -> void:
	_update_ui()
	print("Attempt used. Remaining: ", remaining_attempts)

func _on_score_updated(new_score: float, percentage: float) -> void:
	_update_ui()
	print("Score updated: ", new_score, " (", percentage, "%)")

# Inspector property change handler
func _property_list_changed() -> void:
	if quiz_manager:
		_update_ui()

