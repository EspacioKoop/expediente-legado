## Suite del primer corte del port a Godot. Se ejecuta sin abrir el editor:
##
##     godot4 --headless --path godot --script pruebas/pruebas.gd
##
## Los casos vienen de las pruebas JUnit del backend Java (WikiLinkServiceTest,
## HotspotServiceTest, CartaOcultaServiceTest, ProgresoServiceTest), portadas
## una a una: si el port cambia una decisión del original, la prueba lo dice.
extends SceneTree

var fallos := 0
var pasadas := 0


func _init() -> void:
	_marcas_hotspot()
	_marcas_cartas()
	_marcas_referencias()
	_marcas_solapamiento()
	_bbcode()
	_progreso()
	_contenido()

	var comprobar_cb := Callable(self, "comprobar")

	PruebasPrometeoYCombate._prometeo(comprobar_cb)
	PruebasPrometeoYCombate._partida(comprobar_cb)
	_partida_validacion(comprobar_cb)
	PruebasPrometeoYCombate._guardado_seguro(comprobar_cb)
	PruebasPrometeoYCombate._borrar_el_avance(comprobar_cb)
	PruebasPrometeoYCombate._historias(comprobar_cb)
	PruebasPrometeoYCombate._combate(comprobar_cb)
	PruebasPrometeoYCombate._ventanilla(comprobar_cb)
	PruebasPrometeoYCombate._jornada(comprobar_cb)
	PruebasJungian.todo(comprobar_cb, root)
	PruebasJuicioReglas.todo(comprobar_cb)
	PruebasJuicioRival.todo(comprobar_cb)
	PruebasJuicioDoctrina.todo(comprobar_cb)
	PruebasJuicioJugador.todo(comprobar_cb)
	PruebasJuicioHud.todo(comprobar_cb)
	PruebasJuicioFeedback.todo(comprobar_cb)
	PruebasJuicioEscenografia.todo(comprobar_cb)
	PruebasJuicioJungiano.todo(comprobar_cb)
	PruebasJuicioSimbolico.todo(comprobar_cb)
	PruebasAlquiler.todo(comprobar_cb)
	PruebasImprevistos.todo(comprobar_cb)
	PruebasPrometeoYCombate._procedencia(comprobar_cb)

	PruebasEspaciosYSueno._espacios(comprobar_cb)
	PruebasEspaciosYSueno._acciones_y_vuelta(comprobar_cb)
	PruebasEspaciosYSueno._acusacion(comprobar_cb)
	PruebasEspaciosYSueno._careo(comprobar_cb)
	PruebasCinematicasYMando._cinematicas(comprobar_cb)
	PruebasCinematicasYMando._mando(comprobar_cb)
	PruebasEspaciosYSueno._plantas(comprobar_cb)
	PruebasEspaciosYSueno._sueno(comprobar_cb)
	PruebasEspaciosYSueno._traducciones(comprobar_cb)
	PruebasEspaciosYSueno._sueno_contenido(comprobar_cb)
	load("res://pruebas/pruebas_debug_draw_116.gd").todo(comprobar_cb)
	load("res://pruebas/pruebas_animacion_ambiental.gd").todo(comprobar_cb)
	_noche_degradada(comprobar_cb)

	PruebasSuenoFinal._compilan(comprobar_cb)
	PruebasSuenoFinal._salida_del_sueno(comprobar_cb)
	PruebasSuenoFinal._jornada_antigua(comprobar_cb)
	PruebasSuenoFinal._companeros(comprobar_cb)
	PruebasSuenoFinal._sonido(comprobar_cb)
	PruebasSuenoFinal._sueno_combate(comprobar_cb)

	PruebasGato._gato(comprobar_cb)
	PruebasGato._cuenco(comprobar_cb)
	PruebasGato._comida_propia(comprobar_cb)
	PruebasGato._malla(comprobar_cb)

	PruebasSemilla._semilla(comprobar_cb)
	load("res://pruebas/pruebas_seleccion_nocturna.gd").todo(comprobar_cb)
	PruebasHistoria.catalogo(comprobar_cb)
	_archivado(comprobar_cb)

	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


