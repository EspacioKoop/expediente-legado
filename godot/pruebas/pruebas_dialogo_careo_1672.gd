extends SceneTree

const ESCENA := preload("res://escenas/careo.tscn")
const RUTA := "user://prueba_dialogo_careo_1672.json"

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_limpiar()
	_probar_modelo()
	await _probar_escena()
	_probar_persistencia()
	_limpiar()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_modelo() -> void:
	var jornada := {"dia": 3}
	var sin_contexto := DialogoCareoContextual.opciones(false)
	var con_contexto := DialogoCareoContextual.opciones(true)
	_comprobar(sin_contexto.size(), 2, "sin contexto documental hay dos enfoques")
	_comprobar(con_contexto.size(), 3, "el contexto conocido habilita contraste")
	_comprobar(con_contexto[-1]["id"], "contraste", "contraste es una rama explícita")

	var primera := DialogoCareoContextual.registrar(jornada, "folio-a", "pragmatica")
	_comprobar(primera.get("nueva"), true, "la primera rama registra memoria")
	var repetida := DialogoCareoContextual.registrar(jornada, "folio-a", "version")
	_comprobar(repetida.get("nueva"), false, "la reentrada no reescribe la memoria")
	_comprobar(
		jornada[DialogoCareoContextual.CAMPO]["folio-a"]["rama"],
		"pragmatica",
		"primera escritura gana",
	)
	_comprobar(
		DialogoCareoContextual.reentrada(jornada, "folio-a"),
		"DIALOGO_CAREO_PRAGMATICA_REENTRADA",
		"la memoria produce una secuela específica",
	)


func _probar_escena() -> void:
	var estado := {
		"jornada": {"dia": 4},
		"pistas_descubiertas": [],
	}
	var careo = ESCENA.instantiate()
	careo.acusado = {"nombre": "Reclamante", "ataques": []}
	careo.folio = "folio-runtime"
	careo.estado = estado
	root.add_child(careo)
	await process_frame
	careo._empezar_duelo()
	await process_frame

	_comprobar(careo._opciones_dialogo != null, true, "el careo monta opciones antes del duelo")
	_comprobar(
		careo._opciones_dialogo.get_child_count(),
		2,
		"sin conclusión documental muestra dos respuestas",
	)
	_comprobar(careo._botones.visible, false, "el combate espera a la conversación")
	var combate_antes: Dictionary = careo._combate.duplicate(true)
	var boton_version := careo._opciones_dialogo.get_child(1) as Button
	boton_version.pressed.emit()
	await process_frame
	_comprobar(careo._botones.visible, true, "elegir devuelve el control al combate")
	_comprobar(careo._combate, combate_antes, "dialogar no modifica el estado del combate")
	_comprobar(
		estado["jornada"][DialogoCareoContextual.CAMPO]["folio-runtime"]["rama"],
		"version",
		"la escena registra la rama elegida",
	)
	_comprobar(estado["pistas_descubiertas"], [], "el diálogo no fabrica pistas")
	careo.queue_free()
	await process_frame

	var reentrada = ESCENA.instantiate()
	reentrada.acusado = {"nombre": "Reclamante", "ataques": []}
	reentrada.folio = "folio-runtime"
	reentrada.estado = estado
	root.add_child(reentrada)
	await process_frame
	reentrada._empezar_duelo()
	await process_frame
	_comprobar(reentrada._opciones_dialogo == null, true, "reentrar no repite el selector")
	_comprobar(reentrada._botones.visible, true, "reentrada deja disponible el duelo")
	var texto_reentrada := TranslationServer.translate("DIALOGO_CAREO_VERSION_REENTRADA")
	_comprobar(
		reentrada._cronica.text.begins_with(texto_reentrada),
		true,
		"reentrada recuerda el enfoque sin alterar hechos",
	)
	reentrada.queue_free()
	await process_frame


func _probar_persistencia() -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	var jornada: Dictionary = partida.estado["jornada"]
	DialogoCareoContextual.registrar(jornada, "folio-guardado", "contraste")
	partida.estado["jornada"] = jornada
	_comprobar(partida.guardar(RUTA), true, "la memoria ligera cabe en el guardado normal")

	var releida := Partida.new()
	var carga := releida.cargar(RUTA)
	_comprobar(carga.get("resultado"), "cargada", "la partida con memoria se recarga")
	_comprobar(
		DialogoCareoContextual.reentrada(releida.estado["jornada"], "folio-guardado"),
		"DIALOGO_CAREO_CONTRASTE_REENTRADA",
		"guardar y recargar conserva la reentrada",
	)


func _limpiar() -> void:
	for sufijo in ["", ".nuevo", ".roto"]:
		var ruta: String = RUTA + sufijo
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(actual, esperado, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO diálogo careo: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
