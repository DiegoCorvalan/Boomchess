extends Node

signal score_changed(new_score:int)

var score:int = 0
var game_over:bool = false

func reset_score() -> void:
	score = 0
	game_over = false
	score_changed.emit(score)

func get_score() -> int:
	return score

func points_for_size(size_level:int) -> int:
	if size_level <= 1:
		return 1
	var value := 5.0 * pow(1.8, float(size_level - 2))
	return int(round(value))

func add_points_for_size(size_level:int) -> void:
	if game_over:
		return
	score += points_for_size(size_level)
	score_changed.emit(score)

func set_game_over() -> void:
	game_over = true
