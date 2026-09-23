## Wiring de Simurgh al recorrido real (#658).
##
## La lámina se monta únicamente en la vivienda real y exige interacción
## deliberada. Durante el sueño se consume la selección común de #442 y
## MitologiasNoche decide en qué escena se materializa el cambio de escala.
extends Node

const POSICION_LAMINA := Vector3(-3.4, 1.35, 4.3)
const GIRO_LAMINA := 180.0
const ESCALA_SUENO := 0.42

var _mundo_casa_id := 0
var _mundo_sueno_id := 0
var _sueno_montado_esta_noche := false
var _fase_anterior := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var fase := String(dia.jornada.get("fase", ""))
	if fase != _fase_anterior:
		if fase != "sueño":
			_sueno_montado_esta_noche = false
		_fase_anterior = fase

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if fase == "casa":
		if String(dia._vivienda()) != "casa":
			return
		if mundo_id != _mundo_casa_id:
			_mundo_casa_id = mundo_id
			_montar_lamina(mundo, dia.jornada)
		return

	if fase != "sueño" or _sueno_montado_esta_noche:
		return
	if mundo_id == _mundo_sueno_id:
		return
	_mundo_sueno_id = mundo_id

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

	_montar_sueno(mundo, dia._espacio_actual)
	_sueno_montado_esta_noche = true


func _montar_lamina(mundo: Node3D, jornada: Dictionary) -> void:
	if mundo.get_node_or_null("SimurghLaminaCasa") != null:
		return
	var lamina := SimurghVigilia.new()
	lamina.name = "SimurghLaminaCasa"
	lamina.position = POSICION_LAMINA
	lamina.rotation_degrees.y = GIRO_LAMINA
	mundo.add_child(lamina)
	lamina.configurar(jornada)


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
			SuenoSimurgh.ID_MITO,
			familias,
			cantidad,
			pendientes.size(),
		)
	)


func _montar_sueno(mundo: Node3D, espacio: Dictionary) -> void:
	if mundo.get_node_or_null("SuenoSimurghNoche") != null:
		return

	var simurgh := SuenoSimurgh.new()
	simurgh.name = "SuenoSimurghNoche"
	simurgh.reduccion_movimiento = bool(
		PreferenciasSiga.cargar().get("reduccion_movimiento", false)
	)
	simurgh.preparar()

	# El harness standalone crea cámara y luz. En el ciclo real se conservan las
	# del sueño base para no secuestrar la vista ni duplicar iluminación.
	for nombre in ["CamaraStandalone", "LuzGeneral"]:
		var nodo := simurgh.get_node_or_null(nombre)
		if nodo != null:
			simurgh.remove_child(nodo)
			nodo.free()

	simurgh.scale = Vector3.ONE * ESCALA_SUENO
	simurgh.position = _ancla_entre_entrada_y_salida(espacio)
	mundo.add_child(simurgh)


func _ancla_entre_entrada_y_salida(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = espacio.get("salidas", [])
	if salidas.is_empty():
		return entrada
	var salida: Vector3 = salidas[0].get("pos", entrada)
	return entrada.lerp(salida, 0.5)


func sueno_montado_esta_noche() -> bool:
	return _sueno_montado_esta_noche
