extends Node2D

@export var pelota_scene:PackedScene = preload("res://Fruta/Pelota.tscn")

var _mouse_press_position:Vector2 = Vector2.ZERO
var _is_mouse_pressed:bool = false
var _touch_press_positions := {}

@onready var _score_label:Label = $label
var _is_game_over:bool = false

func _ready():
	var t := Timer.new()
	t.wait_time = 10.0
	t.one_shot = false
	t.autostart = true
	add_child(t)
	t.timeout.connect(_log_pelotas_positions)
	# Init score label and subscribe to score changes
	if Engine.has_singleton("Global") or (typeof(Global) != TYPE_NIL):
		_update_score_label(Global.get_score())
		Global.score_changed.connect(_update_score_label)

func _unhandled_input(event:InputEvent) -> void:
	if _is_game_over:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_press_position = event.position
			_is_mouse_pressed = true
		else:
			if _is_mouse_pressed:
				_spawn_pelota_at(_mouse_press_position)
				_is_mouse_pressed = false
		return

	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_touch_press_positions[touch_event.index] = touch_event.position
		else:
			if _touch_press_positions.has(touch_event.index):
				var pressed_pos:Vector2 = _touch_press_positions[touch_event.index]
				_spawn_pelota_at(pressed_pos)
				_touch_press_positions.erase(touch_event.index)

func _spawn_pelota_at(screen_position:Vector2) -> void:
	if _is_game_over:
		return
	if pelota_scene == null:
		return
	var pelota := pelota_scene.instantiate()
	if not (pelota is Node2D):
		return
	var pelota_2d := pelota as Node2D
	pelota_2d.global_position = screen_position
	add_child(pelota_2d)

func _log_pelotas_positions() -> void:
	var nodes := get_tree().get_nodes_in_group("pelotas")
	for n in nodes:
		if n is Node2D:
			print("Pelota ", n.name, " position=", n.global_position)

func _update_score_label(new_score:int) -> void:
	if _score_label != null:
		_score_label.text = "Puntos: " + str(new_score)


func _on_area_2d_area_entered(area):
	if _is_game_over:
		return
	_is_game_over = true
	if typeof(Global) != TYPE_NIL and ("set_game_over" in Global):
		Global.set_game_over()
	var final_score := 0
	if typeof(Global) != TYPE_NIL and ("get_score" in Global):
		final_score = Global.get_score()
	if _score_label != null:
		_score_label.text = "Pierdes - Puntos: " + str(final_score)
