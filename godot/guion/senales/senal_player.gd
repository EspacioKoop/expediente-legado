class_name SenalPlayer
extends Node3D

## Presentación local de una señal validada. No añade colisión ni navegación.

const SenalDatos = preload("res://guion/red/senal_datos.gd")
const SenalVocabulario = preload("res://guion/red/senal_vocabulario.gd")

@export var offset_y := 1.8
@export var tiempo_mostrado := 8.0

var _etiqueta: Label3D
var _visible_desde_msec := 0


func _ready() -> void:
	_etiqueta = Label3D.new()
	_etiqueta.name = "TextoSenal"
	_etiqueta.position = Vector3(0.0, offset_y, 0.0)
	_etiqueta.visible = false
	add_child(_etiqueta)


func mostrar_evento(
	evento: Dictionary, conocimiento: Array = [], ahora_unix: int = -1
) -> bool:
	var ahora := ahora_unix
	if ahora < 0:
		ahora = int(Time.get_unix_time_from_system())
	var validacion := SenalDatos.validar_evento(evento, ahora, conocimiento)
	if not validacion["ok"]:
		ocultar()
		return false
	var renderizado := SenalVocabulario.renderizar(
		validacion["event"]["payload"], conocimiento
	)
	if not renderizado["ok"]:
		ocultar()
		return false
	_etiqueta.text = String(renderizado["text"])
	_etiqueta.visible = true
	_visible_desde_msec = Time.get_ticks_msec()
	return true


func ocultar() -> void:
	if _etiqueta == null:
		return
	_etiqueta.text = ""
	_etiqueta.visible = false


func _process(_delta: float) -> void:
	if _etiqueta == null or not _etiqueta.visible:
		return
	var transcurrido := Time.get_ticks_msec() - _visible_desde_msec
	if transcurrido >= int(tiempo_mostrado * 1000.0):
		ocultar()
