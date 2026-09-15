## Wiring nocturno de Gilgamesh dentro del recorrido real (#435/#436).
##
## `SemillasOniricas` decide si Gilgamesh sale y `MitologiasNoche` decide en qué
## escena se materializa. Este controller solo monta el vertical ya integrado.
extends Node

const ESCENA_GILGAMESH := preload("res://escenas/sueno_gilgamesh.tscn")
const ESCALA_ENCUENTRO := 0.44

var _mundo_montado_id := 0
var _gilgamesh_montado_esta_noche := false
var _fase_anterior := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var fase := String(dia.jornada.get("fase", ""))
	if fase != _fase_anterior:
		if fase != "sueño":
			_gilgamesh_montado_esta_noche = false
		_fase_anterior = fase
	if fase != "sueño":
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_montado_id:
		return
	_mundo_montado_id = mundo_id
	if _gilgamesh_montado_esta_noche:
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

	_montar_gilgamesh(mundo, dia._espacio_actual)
	_gilgamesh_montado_esta_noche = true


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
			SuenoGilgamesh.ID_MITO,
			familias,
			cantidad,
			pendientes.size(),
		)
	)


func _montar_gilgamesh(mundo: Node3D, espacio: Dictionary) -> void:
	if mundo.get_node_or_null("SuenoGilgameshNoche") != null:
		return

	var gilgamesh := ESCENA_GILGAMESH.instantiate() as SuenoGilgamesh
	if gilgamesh == null:
		return
	gilgamesh.name = "SuenoGilgameshNoche"
	# Igual que Aquiles: preparar antes de entrar en SceneTree para poder retirar
	# la cámara standalone antes de que se haga current.
	gilgamesh.preparar()
	var camara := gilgamesh.get_node_or_null("CamaraStandalone")
	if camara != null:
		gilgamesh.remove_child(camara)
		camara.free()

	gilgamesh.scale = Vector3.ONE * ESCALA_ENCUENTRO
	gilgamesh.position = _ancla_entre_entrada_y_salida(espacio)
	mundo.add_child(gilgamesh)


func _ancla_entre_entrada_y_salida(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = espacio.get("salidas", [])
	if salidas.is_empty():
		return entrada
	var salida: Vector3 = salidas[0].get("pos", entrada)
	return entrada.lerp(salida, 0.5)


func gilgamesh_montado_esta_noche() -> bool:
	return _gilgamesh_montado_esta_noche
