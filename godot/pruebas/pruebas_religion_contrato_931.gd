extends SceneTree

const Eventos = preload("res://guion/religion_eventos.gd")
const Mundo = preload("res://guion/religion_mundo_934.gd")

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_fuente_unica_y_canales()
	_probar_declaraciones_y_vinculos()
	_probar_persistencia_y_reset()
	_probar_validacion()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_fuente_unica_y_canales() -> void:
	var estado := Partida.nueva()
	var registro := Eventos.asegurar_en_estado(estado)
	_comprobar(
		registro == estado[Eventos.CLAVE_ESTADO],
		"Partida expone el registro común de religión",
	)
	_comprobar(
		Mundo.registrar_exposicion(registro, "tablon_calendario", Mundo.DIA_ACTO_MEMORIA, 2),
		"el mundo escribe exposición en el registro común",
	)
	_comprobar(
		Mundo.registrar_practica(registro, "silencio_memoria", Mundo.DIA_ACTO_MEMORIA, 2),
		"el mundo escribe práctica en el mismo registro",
	)
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_EXPOSICION).size() == 1,
		"exposición permanece en su canal",
	)
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_PRACTICA).size() == 1,
		"práctica permanece en su canal",
	)
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_CONVICCION).is_empty(),
		"exposición y práctica no infieren convicción",
	)
	var exposicion: Dictionary = Eventos.eventos(registro, Eventos.CANAL_EXPOSICION)[0]
	var practica: Dictionary = Eventos.eventos(registro, Eventos.CANAL_PRACTICA)[0]
	_comprobar(exposicion["vuelta"] == 2, "la exposición registra la vuelta")
	_comprobar(practica["vuelta"] == 2, "la práctica registra la vuelta")
	_comprobar(
		String(exposicion["procedencia"]) == "mundo:interaccion:examinar",
		"la exposición conserva procedencia",
	)
	_comprobar(
		String(practica["procedencia"]) == "mundo:interaccion:participar",
		"la práctica conserva procedencia",
	)


func _probar_declaraciones_y_vinculos() -> void:
	var registro := Eventos.nuevo()
	for declaracion in [
		Eventos.DECLARACION_NO_ADSCRIPCION,
		Eventos.DECLARACION_DUDA,
		Eventos.DECLARACION_CAMBIO,
	]:
		var evento := (
			Eventos
			. crear_evento(
				"declaracion:%s" % declaracion,
				Eventos.CANAL_CONVICCION,
				"dialogo:protagonista",
				"conversacion:archivo",
				4,
				"fixture",
				[],
				[],
				false,
				[],
				{
					"vuelta": 1,
					"procedencia": "dialogo:declaracion_directa",
					"declaracion": declaracion,
				},
			)
		)
		_comprobar(Eventos.registrar(registro, evento), "se registra %s" % declaracion)

	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_CONVICCION).size() == 3,
		"duda, no adscripción y cambio conservan historia propia",
	)
	_comprobar(
		String(Eventos.ultima_declaracion(registro)["declaracion"]) == Eventos.DECLARACION_CAMBIO,
		"la postura actual se deriva de la última declaración explícita",
	)

	var vinculo := (
		Eventos
		. crear_evento(
			"vinculo:archivo:comunidad",
			Eventos.CANAL_VINCULO,
			"dialogo:npc_archivo",
			"archivo",
			4,
			"",
			["contacto_directo"],
			[],
			false,
			[],
			{
				"vuelta": 1,
				"procedencia": "dialogo:directo",
				"actor": "npc:archivo",
			},
		)
	)
	_comprobar(Eventos.registrar(registro, vinculo), "se registra un vínculo observable")
	var por_actor := Eventos.vinculos_por_actor(registro)
	_comprobar(por_actor.get("npc:archivo", []).size() == 1, "el vínculo se indexa por actor")
	_comprobar(
		por_actor.get("npc:otro", []).is_empty(),
		"otro actor no conoce automáticamente el vínculo",
	)

	var serializado := JSON.stringify(registro)
	_comprobar(not serializado.contains('"fe":'), "no existe una barra de fe")
	_comprobar(not serializado.contains('"religiosidad":'), "no existe puntuación de religiosidad")


