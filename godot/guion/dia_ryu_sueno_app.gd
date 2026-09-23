## Wiring nocturno de Ryū dentro del recorrido real (#435/#440).
##
## SemillasOniricas selecciona familias y MitologiasNoche asigna escena. Esta
## capa solo materializa el vertical 3D sin sustituir sala, entrada ni salida.
extends Node

var _mundo_montado_id := 0
var _ryu_montado_esta_noche := false
var _fase_anterior := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var fase := String(dia.jornada.get("fase", ""))
	if fase != _fase_anterior:
		if fase != "sueño":
			_ryu_montado_esta_noche = false
		_fase_anterior = fase
	if fase != "sueño":
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_montado_id:
		return
	_mundo_montado_id = mundo_id
	if _ryu_montado_esta_noche:
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

	_montar_ryu(mundo, dia._espacio_actual)
	_ryu_montado_esta_noche = true


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
			SuenoRyu.ID_MITO,
			familias,
			cantidad,
			pendientes.size(),
		)
	)


func _montar_ryu(mundo: Node3D, espacio: Dictionary) -> void:
	if mundo.get_node_or_null("SuenoRyuNoche") != null:
		return

	var ryu := SuenoRyu.new()
	ryu.name = "SuenoRyuNoche"
	ryu.reduccion_movimiento = bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))
	# Se prepara fuera del árbol para que reducción de movimiento determine
	# desde el inicio la densidad de lluvia y no exista cámara standalone.
	ryu.preparar()
	ryu.scale = Vector3.ONE * SuenoRyu.ESCALA_ENCUENTRO
	ryu.position = _ancla_entre_entrada_y_salida(espacio)
	mundo.add_child(ryu)


func _ancla_entre_entrada_y_salida(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = espacio.get("salidas", [])
	if salidas.is_empty():
		return entrada
	var salida: Vector3 = salidas[0].get("pos", entrada)
	return entrada.lerp(salida, 0.5)


func ryu_montado_esta_noche() -> bool:
	return _ryu_montado_esta_noche
