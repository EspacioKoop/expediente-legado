## Wiring nocturno de Aquiles dentro del recorrido real (#435/#438).
##
## El selector común decide si Aquiles puede contaminar esta noche. Este
## controller solo materializa el vertical ya existente en la primera escena
## del sueño seleccionada para la jornada. Mantiene la sala base y su salida:
## Aquiles es una capa interactiva del sueño, no un segundo gestor de fases.
extends Node

const ESCALA_ENCUENTRO := 0.62
const MAX_FAMILIAS_NOCHE := 2

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

	if _aquiles_montado_esta_noche or not _es_primera_escena(dia):
		return
	var seleccion := (
		SemillasOniricas
		. seleccionar_para_noche(
			dia.jornada,
			dia._raiz(),
			MAX_FAMILIAS_NOCHE,
		)
	)
	var familias: Array = seleccion.get("familias", [])
	if not familias.has(SuenoAquiles.ID_MITO):
		return

	_montar_aquiles(mundo, dia._espacio_actual)
	_aquiles_montado_esta_noche = true


## El encuentro entra una vez, al principio de la noche. Así una semilla no
## convierte las tres salas en tres copias del mismo mito y recargar a mitad de
## noche no reinyecta Aquiles en una escena posterior.
func _es_primera_escena(dia: Node) -> bool:
	var opciones: Dictionary = dia._opciones_sueno()
	var cantidad := clampi(
		int(opciones.get("cantidad", Sueno.ESCENAS_POR_NOCHE)),
		1,
		SuenoFormas.ids().size(),
	)
	var pendientes: Array = dia.jornada.get("sueno_escenas", [])
	return pendientes.size() == cantidad


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
