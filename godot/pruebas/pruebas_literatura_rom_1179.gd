## Contrato de desbloqueo y evento de SUEÑO 98 (#1179).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_desbloqueo_exige_conocimiento()
	_probar_evento_de_handshake()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_desbloqueo_exige_conocimiento() -> void:
	var registro := LiteraturaEventos.nuevo()
	_comprobar(
		not LiteraturaRoms.desbloqueadas(registro).has("sueno_98"),
		"sin eventos la ROM permanece bloqueada",
	)

	var posesion := (
		LiteraturaEventos
		. crear_evento(
			"posesion:1179",
			LiteraturaEventos.CANAL_POSESION,
			Sueno98Vigilia.OBRA_ID,
			"inventario:prueba",
		)
	)
	_comprobar(LiteraturaEventos.registrar(registro, posesion), "la posesion se registra")
	_comprobar(
		not LiteraturaRoms.desbloqueadas(registro).has("sueno_98"),
		"poseer no desbloquea la ROM",
	)

	var insight := (
		LiteraturaEventos
		. crear_evento(
			"insight:1179:previo",
			LiteraturaEventos.CANAL_INSIGHT,
			Sueno98Vigilia.OBRA_ID,
			"conversacion:prueba",
		)
	)
	_comprobar(LiteraturaEventos.registrar(registro, insight), "el insight previo se registra")
	_comprobar(
		not LiteraturaRoms.desbloqueadas(registro).has("sueno_98"),
		"un insight sin conocimiento no desbloquea",
	)

	var conocimiento := (
		LiteraturaEventos
		. crear_evento(
			"conocimiento:1179",
			LiteraturaEventos.CANAL_CONOCIMIENTO,
			Sueno98Vigilia.OBRA_ID,
			"documento:biblioteca:prueba",
		)
	)
	_comprobar(
		LiteraturaEventos.registrar(registro, conocimiento),
		"el conocimiento explicito se registra",
	)
	_comprobar(
		LiteraturaRoms.desbloqueadas(registro).has("sueno_98"),
		"el conocimiento explicito desbloquea SUEÑO 98",
	)


func _probar_evento_de_handshake() -> void:
	var observador := LiteraturaRomVigilia.new()
	(
		observador
		. configurar_contrato(
			null,
			{"dia": 4, "vuelta": 2},
			null,
			{
				"id_rom": Sueno98Vigilia.ID_ROM,
				"titulo_rom": Sueno98Vigilia.TITULO_ROM,
				"obra_id": Sueno98Vigilia.OBRA_ID,
				"direccion": Sueno98Vigilia.DIRECCION_ESTADO,
				"valor": Sueno98Vigilia.ESTADO_COMPLETADO,
				"contexto": Sueno98Vigilia.CONTEXTO,
				"etiquetas": Sueno98Vigilia.ETIQUETAS,
			},
		)
	)
	var evento := observador.evento_handshake()
	_comprobar(not evento.is_empty(), "el contrato produce un evento valido")
	_comprobar(
		String(evento.get("id", "")) == "insight:rom:sueno_98:objetivo_completado",
		"el id del evento es estable",
	)
	_comprobar(
		String(evento.get("canal", "")) == LiteraturaEventos.CANAL_INSIGHT,
		"completar la adaptacion registra insight",
	)
	_comprobar(
		String(evento.get("canal", "")) != LiteraturaEventos.CANAL_CONOCIMIENTO,
		"la ROM no registra conocimiento",
	)
	_comprobar(
		String(evento.get("obra_id", "")) == Sueno98Vigilia.OBRA_ID,
		"el hecho queda ligado a la obra fuente",
	)
	_comprobar(int(evento.get("jornada", 0)) == 4, "conserva la jornada")
	var metadatos: Dictionary = evento.get("metadatos", {})
	_comprobar(
		String(metadatos.get("procedencia", "")) == "rom:handshake:c100",
		"conserva la procedencia tecnica",
	)
	observador.free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		printerr("FALLO #1179: %s" % nombre)
