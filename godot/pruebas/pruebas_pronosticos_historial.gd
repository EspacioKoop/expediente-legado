extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	var visor = load("res://escenas/visor.tscn").instantiate()
	root.add_child(visor)
	await process_frame

	visor.partida.estado = Partida.nueva()
	visor.jornada = visor.partida.estado["jornada"]
	visor.descubiertas = visor.partida.estado["pistas_descubiertas"]
	visor.caso = visor.contenido.casos[0]

	var casos: Array = visor.contenido.casos
	var estado: Dictionary = visor.partida.estado["pronosticos"]
	var id_acierto := String(casos[0]["id"])
	var id_fallo := String(casos[1]["id"])
	var id_abandono := String(casos[2]["id"])
	var id_sin_resolver := String(casos[3]["id"])

	Pronosticos.crear(estado, id_acierto, "habra_duelo", true)
	Pronosticos.resolver(estado, id_acierto, true)
	Pronosticos.crear(estado, id_fallo, "cierre_hoy", true)
	Pronosticos.resolver(estado, id_fallo, false)
	Pronosticos.crear(estado, id_abandono, "arrastra_manana", false)
	Pronosticos.abandonar(estado, id_abandono)
	Pronosticos.crear(estado, id_sin_resolver, "documento_clave", "FACTURA")
	Pronosticos.resolver(estado, id_sin_resolver, null)

	var antes: Dictionary = estado.duplicate(true)
	var esperado := Pronosticos.historial(estado)
	visor._abrir_historial_pronosticos()
	await process_frame

	_comprobar(visor._ventana_historial != null, "el botón abre una ventana de historial")
	_comprobar(
		visor._pronostico_historial_lista != null,
		"la ventana expone una lista navegable",
	)
	_comprobar(
		visor._pronostico_historial_lista.item_count == esperado.size(),
		"la lista contiene todos los pronósticos registrados",
	)

	var estados := []
	for i in esperado.size():
		var fila: Dictionary = esperado[i]
		estados.append(String(fila["estado"]))
		_comprobar(
			String(visor._pronostico_historial_lista.get_item_metadata(i))
			== String(fila["expediente"]),
			"el historial visible conserva el orden determinista",
		)
	_comprobar(estados.has(Pronosticos.ESTADO_ACERTADO), "el historial incluye aciertos")
	_comprobar(estados.has(Pronosticos.ESTADO_FALLADO), "el historial incluye fallos")
	_comprobar(estados.has(Pronosticos.ESTADO_ABANDONADO), "el historial incluye abandonos")
	_comprobar(
		estados.has(Pronosticos.ESTADO_SIN_RESOLVER),
		"el historial incluye pronósticos sin resolver",
	)
	_comprobar(estado == antes, "consultar el historial no muta los pronósticos")

	visor._cerrar_historial_pronosticos()
	await process_frame
	_comprobar(visor._ventana_historial == null, "cerrar descarta la ventana temporal")

	visor.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO PronosticosHistorial: " + nombre)