## La política se prueba sobre la capa real, sin montar la interfaz.
func _noche_degradada(comprobar_cb: Callable) -> void:
	var dia = load("res://guion/dia_alquiler_app.gd").new()
	dia.partida.estado = Partida.nueva()
	dia.partida.estado["semilla"] = 86
	dia.jornada = dia.partida.estado["jornada"]
	dia.jornada["raiz"] = 86
	dia.jornada["fase"] = "casa"
	dia.jornada["alquiler"]["impagos"] = 1
	dia.jornada["leido_hoy"] = ["folio-prueba"]
	dia.contenido.casos = [
		{
			"id": "caso-prueba",
			"registros": [{"id": "registro-prueba", "folio": "folio-prueba"}],
			"pistas":
			[
				{"id": "p1", "registroOrigen": "registro-prueba", "fraseGatillo": "uno"},
				{"id": "p2", "registroOrigen": "registro-prueba", "fraseGatillo": "dos"},
				{"id": "p3", "registroOrigen": "registro-prueba", "fraseGatillo": "tres"}
			]
		}
	]
	dia.partida.estado["pistas_descubiertas"] = ["p1", "p2", "p3"]
	Jornada.dormir(dia.jornada)
	dia._aplicar_politica_sueno()
	comprobar_cb.call("sin casa hay una sala", dia.jornada["sueno_escenas"].size(), 1)
	var espacio: Dictionary = dia._espacio_de("sueño")
	comprobar_cb.call("el respaldo no amplía el mapa", dia.jornada["mapa"], [])
	comprobar_cb.call("una sala recibe todas las frases", espacio["carteles"].size(), 3)
	var escenas: Array = dia.jornada["sueno_escenas"].duplicate()
	dia.partida.estado = JSON.parse_string(JSON.stringify(dia.partida.estado))
	dia.jornada = dia.partida.estado["jornada"]
	var recargado: Dictionary = dia._espacio_de("sueño")
	comprobar_cb.call("recargar conserva el contenido", recargado, espacio)
	comprobar_cb.call("recargar conserva el mapa vacío", dia.jornada["mapa"], [])
	dia.jornada["mapa"] = escenas.duplicate()
	dia._aplicar_politica_sueno()
	dia._espacio_de("sueño")
	comprobar_cb.call(
		"el sueño degradado repite lo conocido", dia.jornada["sueno_escenas"], escenas
	)
	comprobar_cb.call("el mapa conocido no crece", dia.jornada["mapa"], escenas)
	dia.jornada["alquiler"]["impagos"] = 0
	dia.jornada["mapa"] = []
	dia.jornada["fase"] = "casa"
	Jornada.dormir(dia.jornada)
	dia._aplicar_politica_sueno()
	comprobar_cb.call(
		"con vivienda siguen siendo tres salas", dia.jornada["sueno_escenas"].size(), 3
	)
	var frases := 0
	for i in 3:
		var sala: Dictionary = dia._espacio_de("sueño")
		frases += sala["carteles"].size()
		dia.jornada["sueno_escenas"].pop_front()
	comprobar_cb.call("la noche normal reparte todas las frases", frases, 3)
	comprobar_cb.call("la noche normal amplía el mapa", dia.jornada["mapa"].size(), 3)
	dia.free()


## Validación de partidas (#190) ----------------------------------------------


