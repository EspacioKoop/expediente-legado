## Arbolado CC0 de fondo en el trayecto (#219/#216).
##
## Controller hijo: solo añade geometría decorativa cuando existe el mundo del
## trayecto. Los árboles quedan detrás de las fachadas o al final del eje de la
## calle, donde se leen como patios y periferia; nunca sobre acera ni calzada.
## No cambia navegación, colisiones, jornada ni puntos interactivos.
extends Node

const INSTANCIAS_ARBOLES := 6
const DRAW_CALLS_BASE_MAX := 12

var _mundo_montado_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	if String(dia.jornada.get("fase", "")) != "trayecto":
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_montado_id:
		return
	_mundo_montado_id = mundo_id
	_montar_arbolado(mundo)


func _montar_arbolado(mundo: Node3D) -> void:
	# Las fachadas miden ~10 m y están a |x| ≈ 5,5: un árbol de tamaño real queda
	# oculto, y uno pegado a ellas atraviesa el muro con la copa. Son ejemplares
	# de patio (12-16 m) lo bastante atrás (|x| >= 10,5) para que solo asome la
	# silueta por encima de los tejados.
	_arbol(mundo, 0, ArbolesQuaternius.FRONDOSO, Vector3(-10.5, 0.0, -6.0), 2.20, 24.0)
	_arbol(mundo, 1, ArbolesQuaternius.PINO, Vector3(-11.5, 0.0, 5.0), 1.90, 60.0)
	_arbol(mundo, 2, ArbolesQuaternius.DESNUDO, Vector3(11.0, 0.0, -8.0), 2.10, -40.0)
	_arbol(mundo, 3, ArbolesQuaternius.FRONDOSO, Vector3(11.5, 0.0, 7.0), 2.30, 115.0)
	# Remates del eje: periferia detrás de los edificios que cierran la calle.
	_arbol(mundo, 4, ArbolesQuaternius.PINO, Vector3(3.0, 0.0, -24.0), 2.00, -15.0)
	_arbol(mundo, 5, ArbolesQuaternius.DESNUDO, Vector3(-3.5, 0.0, 25.0), 2.20, 70.0)


func _arbol(
	mundo: Node3D, indice: int, modelo: String, posicion: Vector3, escala: float, giro_y: float
) -> void:
	var arbol := ArbolesQuaternius.crear(modelo)
	arbol.name = "Arbol%d_%s" % [indice, modelo.get_basename()]
	arbol.position = posicion
	arbol.scale = Vector3.ONE * escala
	arbol.rotation_degrees.y = giro_y
	mundo.add_child(arbol)
