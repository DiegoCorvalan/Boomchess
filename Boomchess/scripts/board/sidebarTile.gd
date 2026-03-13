extends TextureRect # Cada casilla del tablero es un TextureRect

var pieza_bk : Pieza # Guarda la pieza original mientras se arrastra
var ghost : Control = null # Nodo "fantasma" que sigue al mouse durante el drag
signal sin_pieza
@export var pieza : Pieza # Datos de la pieza que está en esta casilla
var bloqueado 

func _ready():
	# Al iniciar el nodo, actualiza la textura según la pieza asignada
	_piece_update()

func _piece_update():
	# Actualiza la imagen y el tooltip de la casilla según la pieza actual
	if not pieza:
		texture = null
		tooltip_text = ""
		return
	
	texture = pieza.icon
	tooltip_text = pieza.nombre


func _get_drag_data(_at_position):
	# Se ejecuta cuando se empieza a arrastrar desde esta casilla
	if not pieza:
		return null
	
	pieza_bk = pieza
	
	# Crea un "ghost" que seguirá al mouse mientras se arrastra la pieza
	ghost = Control.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 1000
	
	var preview_texture = TextureRect.new()
	preview_texture.texture = pieza.icon
	preview_texture.expand_mode = 1
	preview_texture.size = Vector2(25, 25)
	preview_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.add_child(preview_texture)
	ghost.size = Vector2(25, 25)
	
	get_viewport().add_child(ghost)
	var mouse_pos = get_global_mouse_position()
	ghost.global_position = mouse_pos - Vector2(12.5, 12.5)
	
	# Preview invisible requerido por el sistema de drag and drop de Godot
	var invisible_preview = Control.new()
	invisible_preview.size = Vector2(1, 1)
	invisible_preview.visible = false
	set_drag_preview(invisible_preview)
	
	# Vacía la casilla a nivel lógico y visual mientras se arrastra
	pieza = null
	_piece_update()
	# Los datos que se arrastran son la pieza, no solo la textura
	return pieza_bk

func _process(_delta):
	# Mientras exista el ghost, lo hace seguir la posición del mouse
	if ghost != null and ghost.is_inside_tree():
		var mouse_pos = get_global_mouse_position()
		ghost.global_position = mouse_pos - Vector2(12.5,5)

	
func _notification(what:int) -> void:
	# Notificación especial para saber cuándo termina el drag and drop
	if what == Node.NOTIFICATION_DRAG_END:
		if ghost != null:
			if ghost.is_inside_tree():
				ghost.queue_free()
			ghost = null
		
		if is_drag_successful():
			# El arrastre terminó bien, ya no necesitamos la pieza anterior
			pieza_bk = null
			emit_signal("sin_pieza")
			
		else:
			if pieza == null:
				# El arrastre falló, restauramos la pieza original e icono
				pieza = pieza_bk
				_piece_update()
				pieza_bk = null
