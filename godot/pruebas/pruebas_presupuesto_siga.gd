extends SceneTree

var pasadas := 0
var fallos := 0


func _init() -> void:
	var jornada := Jornada.nueva()

	comprobar(
		"la primera lectura nueva se anuncia gratis",
		Jornada.coste_lectura(jornada, "DOC-A"),
		0
	)
	comprobar(
		"consultar el coste no gasta acciones",
		jornada["acciones"],
		Jornada.ACCIONES_POR_DIA
	)
	comprobar("la primera lectura se puede abrir", Jornada.gastar_lectura(jornada, "DOC-A"), true)
	comprobar(
		"la primera lectura gratuita no gasta acciones",
		jornada["acciones"],
		Jornada.ACCIONES_POR_DIA
	)

	Jornada.anotar_lectura(jornada, "DOC-A")
	comprobar(
		"la siguiente lectura nueva anuncia una accion",
		Jornada.coste_lectura(jornada, "DOC-B"),
		1
	)
	comprobar("la segunda lectura se puede abrir", Jornada.gastar_lectura(jornada, "DOC-B"), true)
	comprobar(
		"la segunda lectura consume una accion",
		jornada["acciones"],
		Jornada.ACCIONES_POR_DIA - 1
	)

	Jornada.anotar_lectura(jornada, "DOC-B")
	comprobar("releer hoy se anuncia gratis", Jornada.coste_lectura(jornada, "DOC-B"), 0)
	comprobar("releer hoy se puede abrir", Jornada.gastar_lectura(jornada, "DOC-B"), true)
	comprobar(
		"releer hoy no vuelve a gastar",
		jornada["acciones"],
		Jornada.ACCIONES_POR_DIA - 1
	)

	jornada["acciones"] = 0
	comprobar(
		"una lectura nueva sigue anunciando su coste sin presupuesto",
		Jornada.coste_lectura(jornada, "DOC-C"),
		1
	)
	comprobar(
		"sin presupuesto una lectura de pago se deniega",
		Jornada.gastar_lectura(jornada, "DOC-C"),
		false
	)

	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s\n  esperado: %s\n  obtenido: %s" % [nombre, esperado, obtenido])