func _partida_validacion(comprobar: Callable) -> void:
	var valida := Partida.nueva()
	comprobar.call("partida nueva válida", Partida.validar(valida), [])

	var antigua := {"jornada": Jornada.nueva()}
	comprobar.call("partida antigua migrable", Partida.validar(antigua), [])

	var jornada_nula := valida.duplicate(true)
	jornada_nula["jornada"] = null
	comprobar.call("jornada nula se rechaza", Partida.validar(jornada_nula).is_empty(), false)

	var gato_incompleto := valida.duplicate(true)
	gato_incompleto["jornada"]["gato"] = []
	comprobar.call(
		"gato con tipo incorrecto se rechaza", Partida.validar(gato_incompleto).is_empty(), false
	)

	var lista_como_objeto := valida.duplicate(true)
	lista_como_objeto["jornada"]["leido_hoy"] = {}
	comprobar.call(
		"lista sustituida por objeto se rechaza",
		Partida.validar(lista_como_objeto).is_empty(),
		false
	)

	var contador_invalido := valida.duplicate(true)
	contador_invalido["vida"] = "tres"
	comprobar.call(
		"contador con tipo inválido se rechaza",
		Partida.validar(contador_invalido).is_empty(),
		false
	)

	var contador_fuera_de_rango := valida.duplicate(true)
	contador_fuera_de_rango["vida"] = Partida.VIDA_MAXIMA + 1
	comprobar.call(
		"contador fuera de rango se rechaza",
		Partida.validar(contador_fuera_de_rango).is_empty(),
		false
	)

	var futura := valida.duplicate(true)
	futura["version"] = Partida.VERSION + 1
	comprobar.call("versión futura se rechaza", Partida.validar(futura).is_empty(), false)

	var fase_invalida := valida.duplicate(true)
	fase_invalida["jornada"]["fase"] = "inventada"
	comprobar.call("fase desconocida se rechaza", Partida.validar(fase_invalida).is_empty(), false)


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s\n  esperado: %s\n  obtenido: %s" % [nombre, esperado, obtenido])


# --- HotspotServiceTest -----------------------------------------------------


func _marcas_hotspot() -> void:
	var texto := "El pago se autorizó sin revisión previa por orden directa."

	comprobar(
		"sin frase gatillo: un solo segmento plano",
		Marcas.segmentar(texto, [Marcas.frase(texto, "", "pista", {})]),
		[{"texto": texto, "tipo": "", "meta": {}}]
	)
	comprobar(
		"frase ausente: un solo segmento plano",
		Marcas.segmentar(texto, [Marcas.frase(texto, "no está aquí", "pista", {})]).size(),
		1
	)
	var sin_descubrir := Marcas.segmentar(
		texto, [Marcas.frase(texto, "sin revisión previa", "pista", {"pista": "p1"})]
	)
	comprobar("pista sin descubrir: tres segmentos", sin_descubrir.size(), 3)
	comprobar(
		"pista sin descubrir: el del medio es la frase",
		sin_descubrir[1],
		{"texto": "sin revisión previa", "tipo": "pista", "meta": {"pista": "p1"}}
	)
	var descubierta := Marcas.segmentar(
		texto, [Marcas.frase(texto, "sin revisión previa", "pista_vista", {"pista": "p1"})]
	)
	comprobar("pista descubierta: queda como leída", descubierta[1]["tipo"], "pista_vista")


# --- CartaOcultaServiceTest -------------------------------------------------


func _marcas_cartas() -> void:
	comprobar("folio con carta", CartasOcultas.en_folio("F-1996-00187")["carta"], "la-luna")
	comprobar("folio sin carta", CartasOcultas.en_folio("EMP-0456"), {})
	comprobar("folio nulo", CartasOcultas.en_folio(null), {})
	var fax := "Trazos que no corresponden a ningún alfabeto reconocido."
	var carta := CartasOcultas.en_folio("FAX-1996-077")
	comprobar(
		"carta con tildes se localiza",
		Marcas.frase(fax, carta["frase"], "carta", {}).is_empty(),
		false
	)
	comprobar(
		"carta cuya frase no está en el documento",
		Marcas.frase("Otro contenido.", carta["frase"], "carta", {}),
		{}
	)


# --- WikiLinkServiceTest ----------------------------------------------------


