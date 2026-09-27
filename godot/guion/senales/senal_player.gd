class_name SenalPlayer
extends Node3D

signal moderacion_solicitada(event_id: String)

## Presentación local de una señal validada. No añade colisión ni navegación.

const SenalDatos = preload("res://guion/red/senal_datos.gd")
const SenalVocabulario = preload("res://guion/red/senal_vocabulario.gd")

@export var offset_y := 1.8
@export var tiempo_mostrado := 8.0

var _etiqueta: Label3D
var _moderador: Interactuable3D
var _event_id := ""
var _visible_desde_msec := 0


func _ready() -> void:
	_etiqueta = Label3D.new()
	_etiqueta.name = "TextoSenal"
	_etiqueta.position = Vector3(0.0, offset_y, 0.0)
	_etiqueta.visible = false
	add_child(_etiqueta)

	_moderador = Interactuable3D.new()
	_moderador.name = "Moderar"
	_moderador.position = Vector3(0.0, offset_y, 0.0)
	_moderador.verbo = Interactuable3D.Verbo.EXAMINAR
	_moderador.nombre_objeto = "señal"
	_moderador.sonido = Interactuable3D.SIN_SONIDO
	_moderador.collision_mask = 0
	_moderador.habilitado = false
	_moderador.activado.connect(_al_moderar)
	add_child(_moderador)

	var colision := CollisionShape3D.new()
	colision.name = "ColisionModeracion"
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.4, 0.8, 0.5)
	colision.shape = forma
	_moderador.add_child(colision)


func mostrar_evento(evento: Dictionary, conocimiento: Array = [], ahora_unix: int = -1) -> bool:
	var ahora := ahora_unix
	if ahora < 0:
		ahora = int(Time.get_unix_time_from_system())
	var validacion := SenalDatos.validar_evento(evento, ahora, conocimiento)
	if not validacion["ok"]:
		ocultar()
		return false
	var renderizado := SenalVocabulario.renderizar(validacion["event"]["payload"], conocimiento)
	if not renderizado["ok"]:
		ocultar()
		return false
	_event_id = String(validacion["event"].get("event_id", ""))
	_etiqueta.text = String(renderizado["text"])
	_etiqueta.visible = true
	_moderador.habilitado = not _event_id.is_empty()
	_visible_desde_msec = Time.get_ticks_msec()
	return true


func ocultar() -> void:
	_event_id = ""
	if _moderador != null:
		_moderador.habilitado = false
	if _etiqueta == null:
		return
	_etiqueta.text = ""
	_etiqueta.visible = false


func evento_id() -> String:
	return _event_id


func texto_actual() -> String:
	return _etiqueta.text if _etiqueta != null else ""


func esta_visible() -> bool:
	return _etiqueta != null and _etiqueta.visible


func _al_moderar(_actor: Node) -> void:
	if _event_id.is_empty():
		return
	moderacion_solicitada.emit(_event_id)


func _process(_delta: float) -> void:
	if _etiqueta == null or not _etiqueta.visible:
		return
	var transcurrido := Time.get_ticks_msec() - _visible_desde_msec
	if transcurrido >= int(tiempo_mostrado * 1000.0):
		ocultar()
