extends SceneTree

const Eventos = preload("res://guion/religion_eventos.gd")
const Conflicto = preload("res://guion/religion_conflicto.gd")

var pasadas := 0
var fallos := 0


func _init() -> void:
	var registro := Eventos.nuevo()
	_comprobar(registro.size() == 4, "el contrato nace con cuatro canales")
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_CONVICCION).is_empty(),
		"una partida sin hechos no inventa convicciones"
	)

	var invalido := Eventos.crear_evento("x", "canal_inventado", "fixture")
	_comprobar(invalido.is_empty(), "un canal inventado se rechaza")

	var exposicion := Eventos.crear_evento(
		"expo-libro",
		Eventos.CANAL_EXPOSICION,
		"libro:fixture",
		"careo:archivo",
		1,
		"tradicion_fixture",
		[],
		[Conflicto.REGLA_NO_INICIAR]
	)
	_comprobar(Eventos.registrar(registro, exposicion), "la exposición se registra")
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_PRACTICA).is_empty(), "exposición no crea práctica"
	)
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_CONVICCION).is_empty(),
		"exposición no crea convicción"
	)
	_comprobar(
		Conflicto.compromisos_disponibles(registro, "careo:archivo").is_empty(),
		"la exposición no concede compromisos de combate"
	)

	var practica := Eventos.crear_evento(
		"practica-voto",
		Eventos.CANAL_PRACTICA,
		"escena:fixture",
		"juicio:caso-1",
		1,
		"tradicion_a",
		["voluntario"],
		[Conflicto.REGLA_NO_INICIAR]
	)
	_comprobar(Eventos.registrar(registro, practica), "la práctica explícita se registra")
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_CONVICCION).is_empty(),
		"practicar no infiere convicción"
	)
	_comprobar(
		not Eventos.registrar(
			registro,
			Eventos.crear_evento(
				"practica-voto", Eventos.CANAL_CONVICCION, "dialogo:fixture", "juicio:caso-1"
			)
		),
		"un mismo hecho no puede reaparecer en otro canal"
	)
	_comprobar(
		Conflicto.compromisos_disponibles(registro, "juicio:otro").is_empty(),
		"el compromiso no sale de su contexto"
	)

	var compromisos := Conflicto.compromisos_disponibles(registro, "juicio:caso-1")
	_comprobar(compromisos.size() == 1, "la práctica habilita una regla contextual")
	var voto: Dictionary = compromisos[0]
	_comprobar(
		not Conflicto.puede_iniciar_accion_ofensiva(voto, false),
		"el voto obliga a ceder la iniciativa"
	)
	_comprobar(
		Conflicto.puede_iniciar_accion_ofensiva(voto, true),
		"el voto permite responder tras iniciativa rival"
	)
	_comprobar(
		Conflicto.puede_iniciar_accion_ofensiva({}, false),
		"sin compromiso el combate base conserva la iniciativa"
	)

	var vinculo := Eventos.crear_evento(
		"vinculo-centro",
		Eventos.CANAL_VINCULO,
		"relacion:fixture",
		"juicio:caso-1",
		1,
		"",
		[],
		[Conflicto.REGLA_NO_INICIAR]
	)
	_comprobar(Eventos.registrar(registro, vinculo), "un vínculo observable se registra")
	_comprobar(
		Conflicto.compromisos_disponibles(registro, "juicio:caso-1").size() == 1,
		"un vínculo no se convierte en obligación personal"
	)

	var tregua_privada := Eventos.crear_evento(
		"tregua-privada",
		Eventos.CANAL_PRACTICA,
		"escena:fixture",
		"juicio:caso-2",
		1,
		"tradicion_a",
		[],
		[Conflicto.REGLA_TREGUA_MUTUA],
		false,
		["rival-1"]
	)
	Eventos.registrar(registro, tregua_privada)
	_comprobar(
		Conflicto.compromisos_disponibles(registro, "juicio:caso-2", "rival-1").is_empty(),
		"una práctica privada no produce conocimiento rival"
	)

	var tregua_desconocida := Eventos.crear_evento(
		"tregua-publica-desconocida",
		Eventos.CANAL_CONVICCION,
		"declaracion:fixture",
		"juicio:caso-3",
		1,
		"tradicion_a",
		[],
		[Conflicto.REGLA_TREGUA_MUTUA],
		true,
		["otro-actor"]
	)
	Eventos.registrar(registro, tregua_desconocida)
	_comprobar(
		Conflicto.compromisos_disponibles(registro, "juicio:caso-3", "rival-1").is_empty(),
		"lo público no equivale a que este rival lo conozca"
	)

	var tregua_conocida := Eventos.crear_evento(
		"tregua-publica-conocida",
		Eventos.CANAL_CONVICCION,
		"declaracion:fixture",
		"juicio:caso-4",
		1,
		"tradicion_b",
		[],
		[Conflicto.REGLA_TREGUA_MUTUA],
		true,
		["rival-1"]
	)
	Eventos.registrar(registro, tregua_conocida)
	var mutuos := Conflicto.compromisos_disponibles(registro, "juicio:caso-4", "rival-1")
	_comprobar(mutuos.size() == 1, "una tregua conocida puede ser bilateral")
	_comprobar(Conflicto.tregua_mutua_activa(mutuos[0]), "la tregua declara alcance mutuo")
	_comprobar(
		float(mutuos[0].get("duracion", 0.0)) == Conflicto.DURACION_TREGUA_TEMPORAL,
		"la tregua bilateral expone una ventana temporal explícita",
	)

	var registro_a := Eventos.nuevo()
	var registro_b := Eventos.nuevo()
	Eventos.registrar(
		registro_a,
		Eventos.crear_evento(
			"voto-a",
			Eventos.CANAL_PRACTICA,
			"fixture:a",
			"juicio:equidad",
			1,
			"tradicion_a",
			[],
			[Conflicto.REGLA_NO_INICIAR]
		)
	)
	Eventos.registrar(
		registro_b,
		Eventos.crear_evento(
			"voto-b",
			Eventos.CANAL_PRACTICA,
			"fixture:b",
			"juicio:equidad",
			1,
			"tradicion_b",
			[],
			[Conflicto.REGLA_NO_INICIAR]
		)
	)
	var regla_a: Dictionary = Conflicto.compromisos_disponibles(registro_a, "juicio:equidad")[0]
	var regla_b: Dictionary = Conflicto.compromisos_disponibles(registro_b, "juicio:equidad")[0]
	_comprobar(
		(
			[
				regla_a["regla"],
				regla_a["alcance"],
				regla_a["etiquetas"],
			]
			== [
				regla_b["regla"],
				regla_b["alcance"],
				regla_b["etiquetas"],
			]
		),
		"cambiar la tradición no cambia la potencia de la regla"
	)

	var serializado := JSON.stringify(registro)
	_comprobar(not serializado.contains('"fe"'), "el contrato no crea una barra de fe")
	_comprobar(
		not serializado.contains('"religion"'), "el contrato no asigna una religión al jugador"
	)

	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s" % nombre)
