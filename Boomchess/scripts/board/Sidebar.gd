extends GridContainer


@export var textura : Texture2D
@export var columnas : int 
@export var filas : int

signal perder

@export var piezas : Array[Pieza] = [] # Piezas que aparecerán en el sidebar (filas*columnas)

@export var tile_scene: PackedScene = preload("res://Boomchess/scenes/ui/PanelSidebar.tscn")

func _ready() -> void:
	# Configura el número de columnas del GridContainer
	columns = columnas
	# Limpia cualquier hijo previo (por si se reusa la escena)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	# Crea las casillas según filas y columnas, con nombres tipo "1_1", "1_2", "2_1", etc.
	for fila in range(filas):
		for col in range(columnas):
			var tile := tile_scene.instantiate()
			
			# Nombre en formato "fila_columna" (empezando en 1)
			tile.name = str(fila + 1) + "_" + str(col + 1)
			
			# Índice lineal dentro del array piezas para este slot del sidebar
			var idx := fila * columnas + col
			if idx < piezas.size():
				tile.pieza = piezas[idx]
				tile._piece_update()
			tile.sin_pieza.connect(_on_tile_sin_pieza)
			add_child(tile)
			# Crea un Sprite2D hijo en cada tile con textura alternada (patrón de tablero)
			if textura != null:
				var sprite := Sprite2D.new()
				sprite.centered = false
				sprite.position = Vector2.ZERO
				sprite.z_index = -1  # siempre por debajo de todo
				if (fila + col) % 2 == 0:
					sprite.texture = textura
				else:
					sprite.texture = textura

				# Ajusta el tamaño visual del sprite al tamaño del panel/tile
				var tile_size: Vector2 = tile.size
				if tile_size == Vector2.ZERO:
					tile_size = tile.custom_minimum_size
				if sprite.texture != null:
					var tex_size: Vector2 = sprite.texture.get_size()
					if tex_size.x != 0 and tex_size.y != 0:
						sprite.scale = Vector2(
							tile_size.x / tex_size.x,
							tile_size.y / tex_size.y
						)
				tile.add_child(sprite)


# Función que se ejecutará cuando cualquier tile emita "sin_pieza"
func _on_tile_sin_pieza():
	
	# Actualizar el array de piezas (opcional, depende de tu lógica)
	# Aquí puedes contar cuántas piezas quedan en el sidebar
	
	var piezas_restantes = 0
	for child in get_children():
		if child is TextureRect and child.pieza != null:
			piezas_restantes += 1
	
	
	if piezas_restantes == 0:
		if $"../Label".visible == false:
			$"../Label".text = "Lose"
			$"../Label".visible = true
