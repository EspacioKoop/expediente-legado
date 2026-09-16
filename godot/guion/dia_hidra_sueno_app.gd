## Wiring nocturno de la Hidra dentro del recorrido real (#435/#439).
##
## SemillasOniricas decide si la familia sale y MitologiasNoche le asigna una
## escena. Esta capa monta el vertical interactuable sobre la sala ya existente,
## sin sustituir entrada/salida ni introducir selección paralela.
extends Node

const ESCALA_ENCUENTRO := 0.58

var _mundo_montado_id := 0
var _hidra_montada_esta_noche := false
var _fase_anterior := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var fase := String(dia.jornada.get("fase", ""))
	if fase != _fase_anterior:
		if fase != "sueño":
			_hidra_montada_esta_noche = false
		_fase_anterior = fase
	if fase != "sueño":
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_montado_id:
		return
	_mundo_montado_id = mundo_id
	if _hidra_montada_esta_noche:
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

	_montar_hidra(mundo, dia._espacio_actual, dia)
	_hidra_montada_esta_noche = true


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
			SuenoHidraInteraccion3D.ID_MITO,
			familias,
			cantidad,
			pendientes.size(),
		)
	)


func _montar_hidra(mundo: Node3D, espacio: Dictionary, dia: Node) -> void:
	if mundo.get_node_or_null("SuenoHidraNoche") != null:
		return

	var hidra := SuenoHidraInteraccion3D.new()
	hidra.name = "SuenoHidraNoche"
	hidra.scale = Vector3.ONE * ESCALA_ENCUENTRO
	hidra.position = _ancla_entre_entrada_y_salida(espacio)
	mundo.add_child(hidra)

	var semillas := SemillasOniricas.obtener_semillas(dia.jornada)
	var reduccion := PreferenciasSiga.cargar().get("reduccion_movimiento", false) == true
	hidra.configurar(semillas, reduccion, dia._raiz())


func _ancla_entre_entrada_y_salida(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = espacio.get("salidas", [])
	if salidas.is_empty():
		return entrada
	var salida: Vector3 = salidas[0].get("pos", entrada)
	return entrada.lerp(salida, 0.5)


func hidra_montada_esta_noche() -> bool:
	return _hidra_montada_esta_noche
