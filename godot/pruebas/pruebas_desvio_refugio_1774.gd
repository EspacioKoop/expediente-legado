extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var jornada := {"dia": 1}
	var calle := Node3D.new()
	root.add_child(calle)
	var refugio := DesvioRefugio3D.montar(calle, jornada)
	_comprobar(refugio != null, "monta el refugio")
	_comprobar(jornada == {"dia": 1}, "montar no muta Jornada")
	_comprobar(
		DesvioRefugio3D.montar(calle, jornada) == refugio,
		"montaje idempotente",
	)
	if refugio != null:
		_comprobar(refugio.get_node_or_null("EntradaDesvio") != null, "entrada lateral visible")
		_comprobar(refugio.get_node_or_null("SalidaDesvio") != null, "salida al camino visible")
		_comprobar(refugio.get_node_or_null("FondoRefugio") != null, "fondo del desvío visible")
		_comprobar(bool(refugio.get_meta("retorno_principal", false)), "declara retorno al camino")
		_comprobar(
			refugio.find_children("*", "StaticBody3D", true, false).is_empty(),
			"no crea cuerpos sólidos",
		)
		_comprobar(
			refugio.find_children("*", "CollisionShape3D", true, false).is_empty(),
			"no crea colisiones de softlock",
		)
		_comprobar(
			refugio.get_node_or_null("GoteoBorde2") == null,
			"despejado no inventa precipitación",
		)

	var calle_lluvia := Node3D.new()
	root.add_child(calle_lluvia)
	var lluvia := DesvioRefugio3D.montar(calle_lluvia, {"dia": 1, "clima_forzado": Clima.LLUVIA})
	_comprobar(bool(lluvia.get_meta("precipitacion", false)), "lluvia activa lectura de refugio")
	_comprobar(lluvia.get_node_or_null("CharcoExterior") != null, "lluvia queda fuera del suelo seco")
	_comprobar(lluvia.get_node_or_null("GoteoBorde2") != null, "lluvia gotea en el borde")

	var calle_nieve := Node3D.new()
	root.add_child(calle_nieve)
	var nieve := DesvioRefugio3D.montar(calle_nieve, {"clima_forzado": Clima.NIEVE})
	_comprobar(bool(nieve.get_meta("precipitacion", false)), "nieve activa lectura de refugio")
	_comprobar(nieve.get_node_or_null("NieveBordeTecho") != null, "nieve se acumula en el borde")
	_comprobar(nieve.get_node_or_null("CharcoExterior") == null, "nieve no reutiliza el charco de lluvia")

	calle.queue_free()
	calle_lluvia.queue_free()
	calle_nieve.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO DesvioRefugio1774: " + nombre)