func _marcas_referencias() -> void:
	var texto := "Llegó a [[Empleado #427]] y después al [[Archivo Muerto]]."
	var nombres := Marcas.referencias(texto, []).map(func(h): return h["meta"]["nombre"])
	comprobar("referencias en orden", nombres, ["Empleado #427", "Archivo Muerto"])
	comprobar("texto sin referencias", Marcas.referencias("Sin corchetes.", []), [])
	comprobar("texto vacío", Marcas.referencias("", []), [])
	var con_tilde := "Ver [[Carcosa Servicios Escénicos]]."
	comprobar(
		"referencia con tilde",
		Marcas.referencias(con_tilde, [])[0]["meta"]["nombre"],
		"Carcosa Servicios Escénicos"
	)
	var mezcla := Marcas.referencias(texto, ["Empleado #427"])
	comprobar("concepto desbloqueado", mezcla[0]["tipo"], "concepto")
	comprobar("concepto sin desbloquear", mezcla[1]["tipo"], "concepto_pendiente")
	var segmentos := Marcas.segmentar(texto, Marcas.referencias(texto, ["Empleado #427"]))
	var visible := ""
	for s in segmentos:
		visible += s["texto"]
	comprobar(
		"el texto visible pierde los corchetes",
		visible,
		"Llegó a Empleado #427 y después al Archivo Muerto."
	)


# --- Propio del port: lo que el encadenado de Java no decidía ---------------


func _marcas_solapamiento() -> void:
	var texto := "El sello no corresponde: es de color amarillo, sin duda."
	var hallazgos := [
		Marcas.frase(texto, "es de color amarillo, sin duda", "pista", {"pista": "p1"}),
		Marcas.frase(texto, "es de color amarillo", "carta", {"carta": "la-luna"}),
	]
	var segmentos := Marcas.segmentar(texto, hallazgos)
	comprobar("solapamiento: gana la que empieza antes", segmentos[1]["tipo"], "pista")
	var recompuesto := ""
	for s in segmentos:
		recompuesto += s["texto"]
	comprobar("solapamiento: el texto se conserva entero", recompuesto, texto)


# --- BBCode -----------------------------------------------------------------


func _bbcode() -> void:
	comprobar(
		"texto plano pasa tal cual",
		BBCode.render([{"texto": "Sin marcas.", "tipo": "", "meta": {}}]),
		"Sin marcas."
	)
	comprobar(
		"un corchete del texto se escapa",
		BBCode.render([{"texto": "Anexo [sic] al margen", "tipo": "", "meta": {}}]),
		"Anexo [lb]sic] al margen"
	)
	comprobar(
		"una pista es pulsable",
		BBCode.render([{"texto": "sin revisión previa", "tipo": "pista", "meta": {"pista": "p1"}}]),
		"[url=pista:p1][color=#0000aa][u]sin revisión previa[/u][/color][/url]"
	)
	comprobar(
		"un concepto pendiente no lleva a ninguna parte",
		BBCode.render([{"texto": "Archivo Muerto", "tipo": "concepto_pendiente", "meta": {}}]),
		"[color=#808080]Archivo Muerto[/color]"
	)


# --- ProgresoServiceTest ----------------------------------------------------


