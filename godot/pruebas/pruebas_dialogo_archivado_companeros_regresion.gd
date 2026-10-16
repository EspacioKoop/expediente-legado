## Regresión pura de DialogoArchivadoCompaneros: no toca estado ni textos.
extends SceneTree

const CASOS_SOPORTADOS := {
	"cunado":
	{
		"leve": "COMPA_ARCHIVO_CUNADO_LEVE",
		"alto": "COMPA_ARCHIVO_CUNADO_ALTO",
	},
	"becario":
	{
		"leve": "COMPA_ARCHIVO_BECARIO_LEVE",
		"alto": "COMPA_ARCHIVO_BECARIO_ALTO",
	},
	"jubilacion":
	{
		"leve": "COMPA_ARCHIVO_JUBILACION_LEVE",
		"alto": "COMPA_ARCHIVO_JUBILACION_ALTO",
	},
	"riegos":
	{
		"leve": "COMPA_ARCHIVO_RIEGOS_LEVE",
		"alto": "COMPA_ARCHIVO_RIEGOS_ALTO",
	},
}

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_actor_desconocido()
	_probar_cero_errores_pendientes()
	_probar_umbral_leve_alto()
	print("dialogo_archivado_companeros_regresion: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_actor_desconocido() -> void:
	_comprobar(
		DialogoArchivadoCompaneros.resolver("telefono", 3),
		"",
		"actor sin clave no inventa reacción de archivado",
	)
	_comprobar(
		DialogoArchivadoCompaneros.resolver("", 3),
		"",
		"actor vacío conserva el diálogo base",
	)


func _probar_cero_errores_pendientes() -> void:
	for actor: String in CASOS_SOPORTADOS.keys():
		_comprobar(
			DialogoArchivadoCompaneros.resolver(actor, 0),
			"",
			"%s sin errores pendientes no reacciona" % actor,
		)
		_comprobar(
			DialogoArchivadoCompaneros.resolver(actor, -1),
			"",
			"%s con contador no positivo no reacciona" % actor,
		)


func _probar_umbral_leve_alto() -> void:
	for actor: String in CASOS_SOPORTADOS.keys():
		var esperado: Dictionary = CASOS_SOPORTADOS[actor]
		_comprobar(
			DialogoArchivadoCompaneros.resolver(actor, 2),
			esperado["leve"],
			"%s mantiene reacción leve con dos errores" % actor,
		)
		_comprobar(
			DialogoArchivadoCompaneros.resolver(actor, 3),
			esperado["alto"],
			"%s cruza a reacción alta con tres errores" % actor,
		)


func _comprobar(actual: Variant, esperado: Variant, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error(
		"FALLO DialogoArchivadoCompaneros: %s (actual=%s esperado=%s)" % [nombre, actual, esperado]
	)
