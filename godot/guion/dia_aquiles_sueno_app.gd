## Wiring nocturno de Aquiles dentro del recorrido real (#435/#438).
##
## El selector común decide si Aquiles puede contaminar esta noche. Este
## controller solo materializa el vertical en la escena que le asigna
## `MitologiasNoche`, conservando sala y salida genéricas.
extends Node

const ESCALA_ENCUENTRO := 0.62

var _mundo_montado_id := 0
var _aquiles_montado_esta_noche := false
var _fase_anterior := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var fase := String(dia.jornada.get("fase", ""))
	if fase != _fase_anterior:
		if fase != "sueño":
			_aquiles_montado_esta_noche = false
		_fase_anterior = fase
	if fase != "sueño":
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_montado_id:
		return
	_mundo_montado_id = mundo_id
	if _aquiles_montado_esta_noche:
		return

	var seleccion := (
		SemillasOniricas
		. seleccionar_para_noche(
			dia.jornada,
			dia._raiz(),
			MitologiasNoche.MAX_FAMILIAS_NOCHE,
		)
	)
	var familias: Array = seleccion.get("familias", [])
	if not _corresponde_a_esta_escena(dia, familias):
		return

	_montar_aquiles(mundo, dia._espacio_actual)
	_aquiles_montado_esta_noche = true


func _corresponde_a_esta_escena(dia: Node, familias: Array) -> bool:
	var opciones: Dictionary = dia._opciones_sueno()
	var cantidad := clampi(
		int(opciones.get("cantidad", Sueno.ESCENAS_POR_NOCHE)),
		1,
		SuenoFormas.ids().size(),
	)
	var pendientes: Array = dia.jornada.get("sueno_escenas", [])
	return (
		MitologiasNoche
		. corresponde_a_escena(
			SuenoAquiles.ID_MITO,
			familias,
			cantidad,
			pendientes.size(),
		)
	)


func _montar_aquiles(mundo: Node3D, espacio: Dictionary) -> void:
	if mundo.get_node_or_null("SuenoAquilesNoche") != null:
		return

	var aquiles := SuenoAquilesAlineacion.new()
	aquiles.name = "SuenoAquilesNoche"
	aquiles.reduccion_movimiento = bool(
		PreferenciasSiga.cargar().get("reduccion_movimiento", false)
	)
	# Preparar fuera del árbol permite retirar la cámara standalone antes de
	# que pueda hacerse current y robarle la vista al Caminante de Dia.
	aquiles.preparar()
	var camara := aquiles.get_node_or_null("CamaraStandalone")
	if camara != null:
		aquiles.remove_child(camara)
		camara.free()

	aquiles.scale = Vector3.ONE * ESCALA_ENCUENTRO
	aquiles.position = _ancla_entre_entrada_y_salida(espacio)
	mundo.add_child(aquiles)
	_orientar_segun_recorrido(aquiles, mundo, espacio)


## El vertical standalone fue compuesto con reflector y sello en su lado +Z.
## Hacer que -Z mire a la salida deja esos interactuables del lado por el que
## llega el jugador, independientemente de la orientación de la forma nocturna.
func _orientar_segun_recorrido(
	aquiles: Node3D,
	mundo: Node3D,
	espacio: Dictionary,
) -> void:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = espacio.get("salidas", [])
	if salidas.is_empty():
		return
	var salida: Vector3 = salidas[0].get("pos", entrada)
	var direccion := salida - entrada
	direccion.y = 0.0
	if direccion.length_squared() <= 0.0001:
		return
	aquiles.look_at(mundo.to_global(salida), Vector3.UP)


## Colocar la capa en mitad del recorrido conserva tanto la entrada como la
## salida genéricas y evita inventar coordenadas específicas de una forma.
func _ancla_entre_entrada_y_salida(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = espacio.get("salidas", [])
	if salidas.is_empty():
		return entrada
	var salida: Vector3 = salidas[0].get("pos", entrada)
	return entrada.lerp(salida, 0.5)


func aquiles_montado_esta_noche() -> bool:
	return _aquiles_montado_esta_noche
