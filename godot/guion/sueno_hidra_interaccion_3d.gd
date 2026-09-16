## Capa jugable del vertical de la Hidra (#439).
##
## Reutiliza SuenoHidra como única fuente de estado/regeneración y solo añade
## tres intenciones alcanzables por el detector común: actuar sobre un síntoma,
## observar las conexiones y, cuando la pista ya es suficiente, intervenir en
## el nodo común. No lee Input ni introduce ventanas de timing.
class_name SuenoHidraInteraccion3D
extends Node3D

signal hidra_resuelta

const ID_MITO := "hidra"
const TAMANO_HOTSPOT := Vector3(1.8, 2.2, 1.8)

var _hidra: SuenoHidra
var _sintoma: Interactuable3D
var _conexiones: Interactuable3D
var _nodo: Interactuable3D
var _habilitada := false


func _ready() -> void:
	preparar()


func preparar() -> void:
	if _hidra != null:
		return

	_hidra = SuenoHidra.new()
	_hidra.name = "HidraProcedural"
	add_child(_hidra)
	_hidra.hidra_resuelta.connect(_al_resolverse)

	_sintoma = _crear_hotspot(
		"SintomaHidra",
		Vector3(-4.5, 2.4, -4.0),
		Interactuable3D.Verbo.USAR,
		"cabeza que se multiplica",
	)
	_sintoma.activado.connect(_al_sintoma)

	_conexiones = _crear_hotspot(
		"ConexionesHidra",
		Vector3(0.0, 1.2, 0.1),
		Interactuable3D.Verbo.EXAMINAR,
		"conexiones entre las cabezas",
	)
	_conexiones.activado.connect(_al_observar)

	_nodo = _crear_hotspot(
		"NodoComunHidra",
		Vector3(0.0, 0.9, -2.0),
		Interactuable3D.Verbo.USAR,
		"nodo común de la Hidra",
	)
	_nodo.activado.connect(_al_nodo)
	_actualizar_hotspots()


func configurar(
	semillas: Dictionary,
	reduccion_movimiento: bool = false,
	raiz_seed: int = 0,
) -> bool:
	preparar()
	_habilitada = _hidra.configurar(semillas, reduccion_movimiento, raiz_seed)
	visible = _habilitada
	_actualizar_hotspots()
	return _habilitada


func estado_actual() -> Dictionary:
	if _hidra == null:
		return {}
	return _hidra.estado_actual()


func resuelta() -> bool:
	return bool(estado_actual().get("resuelta", false))


func _al_sintoma(_actor: Node) -> void:
	if not _habilitada or resuelta():
		return
	_hidra.accion_sintoma()
	_actualizar_hotspots()


func _al_observar(_actor: Node) -> void:
	if not _habilitada or resuelta():
		return
	_hidra.observar_conexiones()
	_actualizar_hotspots()


func _al_nodo(_actor: Node) -> void:
	if not _habilitada or resuelta():
		return
	_hidra.accion_nodo_comun()
	_actualizar_hotspots()


func _al_resolverse() -> void:
	_actualizar_hotspots()
	hidra_resuelta.emit()


func _actualizar_hotspots() -> void:
	if _sintoma == null or _conexiones == null or _nodo == null:
		return
	var estado := estado_actual()
	var terminada := bool(estado.get("resuelta", false))
	var nodo_legible := bool(estado.get("nodo_legible", false))
	_sintoma.habilitado = _habilitada and not terminada
	_conexiones.habilitado = _habilitada and not terminada
	_nodo.habilitado = _habilitada and nodo_legible and not terminada


func _crear_hotspot(
	nombre: String,
	posicion: Vector3,
	verbo: int,
	texto: String,
) -> Interactuable3D:
	var hotspot := Interactuable3D.new()
	hotspot.name = nombre
	hotspot.position = posicion
	hotspot.verbo = verbo
	hotspot.nombre_objeto = texto
	add_child(hotspot)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = TAMANO_HOTSPOT
	colision.shape = forma
	hotspot.add_child(colision)
	return hotspot
