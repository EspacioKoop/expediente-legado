extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_catalogo_real_y_eventos()
	_probar_reasignacion_y_solape()
	_probar_cierre_real()
	_probar_validacion()
	print("catalogo_vida_91: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _contenido() -> Contenido:
	var contenido := Contenido.new()
	_comprobar(contenido.cargar(), "carga el catálogo real")
	return contenido


func _probar_catalogo_real_y_eventos() -> void:
	var contenido := _contenido()
	var jornada := Jornada.nueva(91, 1)
	var dinero := int(jornada["dinero"])
	var acciones := int(jornada["acciones"])

	_comprobar(
		CatalogoVidaMetricas.sincronizar_disponibles(jornada, contenido.casos),
		"la primera consulta fotografía disponibilidad",
	)
	var actual := CatalogoVidaMetricas.snapshot(jornada)
	_comprobar(actual["vuelta"] == 1, "la métrica pertenece a la vuelta activa")
	_comprobar(
		actual["casos_disponibles"].size() == contenido.casos.size(),
		"la política desactivada conserva todos los casos disponibles",
	)
	_comprobar(contenido.casos.size() == 11, "el catálogo real sigue teniendo once casos")

	var primero := String(contenido.casos[0]["id"])
	_comprobar(CatalogoVidaMetricas.registrar_abierto(jornada, primero), "registra primer abierto")
	_comprobar(
		not CatalogoVidaMetricas.registrar_abierto(jornada, primero),
		"repetir una apertura es idempotente",
	)
	_comprobar(CatalogoVidaMetricas.registrar_resuelto(jornada, primero), "registra primer cierre")
	_comprobar(
		not CatalogoVidaMetricas.registrar_resuelto(jornada, primero),
		"repetir un cierre es idempotente",
	)
	actual = CatalogoVidaMetricas.snapshot(jornada)
	_comprobar(actual["casos_abiertos"] == [primero], "conserva IDs abiertos sin duplicar")
	_comprobar(actual["casos_resueltos"] == [primero], "conserva IDs cerrados sin duplicar")
	_comprobar(int(jornada["dinero"]) == dinero, "medir no cambia dinero")
	_comprobar(int(jornada["acciones"]) == acciones, "medir no cambia acciones")
	_comprobar(
		not CatalogoVidaMetricas.sincronizar_disponibles(
			jornada, [{"id": "caso-nuevo-que-no-debe-colarse"}]
		),
		"una vida iniciada no cambia su foto si el catálogo crece",
	)
	_comprobar(
		not actual["casos_disponibles"].has("caso-nuevo-que-no-debe-colarse"),
		"la foto iniciada no incorpora casos retroactivamente",
	)


func _probar_reasignacion_y_solape() -> void:
	var contenido := _contenido()
	var jornada := Jornada.nueva(92, 1)
	CatalogoVidaMetricas.sincronizar_disponibles(jornada, contenido.casos)
	var primero := String(contenido.casos[0]["id"])
	var segundo := String(contenido.casos[1]["id"])
	var tercero := String(contenido.casos[2]["id"])
	CatalogoVidaMetricas.registrar_abierto(jornada, primero)
	CatalogoVidaMetricas.registrar_abierto(jornada, segundo)
	CatalogoVidaMetricas.registrar_resuelto(jornada, primero)

	Jornada.reiniciar_vuelta(jornada)
	_comprobar(int(jornada["vuelta"]) == 2, "reasignar avanza la vida")
	var anterior := CatalogoVidaMetricas.anterior(jornada)
	var actual := CatalogoVidaMetricas.snapshot(jornada)
	_comprobar(anterior["vuelta"] == 1, "archiva la vuelta anterior")
	_comprobar(anterior["casos_abiertos"] == [primero, segundo], "archiva abiertos anteriores")
	_comprobar(anterior["casos_resueltos"] == [primero], "archiva cierres anteriores")
	_comprobar(actual["vuelta"] == 2, "la nueva foto usa la nueva vuelta")
	_comprobar(actual["casos_disponibles"].is_empty(), "la nueva vida empieza sin foto heredada")
	_comprobar(actual["casos_abiertos"].is_empty(), "la nueva vida no hereda abiertos")
	_comprobar(actual["casos_resueltos"].is_empty(), "la nueva vida no hereda cierres")

	CatalogoVidaMetricas.sincronizar_disponibles(jornada, contenido.casos)
	CatalogoVidaMetricas.registrar_abierto(jornada, primero)
	CatalogoVidaMetricas.registrar_abierto(jornada, tercero)
	var comparacion := CatalogoVidaMetricas.comparar_con_anterior(jornada)
	_comprobar(
		comparacion["casos_abiertos"]["comunes"] == 1,
		"el solape entre vidas sale de IDs persistidos",
	)
	_comprobar(
		is_equal_approx(float(comparacion["casos_abiertos"]["fraccion_actual"]), 0.5),
		"la fracción de repetición es reproducible",
	)


func _probar_cierre_real() -> void:
	var contenido := _contenido()
	var estado := Partida.nueva()
	var jornada: Dictionary = estado["jornada"]
	CatalogoVidaMetricas.sincronizar_disponibles(jornada, contenido.casos)
	var caso: Dictionary = contenido.casos[0]
	var sospechoso: Dictionary = caso["sospechosos"][0]
	var descubiertas := caso.get("pistas", []).map(func(pista): return pista["id"])
	var resultado := Acusacion.acusar(estado, jornada, caso, sospechoso, descubiertas)
	_comprobar(resultado.get("resultado", "") == "cerrado", "la firma real cierra el caso")
	var actual := CatalogoVidaMetricas.snapshot(jornada)
	_comprobar(
		actual["casos_resueltos"] == [String(caso["id"])],
		"la firma irreversible alimenta la métrica de cierres",
	)
	_comprobar(
		actual["casos_abiertos"] == [String(caso["id"])],
		"cerrar sin lectura previa también cuenta como expediente abierto",
	)


func _probar_validacion() -> void:
	var estado := Partida.nueva()
	var jornada: Dictionary = estado["jornada"]
	CatalogoVidaMetricas.registrar_abierto(jornada, "caso-prueba")
	_comprobar(Partida.validar(estado).is_empty(), "Partida acepta la métrica válida")

	var corrupta: Dictionary = estado.duplicate(true)
	corrupta["jornada"][CatalogoVidaMetricas.CLAVE_ACTUAL]["casos_abiertos"] = [
		"caso-prueba",
		"caso-prueba",
	]
	var errores := Partida.validar(corrupta)
	_comprobar(
		errores.any(func(error): return String(error).contains("id duplicado")),
		"Partida rechaza IDs duplicados en la métrica",
	)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO CatalogoVida91: " + nombre)
