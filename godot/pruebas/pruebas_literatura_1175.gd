extends SceneTree

var pasadas := 0
var fallos := 0


func _initialize() -> void:
	_probar_catalogo()
	_probar_lectura_significativa()
	_probar_separacion_posesion()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_catalogo() -> void:
	var catalogo := LiteraturaCatalogo.cargar()
	_comprobar(not catalogo.is_empty(), "el catalogo literario carga")
	var obras: Array = catalogo.get("obras", [])
	_comprobar(obras.size() == 1, "el primer corte contiene una obra")
	if obras.is_empty():
		return
	var obra: Dictionary = obras[0]
	_comprobar(String(obra.get("id", "")) == "vida_es_sueno_1635", "id estable")
	_comprobar(String(obra.get("titulo", "")) == "La vida es sueño", "titulo documentado")
	_comprobar(String(obra.get("autor", "")) == "Pedro Calderón de la Barca", "autor documentado")
	var rom: Dictionary = obra.get("rom", {})
	_comprobar(String(rom.get("id", "")) == "sueno_98", "la obra declara una ROM futura")
	_comprobar(String(rom.get("estado", "")) == "propuesta", "la ROM no se finge implementada")
	var efecto: Dictionary = obra.get("efecto_juego", {})
	_comprobar(
		String(efecto.get("tipo", "")) == "modificador_contextual",
		"el efecto es declarativo y contextual",
	)
	_comprobar(
		(efecto.get("consumidores", []) as Array).has("conflicto_literario"),
		"el efecto declara consumidor externo",
	)


func _probar_lectura_significativa() -> void:
	var registro := LiteraturaEventos.nuevo()

	var parcial := (
		LiteraturaLectura
		. registrar_interaccion(
			registro,
			"vida_es_sueno_1635",
			"documento:biblioteca:estante_03",
			2,
			0.45,
		)
	)
	_comprobar(not bool(parcial["completa"]), "hojear no completa la lectura")
	_comprobar(
		String(parcial["motivo"]) == "lectura_incompleta",
		"la lectura parcial explica por que no registra",
	)
	_comprobar(
		LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_CONOCIMIENTO).is_empty(),
		"la lectura parcial no crea conocimiento",
	)
	_comprobar(
		LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_INSIGHT).is_empty(),
		"la lectura parcial no crea insight",
	)
	_comprobar(
		LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_POSESION).is_empty(),
		"leer no concede posesion",
	)

	var completa := (
		LiteraturaLectura
		. registrar_interaccion(
			registro,
			"vida_es_sueno_1635",
			"documento:biblioteca:estante_03",
			2,
			1.0,
		)
	)
	_comprobar(bool(completa["completa"]), "alcanzar el umbral completa la lectura")
	_comprobar(bool(completa["conocimiento_nuevo"]), "la primera lectura registra conocimiento")
	_comprobar(bool(completa["insight_nuevo"]), "la primera lectura registra insight")
	_comprobar(
		LiteraturaEventos.obra_conocida(registro, "vida_es_sueno_1635"),
		"el contrato puede consultar conocimiento",
	)
	_comprobar(
		not LiteraturaEventos.obra_poseida(registro, "vida_es_sueno_1635"),
		"conocer sigue sin equivaler a poseer",
	)

	var conocimientos := (
		LiteraturaEventos
		. eventos(
			registro,
			LiteraturaEventos.CANAL_CONOCIMIENTO,
		)
	)
	var insights := LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_INSIGHT)
	_comprobar(conocimientos.size() == 1, "solo hay un evento de conocimiento")
	_comprobar(insights.size() == 1, "solo hay un evento de insight")
	if not conocimientos.is_empty():
		var conocimiento: Dictionary = conocimientos[0]
		_comprobar(
			String(conocimiento.get("fuente", "")) == "documento:biblioteca:estante_03",
			"el conocimiento conserva procedencia",
		)
	if not insights.is_empty():
		var insight: Dictionary = insights[0]
		var metadatos: Dictionary = insight.get("metadatos", {})
		var efecto: Dictionary = metadatos.get("efecto_declarado", {})
		_comprobar(
			String(efecto.get("id", "")) == "palabra_serenidad",
			"el insight transporta el efecto declarado sin aplicarlo",
		)

	var repetida := (
		LiteraturaLectura
		. registrar_interaccion(
			registro,
			"vida_es_sueno_1635",
			"documento:biblioteca:estante_03",
			3,
			1.0,
		)
	)
	_comprobar(not bool(repetida["conocimiento_nuevo"]), "releer no duplica conocimiento")
	_comprobar(not bool(repetida["insight_nuevo"]), "releer no duplica insight")
	_comprobar(String(repetida["motivo"]) == "ya_registrada", "la idempotencia es explicita")
	_comprobar(
		LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_CONOCIMIENTO).size() == 1,
		"el conocimiento sigue siendo unico",
	)
	_comprobar(
		LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_INSIGHT).size() == 1,
		"el insight sigue siendo unico",
	)


func _probar_separacion_posesion() -> void:
	var registro := LiteraturaEventos.nuevo()
	var posesion := (
		LiteraturaEventos
		. crear_evento(
			"posesion:obra:vida_es_sueno_1635:ejemplar:oficina_01",
			LiteraturaEventos.CANAL_POSESION,
			"vida_es_sueno_1635",
			"inventario:oficina_01",
			"ejemplar_fisico",
			1,
			["libro"],
		)
	)
	_comprobar(LiteraturaEventos.registrar(registro, posesion), "la posesion se registra aparte")
	_comprobar(
		LiteraturaEventos.obra_poseida(registro, "vida_es_sueno_1635"),
		"el canal de posesion puede consultarse",
	)
	_comprobar(
		not LiteraturaEventos.obra_conocida(registro, "vida_es_sueno_1635"),
		"poseer no implica conocer",
	)
	_comprobar(
		not LiteraturaEventos.registrar(registro, posesion),
		"el mismo evento de posesion es idempotente",
	)

	var colision := (
		LiteraturaEventos
		. crear_evento(
			String(posesion["id"]),
			LiteraturaEventos.CANAL_CONOCIMIENTO,
			"vida_es_sueno_1635",
			"documento:otro",
		)
	)
	_comprobar(
		not LiteraturaEventos.registrar(registro, colision),
		"un id no puede reclasificarse en otro canal",
	)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO #1175: %s" % nombre)
