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
	visor._actualizar_pronostico()

	_comprobar(not visor._pronostico_confirmar.disabled, "se puede pronosticar antes de leer")
	_comprobar(visor._pronostico_abandonar.disabled, "sin apuesta no se puede abandonar")
	var acciones_antes: int = visor.jornada["acciones"]
	visor._al_confirmar_pronostico()
	var primero: Dictionary = visor.partida.estado["pronosticos"]["por_expediente"][String(
		visor.caso["id"]
	)]
	_comprobar(primero["tipo"] == "habra_duelo", "la tarjeta conserva el tipo elegido")
	_comprobar(primero["valor"] == true, "la tarjeta conserva el valor elegido")
	_comprobar(
		primero["estado"] == Pronosticos.ESTADO_ABIERTO,
		"confirmar deja el pronóstico abierto",
	)
	_comprobar(visor.jornada["acciones"] == acciones_antes, "apostar no consume acciones")
	_comprobar(visor.partida.estado["veredictos"].is_empty(), "apostar no crea veredictos")

	var primer_registro: Dictionary = visor.caso["registros"][0]
	visor.jornada["leidos_total"] = [primer_registro["id"]]
	visor._actualizar_pronostico()
	_comprobar(
		not visor._pronostico_abandonar.disabled,
		"una apuesta abierta se puede abandonar después de leer",
	)
	visor._al_abandonar_pronostico()
	_comprobar(
		primero["estado"] == Pronosticos.ESTADO_ABANDONADO,
		"abandonar no convierte la apuesta en fallo",
	)

	visor._al_elegir_caso(1)
	var segundo_id := String(visor.caso["id"])
	var segundo_registro: Dictionary = visor.caso["registros"][0]
	visor.jornada["leidos_total"] = [segundo_registro["id"]]
	visor.jornada["leido_hoy"] = []
	visor._actualizar_pronostico()
	_comprobar(
		visor._pronostico_confirmar.disabled, "un expediente expuesto bloquea apuesta tardía"
	)
	visor._al_confirmar_pronostico()
	_comprobar(
		not visor.partida.estado["pronosticos"]["por_expediente"].has(segundo_id),
		"el bloqueo visual coincide con el contrato",
	)

	visor.jornada["leidos_total"] = []
	visor.jornada["leido_hoy"] = []
	var indice_documento := _indice_tipo(visor, "documento_clave")
	_comprobar(indice_documento >= 0, "la tarjeta ofrece documento clave")
	if indice_documento >= 0:
		visor._pronostico_tipo.select(indice_documento)
		visor._al_cambiar_tipo_pronostico(indice_documento)
		_comprobar(
			visor._pronostico_valor.item_count > 0,
			"documento clave usa tipos ya visibles del expediente",
		)
		visor._al_confirmar_pronostico()
		var segundo: Dictionary = visor.partida.estado["pronosticos"]["por_expediente"][segundo_id]
		_comprobar(segundo["tipo"] == "documento_clave", "confirma un pronóstico categórico")

	visor.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _indice_tipo(visor, tipo: String) -> int:
	for i in visor._pronostico_tipo.item_count:
		if String(visor._pronostico_tipo.get_item_metadata(i)) == tipo:
			return i
	return -1


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO PronosticosVisor: " + nombre)
