## Regresión del ciclo fijo de Quimera (#2087 / #2391).
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const RUNTIME = preload("res://guion/juicio_combate_quimera_runtime_2087.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_ciclo_completo()
	_probar_determinismo_y_no_mutacion()
	_probar_contextos_ajenos()
	print("pruebas_quimera_2087: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_ciclo_completo() -> void:
	var estado := RUNTIME.nuevo(2087)
	var esperados := [
		ARQUETIPOS.EMBESTIDOR,
		ARQUETIPOS.HOSTIGADOR,
		ARQUETIPOS.BLOQUEADOR,
		ARQUETIPOS.EMBESTIDOR,
	]
	_comprobar(String(estado.get("patron_actual", "")) == esperados[0], "inicia en EMBESTIDOR")
	_comprobar(estado.keys().count("unidad") == 1, "solo existe una unidad activa")

	for indice in range(esperados.size() - 1):
		var patron := String(estado.get("patron_actual", ""))
		_comprobar(patron == esperados[indice], "patrón esperado antes del ciclo %d" % indice)
		var cambio := _avanzar_hasta_cambio(estado)
		estado = cambio.get("estado", estado)
		_comprobar(bool(cambio.get("cambio_patron", false)), "el ciclo termina con cambio")
		_comprobar(
			String(cambio.get("patron_ejecutado", "")) == esperados[indice],
			"declara el patrón ejecutado",
		)
		_comprobar(
			String(estado.get("patron_actual", "")) == esperados[indice + 1],
			"avanza al siguiente patrón fijo",
		)
		_comprobar(estado.keys().count("unidad") == 1, "el cambio mantiene una sola unidad")
		_comprobar(
			String((estado.get("unidad", {}) as Dictionary).get("tipo", ""))
			== esperados[indice + 1],
			"la unidad activa coincide con el patrón siguiente",
		)


func _probar_determinismo_y_no_mutacion() -> void:
	var estado := RUNTIME.nuevo(99)
	var antes := estado.duplicate(true)
	var contextos := _contextos()
	var a := RUNTIME.avanzar(estado, 2.0, contextos)
	var b := RUNTIME.avanzar(antes.duplicate(true), 2.0, contextos)
	_comprobar(a == b, "misma entrada y contexto producen la misma salida")
	_comprobar(estado == antes, "avanzar no muta el estado de entrada")
	_comprobar(
		String(a.get("telegraph", ""))
		== String((a.get("salida", {}) as Dictionary).get("telegraph", "")),
		"reenvía el telegraph del arquetipo",
	)
	_comprobar(
		bool(a.get("ventana_respuesta", false))
		== bool((a.get("salida", {}) as Dictionary).get("ventana_respuesta", false)),
		"reenvía la ventana de respuesta",
	)


func _probar_contextos_ajenos() -> void:
	var estado := RUNTIME.nuevo(123)
	var base := _contextos()
	var ruido := _contextos()
	ruido[ARQUETIPOS.HOSTIGADOR] = {"distancia": 999.0, "rumbo_objetivo": 42.0}
	ruido[ARQUETIPOS.BLOQUEADOR] = {"flanqueado": false, "guardia_rota": false}
	_comprobar(
		RUNTIME.avanzar(estado, 0.25, base) == RUNTIME.avanzar(estado, 0.25, ruido),
		"contextos de patrones inactivos no alteran el tick",
	)


func _avanzar_hasta_cambio(estado_inicial: Dictionary) -> Dictionary:
	var estado := estado_inicial.duplicate(true)
	for _paso in range(8):
		var resultado := RUNTIME.avanzar(estado, 2.0, _contextos())
		_comprobar(
			String(resultado.get("telegraph", ""))
			== String((resultado.get("salida", {}) as Dictionary).get("telegraph", "")),
			"cada tick reenvía telegraph",
		)
		_comprobar(
			bool(resultado.get("ventana_respuesta", false))
			== bool((resultado.get("salida", {}) as Dictionary).get("ventana_respuesta", false)),
			"cada tick reenvía ventana",
		)
		estado = resultado.get("estado", estado)
		if bool(resultado.get("cambio_patron", false)):
			return resultado
	_comprobar(false, "el patrón debe completar su ciclo en ocho ticks")
	return {"estado": estado, "cambio_patron": false}


func _contextos() -> Dictionary:
	return {
		ARQUETIPOS.EMBESTIDOR: {
			"distancia": 5.0,
			"linea_libre": true,
			"choque": true,
			"rumbo_objetivo": 0.0,
		},
		ARQUETIPOS.HOSTIGADOR: {
			"distancia": 6.0,
			"rumbo_objetivo": 0.0,
		},
		ARQUETIPOS.BLOQUEADOR: {
			"flanqueado": true,
			"guardia_rota": false,
		},
	}


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2391 Quimera: " + mensaje)