func _progreso() -> void:
	var caso_a := {"id": "a", "pistas": [{"id": "p1"}, {"id": "p2"}]}
	var caso_b := {"id": "b", "pistas": [{"id": "p3"}]}
	var sin_pistas := {"id": "c", "pistas": []}
	comprobar("caso a medias no está resuelto", Progreso.caso_resuelto(caso_a, ["p1"]), false)
	comprobar("caso completo está resuelto", Progreso.caso_resuelto(caso_a, ["p1", "p2"]), true)
	comprobar(
		"un caso sin pistas nunca está resuelto", Progreso.caso_resuelto(sin_pistas, []), false
	)
	comprobar("lista vacía de casos no es victoria", Progreso.todos_resueltos([], []), false)
	comprobar(
		"todos resueltos", Progreso.todos_resueltos([caso_a, caso_b], ["p1", "p2", "p3"]), true
	)
	comprobar("uno sin resolver", Progreso.todos_resueltos([caso_a, caso_b], ["p1", "p2"]), false)
	var resumen := Progreso.de_casos([caso_a, caso_b], ["p1", "p3"])
	comprobar(
		"resumen del primer caso",
		[resumen[0]["total"], resumen[0]["encontradas"], resumen[0]["resuelto"]],
		[2, 1, false]
	)
	comprobar(
		"resumen del segundo caso",
		[resumen[1]["total"], resumen[1]["encontradas"], resumen[1]["resuelto"]],
		[1, 1, true]
	)

	# #1029: completar la investigación de un expediente concede Los Enamorados
	# desde el evento real de la última pista, nunca desde carga o UI.
	var estado_tarot := Partida.nueva()
	var caso_tarot := {"id": "tarot", "pistas": [{"id": "tp1"}, {"id": "tp2"}]}
	estado_tarot["pistas_descubiertas"] = ["tp1"]
	var tarot_parcial := Prometeo.sincronizar_tarot_por_caso_resuelto(estado_tarot, caso_tarot)
	comprobar("caso incompleto no concede Enamorados", tarot_parcial, [])

	estado_tarot["pistas_descubiertas"].append("tp2")
	var tarot_completo := Prometeo.sincronizar_tarot_por_caso_resuelto(estado_tarot, caso_tarot)
	comprobar("última pista concede Enamorados", tarot_completo, ["los-enamorados"])
	var es_enamorados := func(carta): return carta.get("id", "") == "los-enamorados"
	var enamorados: Dictionary = estado_tarot["tarot"].filter(es_enamorados)[0]
	comprobar("Enamorados queda recogida", enamorados.get("recogida", false), true)
	comprobar(
		"Enamorados entra en memoria fantasma",
		estado_tarot.get("cartas_conocidas", []).has("los-enamorados"),
		true
	)

	var tarot_repetido := Prometeo.sincronizar_tarot_por_caso_resuelto(estado_tarot, caso_tarot)
	comprobar("resolver otra vez no reemite Enamorados", tarot_repetido, [])
	var estado_recargado: Dictionary = JSON.parse_string(JSON.stringify(estado_tarot))
	var tarot_recargado := Prometeo.sincronizar_tarot_por_caso_resuelto(
		estado_recargado, caso_tarot
	)
	comprobar("estado ya adquirido sigue siendo idempotente", tarot_recargado, [])

	# #46/#1029: El Mundo exige el resto válido intacto y el archivo principal
	# completo; La Templanza queda fuera porque solo existe tras gastar una carta.
	var casos_mundo := [
		{"id": "mundo-a", "pistas": [{"id": "m1"}]},
		{"id": "mundo-b", "pistas": [{"id": "m2"}]},
	]
	var estado_mundo := Partida.nueva()
	estado_mundo["pistas_descubiertas"] = ["m1", "m2"]
	for carta in estado_mundo["tarot"]:
		if carta.get("id", "") not in ["el-mundo", "la-templanza"]:
			carta["recogida"] = true
			carta["gastada"] = false

	var sin_archivo: Dictionary = estado_mundo.duplicate(true)
	sin_archivo["pistas_descubiertas"] = ["m1"]
	comprobar(
		"archivo incompleto no concede Mundo",
		Prometeo.sincronizar_tarot_mundo(sin_archivo, casos_mundo),
		[]
	)

	var con_gastada: Dictionary = estado_mundo.duplicate(true)
	var es_mago := func(carta): return carta.get("id", "") == "el-mago"
	con_gastada["tarot"].filter(es_mago)[0]["gastada"] = true
	comprobar(
		"una carta válida gastada bloquea Mundo",
		Prometeo.sincronizar_tarot_mundo(con_gastada, casos_mundo),
		[]
	)

	var con_faltante: Dictionary = estado_mundo.duplicate(true)
	var es_diablo := func(carta): return carta.get("id", "") == "el-diablo"
	con_faltante["tarot"].filter(es_diablo)[0]["recogida"] = false
	comprobar(
		"una carta válida ausente bloquea Mundo",
		Prometeo.sincronizar_tarot_mundo(con_faltante, casos_mundo),
		[]
	)

	var mundo_nuevo := Prometeo.sincronizar_tarot_mundo(estado_mundo, casos_mundo)
	comprobar("colección perfecta concede Mundo", mundo_nuevo, ["el-mundo"])
	var es_mundo := func(carta): return carta.get("id", "") == "el-mundo"
	var mundo: Dictionary = estado_mundo["tarot"].filter(es_mundo)[0]
	var es_templanza := func(carta): return carta.get("id", "") == "la-templanza"
	var templanza: Dictionary = estado_mundo["tarot"].filter(es_templanza)[0]
	comprobar("Mundo queda recogido", mundo.get("recogida", false), true)
	comprobar("Templanza no es requisito de Mundo", templanza.get("recogida", false), false)
	comprobar(
		"Mundo entra en memoria fantasma",
		estado_mundo.get("cartas_conocidas", []).has("el-mundo"),
		true
	)
	comprobar(
		"Mundo es idempotente", Prometeo.sincronizar_tarot_mundo(estado_mundo, casos_mundo), []
	)


