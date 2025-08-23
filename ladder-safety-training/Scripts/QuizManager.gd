class_name QuizManager
extends Node

# Quiz Configuration
@export var quiz_name: String = "Quiz"
@export var required_score: float = 80.0
@export var max_attempts: int = 3
@export var score_type: ScoreType = ScoreType.PERCENTAGE
@export var total_questions: int = 10
@export var points_per_question: float = 10.0

# Quiz State
var current_attempt: int = 0
var current_score: float = 0.0
var questions_answered: int = 0
var questions_correct: int = 0
var quiz_completed: bool = false
var quiz_passed: bool = false

# Signals
signal quiz_started
signal quiz_completed(passed: bool, final_score: float)
signal question_answered(correct: bool, current_score: float)
signal attempt_used(attempt_number: int, remaining_attempts: int)
signal score_updated(new_score: float, percentage: float)

enum ScoreType {
	PERCENTAGE,  # Score is a percentage (0-100)
	POINTS       # Score is based on total points earned
}

func _ready() -> void:
	reset_quiz()

# Start a new quiz attempt
func start_quiz() -> void:
	if current_attempt >= max_attempts:
		print("Maximum attempts reached. Cannot start new quiz.")
		return
	
	current_attempt += 1
	current_score = 0.0
	questions_answered = 0
	questions_correct = 0
	quiz_completed = false
	quiz_passed = false
	
	emit_signal("quiz_started")
	emit_signal("attempt_used", current_attempt, max_attempts - current_attempt)
	print("Quiz started - Attempt ", current_attempt, " of ", max_attempts)

# Answer a question (call this when student answers)
func answer_question(correct: bool, points: float = 0.0) -> void:
	if quiz_completed:
		print("Quiz already completed. Cannot answer more questions.")
		return
	
	questions_answered += 1
	
	if correct:
		questions_correct += 1
		if score_type == ScoreType.POINTS:
			current_score += points
		else:
			current_score = (float(questions_correct) / float(total_questions)) * 100.0
	else:
		if score_type == ScoreType.POINTS:
			current_score += 0.0  # No points for wrong answer
		else:
			current_score = (float(questions_correct) / float(total_questions)) * 100.0
	
	emit_signal("question_answered", correct, current_score)
	emit_signal("score_updated", current_score, get_score_percentage())
	
	print("Question answered. Correct: ", correct, " | Score: ", current_score)

# Complete the quiz
func complete_quiz() -> void:
	if quiz_completed:
		print("Quiz already completed.")
		return
	
	quiz_completed = true
	
	# Determine if quiz was passed
	if score_type == ScoreType.PERCENTAGE:
		quiz_passed = current_score >= required_score
	else:
		var percentage = (current_score / (total_questions * points_per_question)) * 100.0
		quiz_passed = percentage >= required_score
	
	emit_signal("quiz_completed", quiz_passed, current_score)
	
	print("Quiz completed. Passed: ", quiz_passed, " | Final Score: ", current_score)

# Get current score as percentage
func get_score_percentage() -> float:
	if score_type == ScoreType.PERCENTAGE:
		return current_score
	else:
		return (current_score / (total_questions * points_per_question)) * 100.0

# Get remaining attempts
func get_remaining_attempts() -> int:
	return max_attempts - current_attempt

# Check if can retake quiz
func can_retake() -> bool:
	return current_attempt < max_attempts

# Reset quiz for new session
func reset_quiz() -> void:
	current_attempt = 0
	current_score = 0.0
	questions_answered = 0
	questions_correct = 0
	quiz_completed = false
	quiz_passed = false

# Get quiz summary
func get_quiz_summary() -> Dictionary:
	return {
		"quiz_name": quiz_name,
		"current_attempt": current_attempt,
		"max_attempts": max_attempts,
		"current_score": current_score,
		"score_percentage": get_score_percentage(),
		"required_score": required_score,
		"questions_answered": questions_answered,
		"questions_correct": questions_correct,
		"total_questions": total_questions,
		"quiz_completed": quiz_completed,
		"quiz_passed": quiz_passed,
		"can_retake": can_retake()
	}
