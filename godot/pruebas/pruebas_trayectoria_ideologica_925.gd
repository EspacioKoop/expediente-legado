extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_resumen_y_reset()
	_probar_cierre_final()
	_probar_validacion()
	print("trayectoria_ideologica_925: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _estado_base() -> Dictionary:
	var estado := Partida.nueva()
	estado["jornada"]["vuelta"] = 1
	return estado


func _probar_resumen_y_reset() -> void:
	var estado := _estado_base()
	_comprobar(
		Prometeo.registrar_eleccion_ideologica(
			estado, "fixture:a", "expediente", "centrista", "caso-a", 1
		),
		true,
		"registra primera decisión",
	)
	_comprobar(
		Prometeo.registrar_eleccion_ideologica(
			estado, "fixture:b", "expediente", "neoliberal", "caso-b", 1
		),
		true,
		"registra segunda decisión",
	)

	var resumen := Prometeo.resumen_trayectoria_ideologica(estado)
	_comprobar(resumen["patron"], "plural", "un empate se conserva como pluralidad")
	_comprobar(resumen["elecciones"], 2, "el resumen cuenta decisiones explícitas")
	_comprobar(resumen["dominantes"].size(), 2, "el resumen conserva ambos dominantes")

	Prometeo.reiniciar_vuelta(estado, Partida.VIDA_MAXIMA)
	var historial := Prometeo.historial_trayectorias_ideologicas(estado)
	_comprobar(historial.size(), 1, "el reset archiva exactamente una trayectoria")
	_comprobar(historial[0]["patron"], "plural", "el snapshot sobrevive al reset")
	_comprobar(
		historial[0]["motivo"],
		"reinicio_vuelta",
		"el snapshot documenta la frontera que lo selló",
	)
	_comprobar(
		Prometeo.elecciones_ideologicas(estado).size(),
		0,
		"el estado activo sí queda limpio",
	)

	Prometeo.reiniciar_vuelta(estado, Partida.VIDA_MAXIMA)
	_comprobar(
		Prometeo.historial_trayectorias_ideologicas(estado).size(),
		1,
		"repetir reset de la misma vuelta no duplica historial",
	)


func _probar_cierre_final() -> void:
	var estado := _estado_base()
	estado["jornada"]["vuelta"] = 2
	Prometeo.registrar_eleccion_ideologica(
		estado, "fixture:final", "dialogo", "socialdemocrata", "caso-final", 2
	)
	FinalPolitico.confirmar_cierre(estado)
	var historial := Prometeo.historial_trayectorias_ideologicas(estado)
	_comprobar(historial.size(), 1, "el final archiva la vida que no pasa por reset")
	_comprobar(historial[0]["vuelta"], 2, "el final conserva la vuelta real")
	_comprobar(historial[0]["patron"], "consistente", "una sola orientación queda descrita")
	_comprobar(historial[0]["motivo"], "final_narrativo", "el cierre final queda distinguido")

	FinalPolitico.confirmar_cierre(estado)
	_comprobar(
		Prometeo.historial_trayectorias_ideologicas(estado).size(),
		1,
		"confirmar el final otra vez es idempotente",
	)


func _probar_validacion() -> void:
	var estado := _estado_base()
	Prometeo.reiniciar_vuelta(estado, Partida.VIDA_MAXIMA)
	_comprobar(Partida.validar(estado), [], "Partida acepta el historial archivado")

	var recargado = JSON.parse_string(JSON.stringify(estado))
	_comprobar(Partida.validar(recargado), [], "el historial sobrevive a JSON round-trip")

	var corrupto: Dictionary = estado.duplicate(true)
	var historial: Array = corrupto[Prometeo.CLAVE_HISTORIAL_IDEOLOGICO]
	historial.append(historial[0].duplicate(true))
	var errores := Partida.validar(corrupto)
	_comprobar(
		errores.any(func(error): return String(error).contains("vuelta duplicada")),
		true,
		"Partida rechaza dos snapshots de la misma vuelta",
	)


func _comprobar(actual: Variant, esperado: Variant, mensaje: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("%s: esperado=%s actual=%s" % [mensaje, esperado, actual])
