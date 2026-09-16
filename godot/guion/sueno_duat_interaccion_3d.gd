## Capa jugable del pesaje del Duat (#441).
##
## SuenoDuat conserva la regla pura del puzzle y el prototipo monumental. Esta
## capa convierte sus pesos declarativos en Interactuable3D alcanzables por el
## detector común: cada interacción recorre fuera -> peso observado -> peso
## sellado -> fuera. No lee Input, no selecciona la familia y no crea HUD.
class_name SuenoDuatInteraccion3D
extends Node3D

signal duat_equilibrado

const ID_MITO := "duat"
const RADIO_HOTSPOT := 0.72
const POS_BANDEJA_REGISTRO := Vector3(-2.15, 2.72, 0.0)
const POS_BANDEJA_MEMORIA := Vector3(2.15, 2.72, 0.0)

var _estado_pesaje: Dictionary = {}
var _seleccion: Dictionary = {}
var _ultimo_resultado: Dictionary = {}
var _prototipo: Node3D
var _hotspots: Array[Interactuable3D] = []
var _reduccion_movimiento := false
var _resuelto := false


func configurar(
	objetos_conocidos: Array,
	semilla: int = 0,
	reduccion_movimiento: bool = false,
) -> bool:
	if _prototipo != null:
		return not _estado_pesaje.is_empty()

	_estado_pesaje = SuenoDuat.preparar_pesaje(objetos_conocidos, semilla)
	_reduccion_movimiento = reduccion_movimiento
	if _estado_pesaje.is_empty():
		visible = false
		return false

	_prototipo = SuenoDuat.crear_prototipo_3d(_estado_pesaje, _reduccion_movimiento)
	_prototipo.name = "DuatInteractivo"
	add_child(_prototipo)
	_montar_interacciones()
	_ultimo_resultado = (
		SuenoDuat
		. aplicar_pesaje_3d(
			_prototipo,
			_estado_pesaje,
			_seleccion,
			_reduccion_movimiento,
		)
	)
	return true


func estado_pesaje() -> Dictionary:
	return _estado_pesaje.duplicate(true)


func seleccion_actual() -> Dictionary:
	return _seleccion.duplicate(true)


func resultado_actual() -> Dictionary:
	return _ultimo_resultado.duplicate(true)


func resuelto() -> bool:
	return _resuelto


func prototipo() -> Node3D:
	return _prototipo


func interactuable(id_objeto: String) -> Interactuable3D:
	for hotspot in _hotspots:
		if String(hotspot.get_meta("duat_objeto_id", "")) == id_objeto:
			return hotspot
	return null


func _montar_interacciones() -> void:
	var pesos := _prototipo.get_node_or_null("PesosInteractivos") as Node3D
	if pesos == null:
		return

	for indice in range(pesos.get_child_count()):
		var area := pesos.get_child(indice) as Area3D
		if area == null:
			continue
		var id_objeto := String(area.get_meta("duat_objeto_id", ""))
		if id_objeto.is_empty():
			continue

		area.set_meta("duat_pos_original", area.position)
		# El Area3D del prototipo conserva visual y metadatos, pero deja de ser
		# colisionable. Solo el Interactuable3D hijo entra en el detector común.
		area.collision_layer = 0
		area.collision_mask = 0

		var hotspot := Interactuable3D.new()
		hotspot.name = "PesoDuat_%02d" % indice
		hotspot.verbo = Interactuable3D.Verbo.USAR
		hotspot.nombre_objeto = "contrapeso"
		hotspot.sonido = Interactuable3D.SIN_SONIDO
		hotspot.set_meta("duat_objeto_id", id_objeto)
		hotspot.set_meta("duat_estado", "fuera")
		area.add_child(hotspot)

		var colision := CollisionShape3D.new()
		var forma := SphereShape3D.new()
		forma.radius = RADIO_HOTSPOT
		colision.shape = forma
		hotspot.add_child(colision)
		hotspot.activado.connect(_al_peso.bind(id_objeto))
		_hotspots.append(hotspot)


func _al_peso(_actor: Node, id_objeto: String) -> void:
	if _resuelto:
		return

	if not _seleccion.has(id_objeto):
		_seleccion[id_objeto] = false
	elif _seleccion[id_objeto] == false:
		_seleccion[id_objeto] = true
	else:
		_seleccion.erase(id_objeto)

	_actualizar_pesos()
	_ultimo_resultado = (
		SuenoDuat
		. aplicar_pesaje_3d(
			_prototipo,
			_estado_pesaje,
			_seleccion,
			_reduccion_movimiento,
		)
	)
	if _ultimo_resultado.get("equilibrado", false) == true:
		_resuelto = true
		for hotspot in _hotspots:
			hotspot.habilitado = false
		duat_equilibrado.emit()


func _actualizar_pesos() -> void:
	var pesos := _prototipo.get_node_or_null("PesosInteractivos") as Node3D
	if pesos == null:
		return

	var indice_registro := 0
	var indice_memoria := 0
	for bruto in pesos.get_children():
		var area := bruto as Area3D
		if area == null:
			continue
		var id_objeto := String(area.get_meta("duat_objeto_id", ""))
		var destino: Vector3 = area.get_meta("duat_pos_original", area.position)
		var estado := "fuera"
		if _seleccion.has(id_objeto):
			if _seleccion[id_objeto] == true:
				destino = _posicion_en_bandeja(POS_BANDEJA_MEMORIA, indice_memoria)
				indice_memoria += 1
				estado = "sellado"
			else:
				destino = _posicion_en_bandeja(POS_BANDEJA_REGISTRO, indice_registro)
				indice_registro += 1
				estado = "observado"

		var hotspot := interactuable(id_objeto)
		if hotspot != null:
			hotspot.set_meta("duat_estado", estado)
		_mover_peso(area, destino)


func _posicion_en_bandeja(base: Vector3, indice: int) -> Vector3:
	var columna := indice % 3
	var fila := floori(float(indice) / 3.0)
	return base + Vector3((float(columna) - 1.0) * 0.44, 0.0, float(fila) * 0.44)


func _mover_peso(area: Area3D, destino: Vector3) -> void:
	if _reduccion_movimiento:
		area.position = destino
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(area, "position", destino, 0.18)
