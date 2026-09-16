## Wiring nocturno del Minotauro dentro del recorrido real (#435/#437).
##
## SemillasOniricas selecciona familias y MitologiasNoche asigna escena. Esta
## capa solo materializa el vertical 3D y conserva sala, entrada y salida.
extends Node

const ESCALA_ENCUENTRO := 0.72

var _mundo_montado_id := 0
var _minotauro_montado_esta_noche := false
var _fase_anterior := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var fase := String(dia.jornada.get("fase", ""))
	if fase != _fase_anterior:
		if fase != "sueño":
			_minotauro_montado_esta_noche = false
		_fase_anterior = fase
	if fase != "sueño":
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_montado_id:
		return
	_mundo_montado_id = mundo_id
	if _minotauro_montado_esta_noche:
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

	_montar_minotauro(mundo, dia._espacio_actual)
	_minotauro_montado_esta_noche = true


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
			SuenoMinotauro3D.ID_MITO,
			familias,
			cantidad,
			pendientes.size(),
		)
	)


func _montar_minotauro(mundo: Node3D, espacio: Dictionary) -> void:
	if mundo.get_node_or_null("SuenoMinotauroNoche") != null:
		return

	var minotauro := SuenoMinotauro3D.new()
	minotauro.name = "SuenoMinotauroNoche"
	minotauro.reduccion_movimiento = bool(
		PreferenciasSiga.cargar().get("reduccion_movimiento", false)
	)
	minotauro.preparar()
	minotauro.scale = Vector3.ONE * ESCALA_ENCUENTRO
	minotauro.position = _ancla_entre_entrada_y_salida(espacio)
	mundo.add_child(minotauro)


func _ancla_entre_entrada_y_salida(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = espacio.get("salidas", [])
	if salidas.is_empty():
		return entrada
	var salida: Vector3 = salidas[0].get("pos", entrada)
	return entrada.lerp(salida, 0.5)


func minotauro_montado_esta_noche() -> bool:
	return _minotauro_montado_esta_noche
