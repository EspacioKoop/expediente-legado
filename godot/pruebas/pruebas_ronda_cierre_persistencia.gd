extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_guardado_y_recarga()
	_probar_dia_nuevo()
	_probar_reasignacion()
	_probar_validacion()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_guardado_y_recarga() -> void:
	var ruta := "user://regresion-ronda-cierre.json"
	_borrar_si_existe(ruta)

	var partida := Partida.new()
	partida.estado = Partida.nueva()
	var jornada: Dictionary = Jornada.completar(
		partida.estado["jornada"], int(partida.estado["semilla"])
	)
	partida.estado["jornada"] = jornada

	var ronda: Dictionary = Jornada.asegurar_ronda_cierre(jornada, false)
	_comprobar(ronda["ruta"].size() >= 3 and ronda["ruta"].size() <= 5, "ruta de 3 a 5 puntos")
	_comprobar(not ronda["ruta"].has(RondaCierre.PUNTO_CUNADO), "cuñado ausente no entra")

	var punto := String(ronda["ruta"][0])
	_comprobar(RondaCierre.completar_punto(ronda, punto), "un punto se registra")
	var misma: Dictionary = Jornada.asegurar_ronda_cierre(jornada, false)
	_comprobar(misma["completados"].has(punto), "reabrir conserva el progreso")
	_comprobar(partida.guardar(ruta), "la partida con ronda se guarda")

	var releida := Partida.new()
	var carga := releida.cargar(ruta)
	_comprobar(carga.get("resultado", "") == "cargada", "la partida se recarga")
	var jornada_releida: Dictionary = Jornada.completar(
		releida.estado["jornada"], int(releida.estado["semilla"])
	)
	releida.estado["jornada"] = jornada_releida
	var cargada: Dictionary = Jornada.asegurar_ronda_cierre(jornada_releida, false)
	_comprobar(cargada["completados"].has(punto), "la recarga conserva el punto")
	_comprobar(cargada["ruta"] == ronda["ruta"], "la recarga conserva la misma ruta")
	_comprobar(RondaCierre.validar(cargada).is_empty(), "la ronda recargada es válida")

	_borrar_si_existe(ruta)


func _probar_dia_nuevo() -> void:
	var jornada := Jornada.nueva(7, 1)
	Jornada.asegurar_ronda_cierre(jornada, true)
	jornada["fase"] = "sueño"
	Jornada.despertar(jornada)
	_comprobar(jornada["ronda_cierre"].is_empty(), "despertar limpia la ronda diaria")


func _probar_reasignacion() -> void:
	var jornada := Jornada.nueva(7, 1)
	Jornada.asegurar_ronda_cierre(jornada, true)
	Jornada.reiniciar_vuelta(jornada)
	_comprobar(int(jornada["vuelta"]) == 2, "la reasignación avanza la vuelta")
	_comprobar(jornada["ronda_cierre"].is_empty(), "la nueva vuelta no hereda la ronda")


func _probar_validacion() -> void:
	var invalida := {
		"dia": 1,
		"ruta": ["recoger_a7", "recoger_a7", "cerrar_puerta"],
		"completados": [],
		"abandonada": false,
		"finalizada": false,
		"rango": RondaCierre.INCOMPLETA,
	}
	_comprobar(
		RondaCierre.validar(invalida).has("ruta contiene duplicados"),
		"el contrato detecta rutas duplicadas",
	)
	var estado := Partida.nueva()
	estado["jornada"]["ronda_cierre"] = invalida
	var errores := Partida.validar(estado)
	_comprobar(
		errores.any(
			func(error): return String(error).contains("ronda_cierre.ruta contiene duplicados")
		),
		"Partida rechaza una ronda corrupta",
	)


func _borrar_si_existe(ruta: String) -> void:
	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO RondaCierrePersistencia: " + nombre)
