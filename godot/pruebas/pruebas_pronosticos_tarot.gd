extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_resolucion_tarot()
	_probar_fallo_tarot()
	_probar_acierto_tras_otro_arcano()
	_probar_otro_tipo_intacto()
	_probar_cierre_sin_hallazgo()
	_probar_historial_malformado()
	await _probar_selector_global()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_resolucion_tarot() -> void:
	var estado := Partida.nueva()
	Pronosticos.crear(estado["pronosticos"], "caso-tarot", "tarot", "el-mago")
	var resultado := PronosticosAuditoria.resolver_tarot(estado, "caso-tarot", "el-mago")
	_comprobar(resultado == Pronosticos.ESTADO_ACERTADO, "el arcano esperado acierta")


func _probar_fallo_tarot() -> void:
	var estado := Partida.nueva()
	Pronosticos.crear(estado["pronosticos"], "caso-tarot", "tarot", "la-luna")
	var resultado := PronosticosAuditoria.resolver_tarot(estado, "caso-tarot", "el-mago")
	_comprobar(
		resultado == Pronosticos.ESTADO_ABIERTO,
		"un arcano distinto no falla mientras el expediente siga abierto",
	)
	var caso := {"id": "caso-tarot", "registros": [], "pistas": []}
	var acusacion := {"resultado": "cerrado", "duelo": {}, "precipitada": false}
	resultado = PronosticosAuditoria.resolver_cierre(estado, caso, acusacion)
	_comprobar(
		resultado == Pronosticos.ESTADO_FALLADO,
		"cerrar tras ver otros arcanos falla si nunca apareció el elegido",
	)


func _probar_acierto_tras_otro_arcano() -> void:
	var estado := Partida.nueva()
	Pronosticos.crear(estado["pronosticos"], "caso-tarot", "tarot", "la-luna")
	PronosticosAuditoria.resolver_tarot(estado, "caso-tarot", "el-mago")
	var resultado := PronosticosAuditoria.resolver_tarot(estado, "caso-tarot", "la-luna")
	_comprobar(
		resultado == Pronosticos.ESTADO_ACERTADO,
		"el arcano elegido puede acertar después de otro hallazgo",
	)


func _probar_otro_tipo_intacto() -> void:
	var estado := Partida.nueva()
	Pronosticos.crear(estado["pronosticos"], "caso-duelo", "habra_duelo", true)
	var resultado := PronosticosAuditoria.resolver_tarot(estado, "caso-duelo", "el-mago")
	_comprobar(resultado == Pronosticos.ESTADO_ABIERTO, "tarot no resuelve apuestas de otro tipo")


func _probar_cierre_sin_hallazgo() -> void:
	var estado := Partida.nueva()
	Pronosticos.crear(estado["pronosticos"], "caso-vacio", "tarot", "el-mago")
	var caso := {"id": "caso-vacio", "registros": [], "pistas": []}
	var acusacion := {"resultado": "cerrado", "duelo": {}, "precipitada": false}
	var resultado := PronosticosAuditoria.resolver_cierre(estado, caso, acusacion)
	_comprobar(
		resultado == Pronosticos.ESTADO_SIN_RESOLVER,
		"cerrar sin hallazgo deja el pronóstico sin resolver",
	)


func _probar_historial_malformado() -> void:
	var estado := Partida.nueva()
	Pronosticos.crear(estado["pronosticos"], "caso-corrupto", "tarot", "el-mago")
	var actual: Dictionary = estado["pronosticos"]["por_expediente"]["caso-corrupto"]
	actual["tarot_vistos"] = "no-es-lista"
	var resultado := PronosticosAuditoria.resolver_tarot(estado, "caso-corrupto", "el-mago")
	_comprobar(
		resultado == Pronosticos.ESTADO_ACERTADO,
		"un historial tarot malformado se normaliza sin bloquear el hallazgo",
	)
	_comprobar(
		actual["tarot_vistos"] == ["el-mago"],
		"la normalización sustituye el valor corrupto por historial válido",
	)


func _probar_selector_global() -> void:
	var visor = load("res://escenas/visor.tscn").instantiate()
	root.add_child(visor)
	await process_frame

	visor.partida.estado = Partida.nueva()
	visor.jornada = visor.partida.estado["jornada"]
	visor.descubiertas = visor.partida.estado["pistas_descubiertas"]
	visor.caso = visor.contenido.casos[0]
	visor._actualizar_pronostico()

	var indice := _indice_tipo(visor, "tarot")
	_comprobar(indice >= 0, "la tarjeta ofrece pronóstico de tarot")
	if indice >= 0:
		visor._pronostico_tipo.select(indice)
		visor._al_cambiar_tipo_pronostico(indice)
		var esperadas := 0
		for carta in visor.partida.estado.get("tarot", []):
			if not carta.get("recogida", false):
				esperadas += 1
		_comprobar(
			visor._pronostico_valor.item_count == esperadas,
			"el selector ofrece todo el catálogo no recogido",
		)
		_comprobar(
			not _contiene_valor(visor._pronostico_valor, "el-loco"),
			"una carta ya poseída no se ofrece como futura",
		)

		var elegido := ""
		for i in visor._pronostico_valor.item_count:
			var carta_id := String(visor._pronostico_valor.get_item_metadata(i))
			if carta_id == "el-mago":
				visor._pronostico_valor.select(i)
				elegido = carta_id
				break
		_comprobar(elegido == "el-mago", "El Mago está disponible antes de descubrir pistas")
		if not elegido.is_empty():
			visor._al_confirmar_pronostico()
			visor._al_carta_desbloqueada("el-mago")
			var actual: Dictionary = visor.partida.estado["pronosticos"]["por_expediente"][String(
				visor.caso["id"]
			)]
			_comprobar(
				actual["estado"] == Pronosticos.ESTADO_ACERTADO,
				"el hook del visor resuelve con el hallazgo real",
			)
			_comprobar(
				visor._pronostico_abandonar.disabled,
				"la tarjeta deja de ofrecer abandono al quedar resuelta",
			)

	visor.queue_free()
	await process_frame


func _indice_tipo(visor, tipo: String) -> int:
	for i in visor._pronostico_tipo.item_count:
		if String(visor._pronostico_tipo.get_item_metadata(i)) == tipo:
			return i
	return -1


func _contiene_valor(opciones: OptionButton, valor: String) -> bool:
	for i in opciones.item_count:
		if String(opciones.get_item_metadata(i)) == valor:
			return true
	return false


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO PronosticosTarot: " + nombre)
