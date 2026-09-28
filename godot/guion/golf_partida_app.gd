## Partida standalone de tres hoyos del golf de pasillo (#158).
##
## Orquesta el slice GolfHoyoApp sobre el núcleo Golf. No conoce Partida,
## rankings ni recompensas. El jugador usa el hoyo 3D y tres compañeros resuelven
## sus turnos con planes simples, distintos y deterministas sobre el mismo Golf.
class_name GolfPartidaApp
extends Node3D

signal cerrado
signal partida_terminada(resultado: Dictionary)

const HOYO_SCENE: PackedScene = preload("res://escenas/golf_hoyo_standalone.tscn")
const JUGADOR := "jugador"
const LANZADORES := ["jugador", "prudente", "agresiva", "absurda"]
const PLAN_COMPANEROS := {
	"prudente": [4, 4, 4],
	"agresiva": [3, 5, 3],
	"absurda": [7, 6, 8],
}
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
	estado = Golf.nueva(LANZADORES)
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

	if not bool(estado.get("terminada", false)):
		_resolver_turnos_companeros(indice_antes)
	if bool(estado.get("terminada", false)):
		_finalizar()
		return
	call_deferred("_abrir_hoyo", int(estado.get("hoyo", 0)))


func _resolver_turnos_companeros(indice_hoyo: int) -> void:
	while not bool(estado.get("terminada", false)):
		var actual := Golf.jugador_actual(estado)
		if actual.is_empty() or actual == JUGADOR:
			return
		var plan: Array = PLAN_COMPANEROS.get(actual, [])
		var golpes := Golf.MAX_GOLPES_POR_HOYO
		if indice_hoyo >= 0 and indice_hoyo < plan.size():
			golpes = clampi(int(plan[indice_hoyo]), 1, Golf.MAX_GOLPES_POR_HOYO)
		var hoyo_antes := int(estado.get("hoyo", 0))
		for _i in range(golpes):
			if int(estado.get("hoyo", 0)) != hoyo_antes:
				break
			Golf.golpear(estado, actual)
		if int(estado.get("hoyo", 0)) == hoyo_antes:
			Golf.terminar_hoyo(estado, actual)


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
