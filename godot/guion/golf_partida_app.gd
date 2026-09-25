## Partida standalone de tres hoyos del golf de pasillo (#158).
##
## Orquesta el slice GolfHoyoApp sobre el núcleo Golf. No conoce Partida,
## rankings, recompensas ni compañeros: cada hoyo entrega sus golpes al modelo
## puro y el siguiente se crea desde una configuración fija y reproducible.
class_name GolfPartidaApp
extends Node3D

signal cerrado
signal partida_terminada(resultado: Dictionary)

const HOYO_SCENE: PackedScene = preload("res://escenas/golf_hoyo_standalone.tscn")
const JUGADOR := "jugador"
const CONFIGURACIONES := [
	{
		"inicio": Vector2(0.0, 1.72),
		"objetivo": Vector2(0.0, -1.72),
		"obstaculos": [Rect2(-1.02, -0.18, 0.56, 0.20)],
	},
	{
		"inicio": Vector2(0.72, 1.72),
		"objetivo": Vector2(-0.72, -1.72),
		"obstaculos": [Rect2(-0.16, -0.82, 0.32, 1.48)],
	},
	{
		"inicio": Vector2(-0.72, 1.72),
		"objetivo": Vector2(0.72, -1.72),
		"obstaculos":
		[
			Rect2(-0.88, 0.18, 0.78, 0.20),
			Rect2(0.12, -0.92, 0.82, 0.20),
		],
	},
]

var estado: Dictionary = {}
var resultado_final: Dictionary = {}
var hoyo_actual: GolfHoyoApp


func _ready() -> void:
	estado = Golf.nueva([JUGADOR])
	_abrir_hoyo(0)


func _abrir_hoyo(indice: int) -> void:
	if is_instance_valid(hoyo_actual):
		hoyo_actual.queue_free()
		hoyo_actual = null
	if indice < 0 or indice >= CONFIGURACIONES.size():
		return

	var configuracion: Dictionary = CONFIGURACIONES[indice].duplicate(true)
	configuracion["numero_hoyo"] = indice + 1
	hoyo_actual = HOYO_SCENE.instantiate()
	hoyo_actual.configurar(configuracion)
	hoyo_actual.hoyo_completado.connect(_al_completar_hoyo)
	hoyo_actual.cerrado.connect(_al_abandonar_hoyo)
	add_child(hoyo_actual)


func _al_completar_hoyo(golpes: int) -> void:
	if bool(estado.get("terminada", false)):
		return
	var indice_antes := int(estado.get("hoyo", 0))
	var jugador := Golf.jugador_actual(estado)
	for _i in range(clampi(golpes, 1, Golf.MAX_GOLPES_POR_HOYO)):
		if int(estado.get("hoyo", 0)) != indice_antes:
			break
		Golf.golpear(estado, jugador)
	if int(estado.get("hoyo", 0)) == indice_antes:
		Golf.terminar_hoyo(estado, jugador)

	if bool(estado.get("terminada", false)):
		_finalizar()
		return
	call_deferred("_abrir_hoyo", int(estado.get("hoyo", 0)))


func _al_abandonar_hoyo() -> void:
	if bool(estado.get("terminada", false)):
		return
	Golf.abandonar(estado)
	_finalizar()
	cerrado.emit()


func _finalizar() -> void:
	resultado_final = Golf.resultado(estado)
	if is_instance_valid(hoyo_actual):
		hoyo_actual.queue_free()
		hoyo_actual = null
	partida_terminada.emit(resultado_final.duplicate(true))