# --- El contenido de verdad -------------------------------------------------


func _contenido() -> void:
	var contenido := Contenido.new()
	comprobar("casos.json carga", contenido.cargar(), true)
	comprobar("diez casos", contenido.casos.size(), 10)
	comprobar("dieciséis conceptos", contenido.conceptos.size(), 16)
	var registros := 0
	var pistas := 0
	var sospechosos := 0
	for c in contenido.casos:
		registros += c["registros"].size()
		pistas += c["pistas"].size()
		sospechosos += c["sospechosos"].size()
	comprobar("cuarenta y cuatro registros", registros, 44)
	comprobar("cuarenta y siete pistas", pistas, 47)
	comprobar("treinta y tres sospechosos", sospechosos, 33)
	comprobar("seis casos principales", contenido.principales().size(), 6)
	var anios_decimales := contenido.casos.filter(
		func(c): return c.get("anioSuceso") != null and typeof(c["anioSuceso"]) != TYPE_INT
	)
	comprobar("los años son enteros", anios_decimales, [])
	var sin_campo := func(campo: String) -> Array:
		return (
			contenido
			. casos
			. filter(
				func(c): return c.get(campo) == null or str(c.get(campo)).strip_edges().is_empty()
			)
			. map(func(c): return c["id"])
		)
	comprobar("ningún caso se queda sin año", sin_campo.call("anioSuceso"), [])
	comprobar("ni sin estado", sin_campo.call("estado"), [])
	comprobar("ni sin título", sin_campo.call("titulo"), [])
	var nombres := contenido.conceptos.map(func(c): return c["nombre"])
	var rotas := []
	for concepto in contenido.conceptos:
		for hallazgo in Marcas.referencias(concepto.get("resumen", ""), nombres):
			if not nombres.has(hallazgo["meta"]["nombre"]):
				rotas.append(hallazgo["meta"]["nombre"])
	comprobar("ninguna referencia del corcho apunta al vacío", rotas, [])
	var perdidas := []
	for folio in CartasOcultas.POR_FOLIO:
		var encontrado := false
		for c in contenido.casos:
			for r in c["registros"]:
				if r["folio"] == folio:
					encontrado = true
					if String(r["contenido"]).find(CartasOcultas.POR_FOLIO[folio]["frase"]) < 0:
						perdidas.append(folio + " (frase ausente)")
		if not encontrado:
			perdidas.append(folio + " (folio inexistente)")
	comprobar("las ocho cartas ocultas son alcanzables", perdidas, [])
	var gatillos_rotos := []
	for c in contenido.casos:
		for p in c["pistas"]:
			if p.get("fraseGatillo") == null:
				continue
			for r in c["registros"]:
				if (
					r["id"] == p["registroOrigen"]
					and String(r["contenido"]).find(p["fraseGatillo"]) < 0
				):
					gatillos_rotos.append(p["id"])
	comprobar("toda frase gatillo está en su documento", gatillos_rotos, [])
	var enlaces_rotos := []
	var ids_pista := {}
	for c in contenido.casos:
		for p in c["pistas"]:
			ids_pista[p["id"]] = true
	for concepto in contenido.conceptos:
		for id in concepto.get("pistas", []):
			if not ids_pista.has(id):
				enlaces_rotos.append(id)
	comprobar("los conceptos citan pistas que existen", enlaces_rotos, [])
	comprobar(
		"y casi todos citan alguna",
		contenido.conceptos.filter(func(c): return not c.get("pistas", []).is_empty()).size(),
		15
	)
	var replicas_mal := []
	for c in contenido.casos:
		for sospechoso in c["sospechosos"]:
			var ataques = sospechoso.get("ataques")
			if ataques == null:
				continue
			if typeof(ataques) != TYPE_ARRAY or ataques.size() != 3:
				replicas_mal.append(sospechoso["nombre"])
	comprobar("los cuatro rivales tienen sus tres réplicas sueltas", replicas_mal, [])
	var memo := {}
	for r in contenido.casos[0]["registros"]:
		if r["folio"] == "MEMO-1999-088":
			memo = r
	var pistas_memo := contenido.pistas_de_registro(contenido.casos[0], memo["id"])
	var sin_ver := BBCode.render(Marcas.de_registro(memo, pistas_memo, []))
	comprobar("un memorándum real deja su frase pulsable", sin_ver.contains("[url=pista:"), true)
	var ya_visto := BBCode.render(Marcas.de_registro(memo, pistas_memo, [pistas_memo[0]["id"]]))
	comprobar("y al descubrirla queda marcada como leída", ya_visto.contains("[bgcolor="), true)
	comprobar(
		"el texto del documento no cambia al descubrirla",
		_sin_etiquetas(sin_ver),
		_sin_etiquetas(ya_visto)
	)


