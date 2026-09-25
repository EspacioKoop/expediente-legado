extends SceneTree

var fallos := 0


func _init() -> void:
	_probar_partida_nueva_y_reasignacion()
	_probar_epilogo_sin_bloquear_final()
	_probar_pluralidad_y_orden()
	_probar_dos_trayectorias_distintas()
	print("pruebas literatura trayectoria #1184: %d fallos" % fallos)
	quit(1 if fallos > 0 else 0)


func _evento(id: String, canal: String, obra: String, fuente: String, jornada: int = 1) -> Dictionary:
	return LiteraturaEventos.crear_evento(
		id,
		canal,
		obra,
		fuente,
		"prueba:1184",
		jornada,
	)


func _probar_partida_nueva_y_reasignacion() -> void:
	var estado := Partida.nueva()
	var registro := LiteraturaEventos.asegurar_en_estado(estado)
	_comprobar(registro == LiteraturaEventos.nuevo(), "partida nueva empieza sin trayectoria literaria")
	LiteraturaEventos.registrar(
		registro,
		_evento(
			"conocimiento:obra:a",
			LiteraturaEventos.CANAL_CONOCIMIENTO,
			"obra_a",
			"documento:biblioteca",
		),
	)
	var antes := JSON.stringify(registro)
	Prometeo.reiniciar_vuelta(estado, Partida.VIDA_MAXIMA)
	_comprobar(
		JSON.stringify(estado[LiteraturaEventos.CLAVE_ESTADO]) == antes,
		"reasignar no borra hechos literarios",
	)


func _probar_epilogo_sin_bloquear_final() -> void:
	var registro := LiteraturaEventos.nuevo()
	var vacio := LiteraturaTrayectoria.derivar_epilogo("final_base_x", registro)
	_comprobar(vacio["final_base"] == "final_base_x", "sin literatura se conserva el final base")
	_comprobar(vacio["literatura"]["estado"] == "ausente", "ausencia es un estado valido")
	_comprobar(not vacio["bloquea_final_base"], "literatura nunca bloquea el final base")
	LiteraturaEventos.registrar(
		registro,
		_evento(
			"insight:dialogo:a",
			LiteraturaEventos.CANAL_INSIGHT,
			"obra_a",
			"npc:archivo:mediadora",
		),
	)
	var con_traza := LiteraturaTrayectoria.derivar_epilogo("final_base_x", registro)
	var proc: Dictionary = con_traza["literatura"]["obras"][0]["procedencias"][0]
	_comprobar(proc["fuente"] == "npc:archivo:mediadora", "epilogo cita procedencia interna")


func _probar_pluralidad_y_orden() -> void:
	var a := LiteraturaEventos.nuevo()
	var b := LiteraturaEventos.nuevo()
	var e1 := _evento(
		"conocimiento:obra:a",
		LiteraturaEventos.CANAL_CONOCIMIENTO,
		"obra_a",
		"documento:a",
	)
	var e2 := _evento(
		"ritual:obra:b",
		LiteraturaEventos.CANAL_RITUAL,
		"obra_b",
		"mesa:cita",
	)
	LiteraturaEventos.registrar(a, e1)
	LiteraturaEventos.registrar(a, e2)
	LiteraturaEventos.registrar(b, e2)
	LiteraturaEventos.registrar(b, e1)
	var ra := LiteraturaTrayectoria.resumir(a)
	var rb := LiteraturaTrayectoria.resumir(b)
	_comprobar(ra == rb, "el orden del array no decide una identidad")
	_comprobar(ra["estado"] == "plural", "pluralidad queda representada sin ganador")


func _probar_dos_trayectorias_distintas() -> void:
	var lectura := LiteraturaEventos.nuevo()
	LiteraturaEventos.registrar(
		lectura,
		_evento(
			"conocimiento:obra:a",
			LiteraturaEventos.CANAL_CONOCIMIENTO,
			"obra_a",
			"documento:a",
		),
	)
	var ritual := lectura.duplicate(true)
	LiteraturaEventos.registrar(
		ritual,
		_evento(
			"ritual:obra:a",
			LiteraturaEventos.CANAL_RITUAL,
			"obra_a",
			"mesa:cita",
		),
	)
	var a := LiteraturaTrayectoria.derivar_epilogo("mismo_final", lectura)
	var b := LiteraturaTrayectoria.derivar_epilogo("mismo_final", ritual)
	_comprobar(a["final_base"] == b["final_base"], "las variaciones no cambian el final base")
	_comprobar(a["literatura"] != b["literatura"], "dos trayectorias producen variaciones distintas")


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)
