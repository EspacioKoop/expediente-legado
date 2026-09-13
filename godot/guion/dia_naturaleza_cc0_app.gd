## Dressing natural CC0 para los márgenes del trayecto (#229/#216).
##
## Controller hijo: solo añade geometría decorativa cuando existe el mundo del
## trayecto. No cambia navegación, colisiones, jornada ni puntos interactivos.
extends Node

const INSTANCIAS_NATURALEZA := 8
const DRAW_CALLS_BASE_MAX := 8

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
	_montar_periferia(mundo)


func _montar_periferia(mundo: Node3D) -> void:
	# La calle mide 9 m de ancho. Estas piezas se pegan a sus dos bordes y no
	# tienen cuerpo físico: rompen la línea dura del escenario sin cerrar el paso.
	_pieza(mundo, NaturalezaQuaternius.ARBUSTO_1, Vector3(-4.18, 0.0, -12.5), 0.72, -18.0)
	_pieza(mundo, NaturalezaQuaternius.ARBUSTO_2, Vector3(4.12, 0.0, -8.4), 0.82, 31.0)
	_pieza(mundo, NaturalezaQuaternius.ROCA_1, Vector3(-4.05, 0.0, -5.0), 1.35, 12.0)
	_pieza(mundo, NaturalezaQuaternius.ROCA_5, Vector3(4.16, 0.0, -1.8), 1.10, -27.0)
	_pieza(mundo, NaturalezaQuaternius.ARBUSTO_2, Vector3(-4.12, 0.0, 3.8), 0.76, 23.0)
	_pieza(mundo, NaturalezaQuaternius.ROCA_5, Vector3(-4.20, 0.0, 8.2), 1.25, 41.0)
	_pieza(mundo, NaturalezaQuaternius.ARBUSTO_1, Vector3(4.08, 0.0, 11.6), 0.68, -36.0)
	_pieza(mundo, NaturalezaQuaternius.ROCA_1, Vector3(4.20, 0.0, 14.2), 1.45, 8.0)


func _pieza(
	mundo: Node3D, modelo: String, posicion: Vector3, escala: float, giro_y: float
) -> void:
	var pieza := NaturalezaQuaternius.crear(modelo)
	pieza.name = "Naturaleza_%s" % modelo.get_basename()
	pieza.position = posicion
	pieza.scale = Vector3.ONE * escala
	pieza.rotation_degrees.y = giro_y
	mundo.add_child(pieza)
