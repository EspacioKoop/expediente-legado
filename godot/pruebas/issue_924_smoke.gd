## Regresión standalone del primer corte de #924/#920.
##
##     godot4 --headless --path godot --script pruebas/issue_924_smoke.gd
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_disponibilidad()
	_probar_registro()
	_probar_lectura_social()
	_probar_contrato_transversal()
	print("issue_924: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _estado_base() -> Dictionary:
	return {
		"veredictos": {},
		"historias_cartas": {},
		"jornada": {"dia": 4},
		"pistas_descubiertas": ["pista1@1"],
	}


func _cerrar_caso(estado: Dictionary) -> void:
	estado["veredictos"][DecisionIdeologicaExpediente.CASO_VERTICAL] = "sospechosoIbarra@1"


func _probar_disponibilidad() -> void:
	var estado := _estado_base()
	var opciones := DecisionIdeologicaExpediente.opciones(
		DecisionIdeologicaExpediente.CASO_VERTICAL
	)
	_comprobar(opciones.size(), 3, "el primer caso ofrece tres enfoques y no una matriz fija")

	var ejes := []
	for opcion in opciones:
		ejes.append(String(opcion.get("eje", "")))
	_comprobar(ejes.has("comunismo"), true, "el corte puede expresar responsabilidad colectiva")
	_comprobar(
		ejes.has("socialdemocrata"), true, "el corte puede expresar revisión institucional"
	)
	_comprobar(ejes.has("centrista"), true, "el corte puede expresar conciliación")
	_comprobar(ejes.has("neoliberal"), false, "un caso no necesita forzar los cuatro ejes")
	_comprobar(
		DecisionIdeologicaExpediente.disponible(
			estado, DecisionIdeologicaExpediente.CASO_VERTICAL
		),
		false,
		"sin un cierre real no aparece la decisión",
	)

	_cerrar_caso(estado)
	_comprobar(
		DecisionIdeologicaExpediente.disponible(
			estado, DecisionIdeologicaExpediente.CASO_VERTICAL
		),
		true,
		"el veredicto real habilita la consecuencia postcierre",
	)


func _probar_registro() -> void:
	var estado := _estado_base()
	_cerrar_caso(estado)
	var veredictos_antes: Dictionary = estado["veredictos"].duplicate(true)
	var pistas_antes: Array = estado["pistas_descubiertas"].duplicate()

	var invalida := DecisionIdeologicaExpediente.resolver(
		estado, DecisionIdeologicaExpediente.CASO_VERTICAL, "opcion_que_no_existe"
	)
	_comprobar(invalida.get("resultado"), "opcion_invalida", "una opción inventada se rechaza")
	_comprobar(
		Prometeo.elecciones_ideologicas(estado).size(),
		0,
		"una opción inválida no deja huella política",
	)

	var resultado := DecisionIdeologicaExpediente.resolver(
		estado, DecisionIdeologicaExpediente.CASO_VERTICAL, "revision_procedimental"
	)
	_comprobar(resultado.get("resultado"), "registrada", "la decisión válida se registra")
	var evento: Dictionary = resultado.get("evento", {})
	_comprobar(evento.get("id"), DecisionIdeologicaExpediente.EVENTO_VERTICAL, "id estable")
	_comprobar(evento.get("fuente"), "expediente", "la fuente es el expediente")
	_comprobar(evento.get("eje"), "socialdemocrata", "se conserva el eje de la opción")
	_comprobar(evento.get("contexto"), "caso@1", "el contexto conserva el caso")
	_comprobar(
		Array(evento.get("etiquetas", [])).has("opcion:revision_procedimental"),
		true,
		"la opción concreta queda trazable sin otra fuente de verdad",
	)
	_comprobar(estado["veredictos"], veredictos_antes, "la ideología no reescribe el veredicto")
	_comprobar(estado["pistas_descubiertas"], pistas_antes, "la ideología no inventa pistas")

	var repetida := DecisionIdeologicaExpediente.resolver(
		estado, DecisionIdeologicaExpediente.CASO_VERTICAL, "conciliacion_interna"
	)
	_comprobar(repetida.get("resultado"), "ya_resuelta", "la decisión es idempotente")
	_comprobar(
		Prometeo.elecciones_ideologicas(estado).size(),
		1,
		"no se puede votar varias veces en el mismo cierre",
	)


func _probar_lectura_social() -> void:
	var sin_evento := _estado_base()
	_cerrar_caso(sin_evento)
	_comprobar(
		DecisionIdeologicaExpediente.registrar_lectura_social(
			sin_evento, DecisionIdeologicaExpediente.CASO_VERTICAL, "cunado"
		),
		false,
		"nadie reacciona antes de que exista el evento observable",
	)
	_comprobar(
		sin_evento.get(Prometeo.CLAVE_LECTURAS_SOCIALES, []).size(),
		0,
		"la ausencia de evento no crea lectura social",
	)

	var estado := _estado_base()
	_cerrar_caso(estado)
	DecisionIdeologicaExpediente.resolver(
		estado, DecisionIdeologicaExpediente.CASO_VERTICAL, "conciliacion_interna"
	)
	_comprobar(
		DecisionIdeologicaExpediente.reaccion_para(
			estado, DecisionIdeologicaExpediente.CASO_VERTICAL, "jefe"
		),
		"",
		"un actor no autorizado no sabe por telepatía qué se decidió",
	)
	_comprobar(
		DecisionIdeologicaExpediente.registrar_lectura_social(
			estado, DecisionIdeologicaExpediente.CASO_VERTICAL, "jefe"
		),
		false,
		"el actor no observador no deja lectura social",
	)
	_comprobar(
		DecisionIdeologicaExpediente.reaccion_para(
			estado, DecisionIdeologicaExpediente.CASO_VERTICAL, "cunado"
		),
		"cierre_negociado",
		"el observador autorizado recibe una reacción derivada de la opción real",
	)
	_comprobar(
		DecisionIdeologicaExpediente.registrar_lectura_social(
			estado, DecisionIdeologicaExpediente.CASO_VERTICAL, "cunado"
		),
		true,
		"el observador autorizado registra la lectura",
	)
	_comprobar(
		DecisionIdeologicaExpediente.registrar_lectura_social(
			estado, DecisionIdeologicaExpediente.CASO_VERTICAL, "cunado"
		),
		false,
		"la misma lectura social no se duplica",
	)
	_comprobar(
		estado.get(Prometeo.CLAVE_LECTURAS_SOCIALES, []).size(),
		1,
		"la reacción vive en el canal social separado",
	)
	var conteo := Prometeo.conteo_elecciones_ideologicas(estado)
	_comprobar(conteo.get("centrista"), 1, "la elección cuenta una vez")
	var total := 0
	for valor in conteo.values():
		total += int(valor)
	_comprobar(total, 1, "la reacción del NPC no añade un segundo voto")


func _probar_contrato_transversal() -> void:
	var estado := _estado_base()
	estado["historias_cartas"] = {"la-luna": "neoliberal"}
	_cerrar_caso(estado)
	DecisionIdeologicaExpediente.resolver(
		estado, DecisionIdeologicaExpediente.CASO_VERTICAL, "responsabilidad_compartida"
	)

	var elecciones := Prometeo.elecciones_ideologicas(estado)
	_comprobar(elecciones.size(), 2, "Tarot y expediente comparten la misma vista")
	var conteo := Prometeo.conteo_elecciones_ideologicas(estado)
	_comprobar(conteo.get("comunismo"), 1, "el expediente entra en el recuento común")
	_comprobar(conteo.get("neoliberal"), 1, "la historia heredada sigue contando")
	var dominantes := Prometeo.ejes_dominantes(estado)
	_comprobar(dominantes.size(), 2, "la contradicción conserva el empate")
	_comprobar(dominantes.has("comunismo"), true, "el empate conserva comunismo")
	_comprobar(dominantes.has("neoliberal"), true, "el empate conserva neoliberal")


func _comprobar(actual, esperado, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #924: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
