extends TextureRect # Cada casilla del tablero es un TextureRect

var pieza_bk : Pieza # Guarda la pieza original mientras se arrastra
var ghost : Control = null # Nodo "fantasma" que sigue al mouse durante el drag
@export var pieza : Pieza # Datos de la pieza que está en esta casilla

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


func _process(_delta):
	# Mientras exista el ghost, lo hace seguir la posición del mouse
	if ghost != null and ghost.is_inside_tree():
		var mouse_pos = get_global_mouse_position()
		ghost.global_position = mouse_pos - Vector2(12.5,5)
	
func _can_drop_data(_pos, data):
	# Solo acepta datos si la casilla no tiene pieza y lo que llega es una Pieza
	if pieza == null:
		$Panel.visible = true
		return data is Pieza
	
func _drop_data(_pos, data):
	# Cuando se suelta algo sobre esta casilla, asignamos la pieza y actualizamos el icono
	if data is Pieza:
		pieza = data
		_piece_update()
		_movment()
	
	
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
		else:
			if pieza == null:
				# El arrastre falló, restauramos la pieza original e icono
				pieza = pieza_bk
				_piece_update()
				pieza_bk = null

func _movment():
	# Mueve la pieza según su Vector2 movimiento y el nombre de la casilla (por ej. "3_2" -> "4_2")
	if not pieza:
		return
	
	# Nombre de esta casilla, esperado en formato "fila_columna" (por ejemplo "3_2" o "3.2")
	var sep := ""
	if name.contains("_"):
		sep = "_"
	elif name.contains("."):
		sep = "."
	else:
		return
	
	var partes := name.split(sep)
	if partes.size() != 2:
		return
	
	var fila := int(partes[0])
	var col := int(partes[1])
	
	var grid := get_parent()
	if grid == null:
		return
	
	# Aplicar el movimiento de la pieza: x = columnas, y = filas
	var paso_fila := int(pieza.movimiento.y)
	var paso_col := int(pieza.movimiento.x)
	if paso_fila == 0 and paso_col == 0:
		return
	
	var tipo := (pieza.tipo if pieza.tipo != null else "exacto").to_lower()
	
	var destino_nombre := ""
	
	if tipo == "continuo":
		# Avanza casilla por casilla hasta el borde (o hasta chocar con una pieza)
		var candidata_fila := fila + paso_fila
		var candidata_col := col + paso_col
		var ultima_ok_fila := fila
		var ultima_ok_col := col
		
		while true:
			var candidato_nombre := str(candidata_fila) + sep + str(candidata_col)

			if not grid.has_node(candidato_nombre):
				print(not grid.has_node(candidato_nombre))
				break
			var candidato := grid.get_node(candidato_nombre)
			if candidato.pieza != null:
				if candidato.pieza.tipo != "enemigo":
					break
			
			ultima_ok_fila = candidata_fila
			ultima_ok_col = candidata_col
			
			candidata_fila += paso_fila
			candidata_col += paso_col
		
		# Si no pudo avanzar ni una casilla, no se mueve
		if ultima_ok_fila == fila and ultima_ok_col == col:
			return
		
		destino_nombre = str(ultima_ok_fila) + sep + str(ultima_ok_col)
	else:
		# exacto (o cualquier valor desconocido): solo mueve 1 vez
		var nueva_fila := fila + paso_fila
		var nueva_col := col + paso_col
		destino_nombre = str(nueva_fila) + sep + str(nueva_col)
	
	if not grid.has_node(destino_nombre):
		return
	
	var destino := grid.get_node(destino_nombre)
	
	# Animación visual del movimiento de la pieza desde esta casilla hasta la casilla destino
	var origen_pos: Vector2 = global_position
	var destino_pos: Vector2 = destino.global_position
	
	var tween := create_tween()
	tween.tween_property(
		self,                # Nodo a animar (esta casilla / pieza visual)
		"global_position",   # Propiedad que se anima
		destino_pos,         # Posición final
		0.3                  # Duración en segundos
	)
	
	# Cuando termine la animación, actualizamos el estado lógico del tablero
	tween.finished.connect(func ():
		# Solo mover si el destino no tiene pieza
		if destino.pieza != null:
			if destino.pieza.tipo != "enemigo":
				global_position = origen_pos
				return
			else:
				var label = $"../../Label"
				label.visible = true
		
		destino.pieza = pieza
		destino._piece_update()
		
		pieza = null
		_piece_update()
		
		# Volver a colocar este nodo en su posición original del GridContainer
		global_position = origen_pos
	)


func _on_mouse_exited():
	$Panel.visible = false # Replace with function body.
