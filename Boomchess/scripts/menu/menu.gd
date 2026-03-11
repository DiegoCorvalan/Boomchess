extends Control



func _on_options_pressed() -> void:
	pass # no hay opciones estamos trabajando para ello

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Boomchess/scenes/Principal2.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
