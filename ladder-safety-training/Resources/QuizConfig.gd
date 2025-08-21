# res://resources/QuizConfig.gd
extends Resource
class_name QuizConfig
#@icon("res://icon.svg") # optional

@export_enum("percent", "points") var pass_mode := "percent"
@export_range(0, 100, 1) var pass_value := 80  # if percent, 0–100; if points, any int you use

@export var shuffle_questions := true
@export var shuffle_choices := true

@export var max_attempts := 0               # 0 = unlimited
@export_enum("all_or_nothing", "partial_credit") var grading := "all_or_nothing"
@export var allow_review := true
@export_enum("full", "incorrect_only") var retry_mode := "full"

@export var time_limit_seconds := 0         # 0 = none

# Optional: which bank to use, or direct question list if you prefer
@export var bank_path : String = ""         # e.g., "res://data/banks/bank_intro.tres"
