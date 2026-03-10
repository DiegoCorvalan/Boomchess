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
	var destino_fila = null
	var destino_columna = null
	# Mueve la pieza según su Vector2 movimiento y el nombre de la casilla (por ej. "3_2" -> "4_2")
	if not pieza:
		return
	# Nombre de esta casilla, esperado en formato "fila_columna" (por ejemplo "3_2" o "3.2")
	var poder = pieza.poder
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
	var no_tiene := ""
	if tipo == "continuo":
		# Avanza casilla por casilla hasta el borde (o hasta chocar con una pieza)
		var candidata_fila := fila + paso_fila
		var candidata_col := col + paso_col
		var ultima_ok_fila := fila
		var ultima_ok_col := col
		
		while true:
			var candidato_nombre := str(candidata_fila) + sep + str(candidata_col)

			if not grid.has_node(candidato_nombre):
				no_tiene = candidato_nombre
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
		destino_fila = ultima_ok_fila
		destino_columna = ultima_ok_col
	else:
		# exacto (o cualquier valor desconocido): solo mueve 1 vez
		var nueva_fila := fila + paso_fila
		var nueva_col := col + paso_col
		destino_nombre = str(nueva_fila) + sep + str(nueva_col)
		destino_fila = nueva_fila
		destino_columna = nueva_col
	
	if not grid.has_node(destino_nombre):
		return
	
	var destino := grid.get_node(destino_nombre)
	
	# Si hay una pieza amiga en el destino, no se mueve; si es enemigo, se permite (y se mostrará el label).
	if destino.pieza != null and destino.pieza.tipo != "enemigo":
		return
	
	# Animación visual: solo se mueve un sprite "fantasma" con el icono de la pieza,
	# el Tile y el fondo permanecen quietos en el GridContainer.
	var origen_pos: Vector2 = global_position
	var destino_pos: Vector2 = destino.global_position
	
	var root := get_tree().current_scene
	if root == null:
		root = get_parent()
	if root == null:
		return
	
	print("Animacion ",pieza.nombre)
	var ghost_animation := Sprite2D.new()
	ghost_animation.texture = pieza.icon
	ghost_animation.scale = Vector2(0.16, 0.16)  # más pequeño durante toda la animación (20,20)
	ghost_animation.global_position = origen_pos + Vector2(10, 10)
	destino_pos = destino_pos + Vector2(10,10)
	ghost_animation.z_index = 100
	root.add_child(ghost_animation)
	var pieza_bk2 = pieza
	pieza = null
	_piece_update()
	var tween := create_tween()
	tween.tween_property(
		ghost_animation,               # Nodo a animar (solo la pieza)
		"global_position",   # Propiedad que se anima
		destino_pos,         # Posición final
		1                  # Duración en segundos
	)
	# Cuando termine la animación, actualizamos el estado lógico del tablero
	tween.finished.connect(func ():
		ghost_animation.queue_free()
		
		if destino.pieza != null and destino.pieza.tipo == "enemigo":
			var label = $"../../Label"
			if label:
				label.text = "Win"
				label.visible = true
		
		destino.pieza = pieza_bk2
		destino._piece_update()
		pieza_bk2 = null
		_power(destino_columna, destino_fila, poder, no_tiene)
	)


func _power(col, fila, poder, no_tiene):
	var grid := get_parent()
	
	if poder == "explosion":
		var fila1 = fila + 1
		var filam1 = fila - 1
		var col1 = col + 1
		var colm1 = col - 1
		
		var positions = [
			str(filam1) + "_" + str(colm1),
			str(filam1) + "_" + str(col),
			str(filam1) + "_" + str(col1),
			str(fila) + "_" + str(colm1),
			str(fila) + "_" + str(col1),
			str(fila1) + "_" + str(colm1),
			str(fila1) + "_" + str(col),
			str(fila1) + "_" + str(col1)
		]
		
		var node = grid.get_node(str(str(fila) + "_" + str(col)))
		$AnimatedSprite2D.global_position = node.global_position + Vector2(12,12)
		$AnimatedSprite2D.visible = true
		$AnimatedSprite2D.play()
		for pos in positions:
			var candidato := grid.get_node(pos)
			if candidato != null:
				if candidato.pieza != null:
					if candidato.pieza.tipo != "enemigo":
						candidato.pieza = null
						candidato.texture = null
	
	if poder == "rebote":
		var actual = grid.get_node(str(str(fila) + "_" + str(col)))
		var partes := str(no_tiene).split("_")
		if partes.size() != 2:
			return
		fila = int(partes[0])
		col = int(partes[1])
		print(actual,partes)
		if fila == 0:
			actual.pieza.movimiento.y = -(actual.pieza.movimiento.y)
		if col == 0:
			actual.pieza.movimiento.x = -(actual.pieza.movimiento.x)
		actual.pieza.poder = ""
		actual._movment()
		

func _on_mouse_exited():
	$Panel.visible = false # Replace with function body.
