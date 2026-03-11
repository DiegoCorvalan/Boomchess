extends Node2D


func _ready() -> void:
	get_tree().change_scene_to_file("res://Boomchess/scripts/menu/menu.gd")
