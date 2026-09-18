## Wiring del vertical Tír na nÓg al recorrido real (#654).
##
## La semilla procede de superficies comunes de vigilia (la minicadena doméstica)
## y esta capa solo materializa el vertical cuando la selección nocturna de #442
## asigna Tír na nÓg a la escena actual. No añade un selector paralelo.
extends Node

const ESCALA_SUENO := 0.62

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

	if fase != "sueño" or _sueno_montado_esta_noche:
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
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
			SuenoTirNaNog.ID_MITO,
			familias,
			cantidad,
			pendientes.size(),
		)
	)


func _montar_sueno(mundo: Node3D, espacio: Dictionary) -> void:
	if mundo.get_node_or_null("SuenoTirNaNogNoche") != null:
		return
	var tir := SuenoTirNaNog.new()
	tir.name = "SuenoTirNaNogNoche"
	tir.reduccion_movimiento = bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))
	tir.scale = Vector3.ONE * ESCALA_SUENO
	tir.position = _ancla_entre_entrada_y_salida(espacio)
	mundo.add_child(tir)
	# La escena standalone crea cámara y luz propias; dentro del ciclo real debe
	# conservar la cámara/iluminación del sueño base para no secuestrar la vista.
	for nombre in ["Camara", "Luz"]:
		var nodo := tir.get_node_or_null(nombre)
		if nodo != null:
			tir.remove_child(nodo)
			nodo.free()


func _ancla_entre_entrada_y_salida(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = espacio.get("salidas", [])
	if salidas.is_empty():
		return entrada
	var salida: Vector3 = salidas[0].get("pos", entrada)
	return entrada.lerp(salida, 0.5)


func sueno_montado_esta_noche() -> bool:
	return _sueno_montado_esta_noche
