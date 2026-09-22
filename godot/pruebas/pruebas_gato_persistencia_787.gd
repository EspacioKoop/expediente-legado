extends SceneTree

## Regresión de #787 para dos contratos que no deben depender de presentación:
## ausencia sin softlock y persistencia exacta del estado relevante del gato.

const RUTA := "user://prueba_gato_persistencia_787.json"

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	_limpiar()
	_probar_ausencia_sin_softlock()
	_probar_persistencia()
	_probar_validacion_memoria()
	_limpiar()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_ausencia_sin_softlock() -> void:
	var gato_ausente := {
		"presente": false,
		"dias_sin_comer": Jornada.PACIENCIA_GATO + 1,
	}
	_comprobar(not GatoAyuda.guia_visible(gato_ausente), "el gato ausente no monta guía onírica")
	_comprobar(
		GatoAyuda.lineas_asistente(gato_ausente).is_empty(),
		"SIGA funciona sin asistente felino",
	)

	# El progreso obligatorio pertenece a SuenoObjetivos, no al gato. Dos rutas
	# espaciales resuelven el umbral aunque no exista ninguna guía.
	var objetivos := SuenoObjetivos.nuevo(["espacio:a", "espacio:b", "espacio:c"])
	_comprobar(SuenoObjetivos.completar(objetivos, "espacio:a"), "primera ruta progresa sin gato")
	_comprobar(SuenoObjetivos.completar(objetivos, "espacio:b"), "segunda ruta progresa sin gato")
	_comprobar(SuenoObjetivos.resuelto(objetivos), "la noche puede resolverse sin gato")


func _probar_persistencia() -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	var jornada: Dictionary = partida.estado["jornada"]
	jornada["dia"] = 7
	jornada["gato"]["presente"] = true
	jornada["gato"]["dias_sin_comer"] = 2
	_comprobar(
		GatoEcoSueno.registrar(jornada["gato"], 7, GatoEcoSueno.COGER),
		"se registra un único recuerdo antes de guardar",
	)
	_comprobar(partida.guardar(RUTA), "la partida con estado felino se guarda")

	var recargada := Partida.new()
	var resultado := recargada.cargar(RUTA)
	_comprobar(resultado.get("resultado", "") == "cargada", "la partida del gato se recarga")
	var gato: Dictionary = recargada.estado["jornada"]["gato"]
	_comprobar(bool(gato.get("presente", false)), "recargar conserva presencia")
	_comprobar(int(gato.get("dias_sin_comer", -1)) == 2, "recargar conserva hambre")
	_comprobar(
		GatoEcoSueno.acciones_de(gato, 7) == [GatoEcoSueno.COGER],
		"recargar conserva la memoria corta sin duplicarla",
	)

	gato["presente"] = false
	_comprobar(recargada.guardar(RUTA), "la ausencia se guarda")
	var ausente := Partida.new()
	_comprobar(ausente.cargar(RUTA).get("resultado", "") == "cargada", "la ausencia se recarga")
	var gato_ausente: Dictionary = ausente.estado["jornada"]["gato"]
	_comprobar(not bool(gato_ausente.get("presente", true)), "recargar no revive al gato")
	_comprobar(
		int(gato_ausente.get("dias_sin_comer", -1)) == 2,
		"la ausencia no borra el hambre persistida",
	)
	_comprobar(
		GatoEcoSueno.acciones_de(gato_ausente, 7) == [GatoEcoSueno.COGER],
		"guardar ausencia no fabrica otro recuerdo",
	)


func _probar_validacion_memoria() -> void:
	_comprobar(
		GatoEcoSueno.validar({"eco_sueno_hoy": "roto"}).size() == 1,
		"una memoria que no es objeto se rechaza",
	)
	var guardado := Partida.nueva()
	guardado["jornada"]["gato"][GatoEcoSueno.CLAVE] = {
		"dia": 3,
		"acciones": ["accion_inventada"],
	}
	var errores := Partida.validar(guardado)
	_comprobar(
		errores.any(func(error): return String(error).contains("gato.eco_sueno_hoy")),
		"Partida valida la memoria corta conocida",
	)


func _limpiar() -> void:
	for ruta in [RUTA, RUTA + ".nuevo", RUTA + ".roto"]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(actual: bool, nombre: String) -> void:
	if actual:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO persistencia gato #787: %s" % nombre)
