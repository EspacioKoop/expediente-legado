extends SceneTree

const Eventos = preload("res://guion/religion_eventos.gd")

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_snapshot_factual()
	_probar_sin_declaracion()
	_probar_archivado_reset_y_persistencia()
	_probar_validacion()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_snapshot_factual() -> void:
	var estado := Partida.nueva()
	var registro := Eventos.asegurar_en_estado(estado)
	_registrar(registro, "expo", Eventos.CANAL_EXPOSICION)
	_registrar(registro, "practica", Eventos.CANAL_PRACTICA)
	_registrar(
		registro,
		"duda",
		Eventos.CANAL_CONVICCION,
		Eventos.DECLARACION_DUDA,
	)
	_registrar(
		registro,
		"cambio",
		Eventos.CANAL_CONVICCION,
		Eventos.DECLARACION_CAMBIO,
	)
	_registrar(registro, "vinculo", Eventos.CANAL_VINCULO, "", "comunidad:archivo")

	var resumen := Eventos.resumen_trayectoria(estado)
	var canales: Dictionary = resumen.get("canales", {})
	_comprobar(int(resumen.get("vuelta", 0)) == 1, "el snapshot usa la vuelta activa")
	_comprobar(
		canales.get(Eventos.CANAL_EXPOSICION, []).size() == 1,
		"conserva exposición como hecho independiente",
	)
	_comprobar(
		canales.get(Eventos.CANAL_PRACTICA, []).size() == 1,
		"conserva práctica sin convertirla en convicción",
	)
	var convicciones: Array = canales.get(Eventos.CANAL_CONVICCION, [])
	_comprobar(convicciones.size() == 2, "conserva declaraciones contradictorias en orden")
	_comprobar(
		String(convicciones[0].get("declaracion", "")) == Eventos.DECLARACION_DUDA,
		"la duda sigue siendo una declaración explícita",
	)
	_comprobar(
		String(convicciones[1].get("declaracion", "")) == Eventos.DECLARACION_CAMBIO,
		"el cambio no borra la declaración previa",
	)
	var vinculos: Array = canales.get(Eventos.CANAL_VINCULO, [])
	_comprobar(
		vinculos.size() == 1 and String(vinculos[0].get("actor", "")) == "comunidad:archivo",
		"el vínculo conserva el actor observable",
	)
	var serializado := JSON.stringify(resumen)
	_comprobar(not serializado.contains('"puntuacion"'), "no crea una puntuación religiosa")
	_comprobar(not serializado.contains('"identidad"'), "no infiere una identidad religiosa")


func _probar_sin_declaracion() -> void:
	var estado := Partida.nueva()
	var registro := Eventos.asegurar_en_estado(estado)
	_registrar(registro, "solo-exposicion", Eventos.CANAL_EXPOSICION)
	var resumen := Eventos.resumen_trayectoria(estado)
	var canales: Dictionary = resumen.get("canales", {})
	var convicciones: Array = canales.get(Eventos.CANAL_CONVICCION, [])
	_comprobar(convicciones.is_empty(), "ausencia de declaración permanece ausencia")
	_comprobar(
		not JSON.stringify(resumen).contains(Eventos.DECLARACION_NO_ADSCRIPCION),
		"no adscripción solo existe si fue declarada",
	)


func _probar_archivado_reset_y_persistencia() -> void:
	var estado := Partida.nueva()
	var registro := Eventos.asegurar_en_estado(estado)
	_registrar(
		registro,
		"no-adscripcion",
		Eventos.CANAL_CONVICCION,
		Eventos.DECLARACION_NO_ADSCRIPCION,
	)
	_registrar(registro, "practica-social", Eventos.CANAL_PRACTICA)
	var registro_antes := JSON.stringify(registro)

	Prometeo.reiniciar_vuelta(estado, 3)
	var historial := Eventos.historial_trayectorias(estado)
	_comprobar(historial.size() == 1, "el reset sella una instantánea por vida")
	Prometeo.reiniciar_vuelta(estado, 3)
	_comprobar(
		Eventos.historial_trayectorias(estado).size() == 1,
		"repetir el cierre de la misma vuelta no duplica historial",
	)
	_comprobar(
		JSON.stringify(Eventos.asegurar_en_estado(estado)) == registro_antes,
		"sellar no reescribe los cuatro canales canónicos",
	)

	Jornada.reiniciar_vuelta(estado["jornada"])
	var registro_nueva := Eventos.asegurar_en_estado(estado)
	_comprobar(
		(
			Eventos
			. eventos_de_vuelta(
				registro_nueva,
				Eventos.CANAL_CONVICCION,
				2,
			)
			. is_empty()
		),
		"la vida nueva no hereda una convicción como estado activo",
	)

	var ruta := "user://prueba_religion_trayectoria_937.json"
	_limpiar(ruta)
	var partida := Partida.new()
	partida.estado = estado
	_comprobar(partida.guardar(ruta), "Partida persiste el historial factual")
	var releida := Partida.new()
	var carga := releida.cargar(ruta)
	_comprobar(String(carga.get("resultado", "")) == "cargada", "el historial vuelve a cargar")
	var historial_releido := Eventos.historial_trayectorias(releida.estado)
	_comprobar(
		historial_releido.size() == 1 and int(historial_releido[0].get("vuelta", 0)) == 1,
		"round-trip conserva la instantánea de la vida cerrada",
	)
	_limpiar(ruta)


func _probar_validacion() -> void:
	var estado := Partida.nueva()
	var registro := Eventos.asegurar_en_estado(estado)
	_registrar(registro, "exposicion-validable", Eventos.CANAL_EXPOSICION)
	Eventos.archivar_trayectoria(estado, "prueba")
	_comprobar(Partida.validar(estado).is_empty(), "Partida acepta un historial factual válido")

	var corrupto := estado.duplicate(true)
	var historial: Array = corrupto[Eventos.CLAVE_HISTORIAL]
	var canales: Dictionary = historial[0]["canales"]
	var exposiciones: Array = canales[Eventos.CANAL_EXPOSICION]
	exposiciones[0]["vuelta"] = 2
	var errores := Partida.validar(corrupto)
	var detectado := false
	for error in errores:
		if String(error).contains("pertenece a otra vuelta"):
			detectado = true
	_comprobar(detectado, "Partida rechaza hechos archivados bajo otra vuelta")


func _registrar(
	registro: Dictionary,
	sufijo: String,
	canal: String,
	declaracion: String = "",
	actor: String = "",
) -> void:
	var metadatos := {
		"vuelta": 1,
		"procedencia": "prueba:937",
	}
	if not declaracion.is_empty():
		metadatos["declaracion"] = declaracion
	if not actor.is_empty():
		metadatos["actor"] = actor
	var evento := (
		Eventos
		. crear_evento(
			"937:%s" % sufijo,
			canal,
			"prueba:937",
			"contexto:937",
			3,
			"",
			[],
			[],
			false,
			[],
			metadatos,
		)
	)
	_comprobar(Eventos.registrar(registro, evento), "registra %s en su canal" % sufijo)


func _limpiar(ruta: String) -> void:
	for sufijo in ["", ".nuevo", ".roto"]:
		var destino: String = ruta + String(sufijo)
		if FileAccess.file_exists(destino):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(destino))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO #937: %s" % nombre)