## Archivado manual (#169) ---------------------------------------------------


func _archivado(comprobar: Callable) -> void:
	var caso := {
		"id": "archivo-prueba",
		"anioSuceso": 1999,
		"estado": "ABIERTO",
		"confidencial": false,
		"registros": [{"folio": "F-1999-001"}],
	}
	var destino := Archivado.destino_de(caso)
	comprobar.call("archivado: destino deriva metadatos", destino, "1990-ABIERTO-GENERAL")
	comprobar.call("archivado: folio no leído bloquea", Archivado.es_clasificable(caso, []), false)
	comprobar.call(
		"archivado: folio leído habilita", Archivado.es_clasificable(caso, ["F-1999-001"]), true
	)
	var acierto := Archivado.evaluar(
		[{"caso": caso, "destino": destino, "folios_leidos": ["F-1999-001"]}]
	)
	comprobar.call("archivado: colocación correcta acierta", acierto["aciertos"], 1)
	comprobar.call("archivado: bandeja perfecta tiene rango propio", acierto["rango"], "perfecta")
	var error := Archivado.evaluar(
		[{"caso": caso, "destino": "1980-CERRADO-GENERAL", "folios_leidos": ["F-1999-001"]}]
	)
	comprobar.call("archivado: colocación incorrecta falla", error["errores"], 1)
	comprobar.call("archivado: error no desaparece", error["evaluadas"], 1)
	comprobar.call("archivado: error cambia rango", error["rango"] == "perfecta", false)
	var parcial := (
		Archivado
		. evaluar(
			[
				{"caso": caso, "destino": destino, "folios_leidos": ["F-1999-001"]},
				{"caso": caso, "destino": destino, "folios_leidos": []},
			]
		)
	)
	comprobar.call("archivado: abandono parcial devuelve pendientes", parcial["pendientes"], 1)
	comprobar.call("archivado: abandono parcial conserva evaluadas", parcial["evaluadas"], 1)


## El texto visible, sin el marcado: lo que el jugador lee.
func _sin_etiquetas(bbcode: String) -> String:
	var expresion := RegEx.new()
	expresion.compile("\\[[^\\]]*\\]")
	return expresion.sub(bbcode, "", true)