func _probar_persistencia_y_reset() -> void:
	var ruta := "user://prueba_religion_931.json"
	_limpiar(ruta)
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	var registro := Eventos.asegurar_en_estado(partida.estado)
	var evento := (
		Eventos
		. crear_evento(
			"exposicion:persistente",
			Eventos.CANAL_EXPOSICION,
			"fixture:persistencia",
			"archivo",
			6,
			"",
			["fixture"],
			[],
			false,
			[],
			{"vuelta": 3, "procedencia": "prueba:directa"},
		)
	)
	Eventos.registrar(registro, evento)
	var antes := JSON.stringify(registro)

	Jornada.reiniciar_vuelta(partida.estado["jornada"])
	_comprobar(
		JSON.stringify(Eventos.asegurar_en_estado(partida.estado)) == antes,
		"reasignar no borra hechos históricos de religión",
	)
	_comprobar(partida.guardar(ruta), "Partida guarda el registro religioso")

	var releida := Partida.new()
	var carga := releida.cargar(ruta)
	_comprobar(
		String(carga.get("resultado", "")) == "cargada", "Partida vuelve a cargar el registro"
	)
	var registro_releido := Eventos.asegurar_en_estado(releida.estado)
	var exposiciones_releidas := Eventos.eventos(registro_releido, Eventos.CANAL_EXPOSICION)
	var evento_releido: Dictionary = exposiciones_releidas[0] if exposiciones_releidas.size() == 1 else {}
	_comprobar(
		(
			exposiciones_releidas.size() == 1
			and String(evento_releido.get("id", "")) == "exposicion:persistente"
			and int(evento_releido.get("jornada", -1)) == 6
			and int(evento_releido.get("vuelta", -1)) == 3
			and String(evento_releido.get("procedencia", "")) == "prueba:directa"
		),
		"el hecho religioso conserva semántica tras guardado y recarga",
	)

	var nueva := Partida.nueva()
	_comprobar(
		(
			Eventos
			. eventos(
				Eventos.asegurar_en_estado(nueva),
				Eventos.CANAL_EXPOSICION,
			)
			. is_empty()
		),
		"una partida nueva sí reinicia la trayectoria religiosa",
	)
	_limpiar(ruta)


func _probar_validacion() -> void:
	var estado := Partida.nueva()
	var registro := Eventos.asegurar_en_estado(estado)
	var evento := (
		Eventos
		. crear_evento(
			"duplicado",
			Eventos.CANAL_EXPOSICION,
			"fixture",
		)
	)
	Eventos.registrar(registro, evento)
	var corrupto := estado.duplicate(true)
	corrupto[Eventos.CLAVE_ESTADO][Eventos.CANAL_PRACTICA].append(evento.duplicate(true))
	var errores := Partida.validar(corrupto)
	var detectado := false
	for error in errores:
		if String(error).contains("id duplicado"):
			detectado = true
	_comprobar(detectado, "Partida rechaza un mismo hecho duplicado entre canales")

	var invalido := (
		Eventos
		. crear_evento(
			"declaracion-invalida",
			Eventos.CANAL_EXPOSICION,
			"fixture",
			"",
			0,
			"",
			[],
			[],
			false,
			[],
			{"declaracion": Eventos.DECLARACION_DUDA},
		)
	)
	_comprobar(invalido.is_empty(), "una exposición no puede declarar convicción implícitamente")


func _limpiar(ruta: String) -> void:
	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	if FileAccess.file_exists(ruta + ".nuevo"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta + ".nuevo"))
	if FileAccess.file_exists(ruta + ".roto"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta + ".roto"))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO #931: %s" % nombre)
