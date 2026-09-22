## Wiring del vertical de Mari al recorrido real (#651).
##
## El folleto solo aparece en la vivienda real y no activa nada por presencia.
## Durante el sueño se consume exclusivamente la selección común de #442 y
## MitologiasNoche decide en qué escena se materializa el paisaje climático.
extends Node

const POSICION_FOLLETO := Vector3(-1.55, 0.86, 2.45)
const ESCALA_SUENO := 0.58

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
			_montar_folleto(mundo, dia.jornada)
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


func _montar_folleto(mundo: Node3D, jornada: Dictionary) -> void:
	if mundo.get_node_or_null("MariFolletoCasa") != null:
		return
	var folleto := MariVigilia.new()
	folleto.name = "MariFolletoCasa"
	folleto.position = POSICION_FOLLETO
	mundo.add_child(folleto)
	folleto.configurar(jornada)


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
			SuenoMari.ID_MITO,
			familias,
			cantidad,
			pendientes.size(),
		)
	)


func _montar_sueno(mundo: Node3D, espacio: Dictionary) -> void:
	if mundo.get_node_or_null("SuenoMariNoche") != null:
		return
	var mari := SuenoMari.new()
	mari.name = "SuenoMariNoche"
	mari.reduccion_movimiento = bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))
	mari.scale = Vector3.ONE * ESCALA_SUENO
	mari.position = _ancla_entre_entrada_y_salida(espacio)
	mundo.add_child(mari)
	var camara := mari.get_node_or_null("CamaraStandalone")
	if camara != null:
		mari.remove_child(camara)
		camara.free()


func _ancla_entre_entrada_y_salida(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = espacio.get("salidas", [])
	if salidas.is_empty():
		return entrada
	var salida: Vector3 = salidas[0].get("pos", entrada)
	return entrada.lerp(salida, 0.5)


func sueno_montado_esta_noche() -> bool:
	return _sueno_montado_esta_noche
