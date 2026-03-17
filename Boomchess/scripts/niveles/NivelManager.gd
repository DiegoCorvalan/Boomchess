extends Control

@export var nivel: Resource
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"1".pressed.connect(_on__pressed.bind("1"))
	$"2".pressed.connect(_on__pressed.bind("2"))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on__pressed(name: String) -> void:
	var path_nivel : String = "res://Boomchess/scripts/niveles/" + name + ".tres"
	var datos : Nivel = load(path_nivel)

	var escena = load("res://Boomchess/scenes/ui/Principal.tscn").instantiate()

	var tablero = escena.get_node("Tablero")
	var sidebar = escena.get_node("Sidebar")

	tablero.columnas = datos.columnas
	tablero.filas = datos.filas
	tablero.textura1 = datos.textura1
	tablero.textura2 = datos.textura2
	tablero.piezas = datos.obstaculos
	
	sidebar.textura =  datos.sidebarTextura
	sidebar.columnas = datos.sidebarColumnas
	sidebar.filas = datos.sidebarFilas
	sidebar.piezas = datos.sidebarPiezas
	

	get_tree().root.add_child(escena)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = escena
