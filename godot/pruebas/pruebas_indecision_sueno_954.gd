extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var historias := Historias.new()
	_comprobar(historias.cargar(), "#954: carga catálogo de historias")
	if historias.catalogo.is_empty():
		_terminar()
		return

	var cartas: Array = historias.catalogo.keys()
	cartas.sort()
	var carta_id := String(cartas[0])

	var estado := Partida.nueva()
	var jornada: Dictionary = estado["jornada"]
	jornada["dia"] = 4
	jornada["leido_hoy"] = ["folio-a"]

	var formas: Array = SuenoFormas.ids()
	formas.sort()
	_comprobar(formas.size() >= 4, "#954: hay variedad suficiente de salas para probar rumiación")
	if formas.size() < 4:
		_terminar()
		return
	var conocida := String(formas[0])
	jornada["mapa"] = [conocida]

	var opciones_originales: Array = historias.vista(estado, carta_id).get("opciones", []).duplicate(true)
	var dinero_antes := int(jornada["dinero"])
	var acciones_antes := int(jornada["acciones"])
	var pistas_antes: Array = estado.get("pistas_descubiertas", []).duplicate()

	var opciones0 := SeleccionNocturna.opciones_sueno(jornada)
	var noche0 := Sueno.noche(
		jornada["dia"], jornada["leido_hoy"], jornada["mapa"], int(jornada["raiz"]), opciones0
	)
	_comprobar(int(jornada["presion_indecision_onirica"]) == 0, "sin aplazamiento no hay rumiación")
	_comprobar(noche0.size() == Sueno.ESCENAS_POR_NOCHE, "nivel 0 conserva tres escenas")
	_comprobar(String(noche0[0]) != conocida, "nivel 0 mantiene lo nuevo primero")

	_comprobar(historias.postergar(estado, carta_id), "primer aplazamiento se registra")
	_comprobar(
		int(jornada["presion_indecision_onirica"]) == 0,
		"un único aplazamiento todavía no fuerza recurrencia",
	)
	_comprobar(historias.postergar(estado, carta_id), "segundo aplazamiento se registra")
	_comprobar(int(jornada["presion_indecision_onirica"]) == 1, "dos aplazamientos activan rumiación leve")

	var opciones1 := SeleccionNocturna.opciones_sueno(jornada)
	var noche1 := Sueno.noche(
		jornada["dia"], jornada["leido_hoy"], jornada["mapa"], int(jornada["raiz"]), opciones1
	)
	_comprobar(int(opciones1.get("rumiacion_indecision", 0)) == 1, "la selección nocturna recibe nivel 1")
	_comprobar(not opciones1.has("cantidad"), "la indecisión no cambia la cantidad de escenas")
	_comprobar(noche1.size() == Sueno.ESCENAS_POR_NOCHE, "nivel 1 conserva tres escenas")
	_comprobar(String(noche1[0]) != conocida, "nivel 1 conserva una escena nueva primero")
	_comprobar(String(noche1[1]) == conocida, "nivel 1 intercala una sala ya vivida")

	_comprobar(historias.postergar(estado, carta_id), "tercer aplazamiento se registra")
	_comprobar(int(jornada["presion_indecision_onirica"]) == 2, "tres aplazamientos activan rumiación alta")
	var opciones2 := SeleccionNocturna.opciones_sueno(jornada)
	var noche2 := Sueno.noche(
		jornada["dia"], jornada["leido_hoy"], jornada["mapa"], int(jornada["raiz"]), opciones2
	)
	_comprobar(int(opciones2.get("rumiacion_indecision", 0)) == 2, "la selección nocturna recibe nivel 2")
	_comprobar(noche2.size() == Sueno.ESCENAS_POR_NOCHE, "nivel 2 conserva tres escenas")
	_comprobar(String(noche2[0]) == conocida, "nivel 2 abre con una sala ya vivida")
	_comprobar(
		historias.vista(estado, carta_id).get("opciones", []) == opciones_originales,
		"rumiar no cambia las opciones políticas",
	)
	_comprobar(int(jornada["dinero"]) == dinero_antes, "rumiar no cambia dinero")
	_comprobar(int(jornada["acciones"]) == acciones_antes, "rumiar no cambia acciones")
	_comprobar(estado.get("pistas_descubiertas", []) == pistas_antes, "rumiar no fabrica pistas")

	jornada["presion_indecision_onirica"] = 1
	var degradado := SeleccionNocturna.opciones_sueno(jornada, {"priorizar_vistas": true})
	var noche_degradada := Sueno.noche(
		jornada["dia"], jornada["leido_hoy"], jornada["mapa"], int(jornada["raiz"]), degradado
	)
	_comprobar(
		String(noche_degradada[0]) == conocida,
		"una política explícita de priorizar vistas conserva precedencia",
	)

	var recargada: Dictionary = JSON.parse_string(JSON.stringify(jornada))
	Jornada.completar(recargada, int(jornada["raiz"]))
	_comprobar(
		int(recargada["presion_indecision_onirica"]) == 1,
		"guardar y completar conserva la presión de la vida laboral",
	)
	_comprobar(
		int(Jornada.nueva(17)["presion_indecision_onirica"]) == 0,
		"una vida laboral nueva reinicia la presión onírica",
	)
	var reasignada := jornada.duplicate(true)
	reasignada["presion_indecision_onirica"] = 2
	Jornada.reiniciar_vuelta(reasignada)
	_comprobar(
		int(reasignada["presion_indecision_onirica"]) == 0,
		"reasignar reinicia la rumiación junto con la vida laboral",
	)

	_terminar()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO IndecisionSueno954: " + nombre)


func _terminar() -> void:
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)
