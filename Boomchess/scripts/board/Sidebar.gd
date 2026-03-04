extends GridContainer


@export var nivel : String
@export var textura : Texture2D
@export var columnas : int 
@export var filas : int

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
			
			add_child(tile)
