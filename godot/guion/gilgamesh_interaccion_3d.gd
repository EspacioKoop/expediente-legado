## Controles 3D del puzzle de Gilgamesh (#436).
##
## La escena ya sabe evaluar cuatro parejas fragmento/ancla. Este controller
## convierte ese contrato lógico en interacción física reutilizando
## `Interactuable3D`: primero se selecciona un fragmento y después se intenta
## colocarlo en un anclaje. Un fallo no consume progreso ni suelta la pieza.
extends Node

var _montada := false
var _fragmento_seleccionado := ""
var _reduccion_movimiento := false
var _fragmentos_interactivos: Dictionary = {}
var _anclas_interactivas: Dictionary = {}


func _process(_delta: float) -> void:
	if _montada:
		return
	var sueno := get_parent() as SuenoGilgamesh
	if sueno == null:
		return
	var puzzle := sueno.get_node_or_null("CiudadImposible/PuzzleTablilla") as Node3D
	if puzzle == null:
		return

	_reduccion_movimiento = bool(
		PreferenciasSiga.cargar().get("reduccion_movimiento", false)
	)
	_montar_interacciones(sueno, puzzle)
	_montada = true
	set_process(false)


func fragmento_seleccionado() -> String:
	return _fragmento_seleccionado


func _montar_interacciones(sueno: SuenoGilgamesh, puzzle: Node3D) -> void:
	var ids: Array = SuenoGilgamesh.ENCAJES.keys()
	ids.sort()
	for valor in ids:
		var fragmento := String(valor)
		var ancla_id := String(SuenoGilgamesh.ENCAJES[fragmento])
		var pieza := puzzle.get_node_or_null(fragmento) as MeshInstance3D
		var ancla := puzzle.get_node_or_null(ancla_id) as MeshInstance3D
		if pieza == null or ancla == null:
			continue
		var tamano: Vector3 = SuenoGilgamesh.TAMANOS[fragmento]

		var zona_fragmento := _crear_interactuable(
			puzzle,
			"Interactuar_%s" % fragmento,
			pieza.position,
			tamano + Vector3(0.34, 0.34, 0.34),
			Interactuable3D.Verbo.COGER,
			"fragmento de %s" % fragmento.trim_prefix("fragmento_"),
		)
		zona_fragmento.activado.connect(_al_fragmento_activado.bind(fragmento))
		_fragmentos_interactivos[fragmento] = zona_fragmento

		var zona_ancla := _crear_interactuable(
			puzzle,
			"Interactuar_%s" % ancla_id,
			ancla.position,
			tamano + Vector3(0.42, 0.22, 0.42),
			Interactuable3D.Verbo.USAR,
			"anclaje de %s" % ancla_id.trim_prefix("ancla_"),
		)
		zona_ancla.activado.connect(_al_ancla_activada.bind(ancla_id))
		_anclas_interactivas[ancla_id] = zona_ancla

	_actualizar_feedback_seleccion(sueno)


func _crear_interactuable(
	padre: Node3D,
	nombre: String,
	posicion: Vector3,
	tamano: Vector3,
	verbo: int,
	etiqueta: String,
) -> Interactuable3D:
	var zona := Interactuable3D.new()
	zona.name = nombre
	zona.position = posicion
	zona.verbo = verbo
	zona.nombre_objeto = etiqueta
	padre.add_child(zona)

	var colision := CollisionShape3D.new()
	colision.name = "Colision"
	var forma := BoxShape3D.new()
	forma.size = tamano
	colision.shape = forma
	zona.add_child(colision)
	return zona


func _al_fragmento_activado(_actor: Node, fragmento: String) -> void:
	var sueno := get_parent() as SuenoGilgamesh
	if sueno == null:
		return
	var pieza := (
		sueno.get_node_or_null("CiudadImposible/PuzzleTablilla/%s" % fragmento)
		as MeshInstance3D
	)
	if pieza == null or not pieza.visible:
		return
	_fragmento_seleccionado = fragmento
	_actualizar_feedback_seleccion(sueno)


func _al_ancla_activada(_actor: Node, ancla_id: String) -> void:
	if _fragmento_seleccionado.is_empty():
		return
	var sueno := get_parent() as SuenoGilgamesh
	if sueno == null:
		return

	var seleccionado := _fragmento_seleccionado
	var resultado := sueno.colocar_fragmento(
		seleccionado,
		ancla_id,
		_reduccion_movimiento,
	)
	if not bool(resultado["aceptada"]):
		# El contrato base exige reversión: conservar la selección permite probar
		# otro anclaje sin volver a recoger la pieza ni perder progreso.
		_actualizar_feedback_seleccion(sueno)
		return

	_deshabilitar(_fragmentos_interactivos.get(seleccionado) as Interactuable3D)
	_deshabilitar(_anclas_interactivas.get(ancla_id) as Interactuable3D)
	_fragmento_seleccionado = ""
	_actualizar_feedback_seleccion(sueno)


func _actualizar_feedback_seleccion(sueno: SuenoGilgamesh) -> void:
	var puzzle := sueno.get_node_or_null("CiudadImposible/PuzzleTablilla") as Node3D
	if puzzle == null:
		return
	for valor in SuenoGilgamesh.ENCAJES.keys():
		var fragmento := String(valor)
		var pieza := puzzle.get_node_or_null(fragmento) as MeshInstance3D
		if pieza == null or not pieza.visible:
			continue
		pieza.scale = (
			Vector3.ONE * 1.14 if fragmento == _fragmento_seleccionado else Vector3.ONE
		)


func _deshabilitar(zona: Interactuable3D) -> void:
	if zona == null:
		return
	zona.habilitado = false
