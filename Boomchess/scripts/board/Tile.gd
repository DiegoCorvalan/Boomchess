extends TextureRect

var texture_bk : Texture2D
var ghost : Control = null

func _get_drag_data(_at_position):
	texture_bk = texture
	
	# Crear ghost que seguirá al mouse
	ghost = Control.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 1000
	
	var preview_texture = TextureRect.new()
	preview_texture.texture = texture
	preview_texture.expand_mode = 1
	preview_texture.size = Vector2(25, 25)
	preview_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.add_child(preview_texture)
	ghost.size = Vector2(25, 25)
	
	get_viewport().add_child(ghost)
	var mouse_pos = get_global_mouse_position()
	ghost.global_position = mouse_pos - Vector2(12.5, 12.5)
	
	# Preview invisible para el sistema de drag and drop
	var invisible_preview = Control.new()
	invisible_preview.size = Vector2(1, 1)
	invisible_preview.visible = false
	set_drag_preview(invisible_preview)
	
	texture = null
	return preview_texture.texture

func _process(_delta):
	if ghost != null and ghost.is_inside_tree():
		var mouse_pos = get_global_mouse_position()
		ghost.global_position = mouse_pos - Vector2(12.5,5)
	
func _can_drop_data(_pos, data):
	if texture == null:
		return data is Texture2D

	
func _drop_data(_pos, data):
	texture = data
	
	
func _notification(what:int) -> void:
	if what == Node.NOTIFICATION_DRAG_END:
		if ghost != null:
			if ghost.is_inside_tree():
				ghost.queue_free()
			ghost = null
		
		if is_drag_successful():
			texture_bk = null
		else:
			if texture == null:
				texture = texture_bk
				texture_bk = null

