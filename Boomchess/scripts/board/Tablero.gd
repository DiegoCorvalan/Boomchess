extends GridContainer

@export var textura1 : Texture2D
@export var textura2 : Texture2D
@export var columnas : int 
@export var filas : int

@export var piezas : Array[Pieza] = [] # Lista de piezas para cada casilla (fila*columnas)

@export var tile_scene: PackedScene = preload("res://Boomchess/scenes/board/Board.tscn")

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

			# Crea un Sprite2D hijo en cada tile con textura alternada (patrón de tablero)
			if textura1 != null and textura2 != null:
				var sprite := Sprite2D.new()
				sprite.centered = false
				sprite.position = Vector2.ZERO
				sprite.z_index = -10  # siempre por debajo de todo
				if (fila + col) % 2 == 0:
					sprite.texture = textura1
				else:
					sprite.texture = textura2

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
			
			# Índice lineal para esta casilla dentro del array piezas
			var idx := fila * columnas + col
			if idx < piezas.size():
				tile.pieza = piezas[idx]
				tile._piece_update()
			
			add_child(tile)
