## Regresión standalone del primer corte declarativo de #920.
##
##     godot4 --headless --path godot --script pruebas/issue_920_smoke.gd
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_oficina_y_lectura_social()
	_probar_exposicion_en_careo()
	_probar_minimo_elecciones()
	_probar_condiciones_de_memoria()
	_probar_companeros_con_memoria()
	print("issue_920: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _estado_base() -> Dictionary:
	return {
		"veredictos": {},
		"historias_cartas": {},
		"jornada": {"dia": 2},
		"pistas_descubiertas": ["pista1@1"],
	}


func _probar_oficina_y_lectura_social() -> void:
	var estado := _estado_base()
	estado["veredictos"][DecisionIdeologicaExpediente.CASO_VERTICAL] = "sospechosoIbarra@1"
	(
		DecisionIdeologicaExpediente
		. resolver(
			estado,
			DecisionIdeologicaExpediente.CASO_VERTICAL,
			"responsabilidad_compartida",
		)
	)
	var antes := Prometeo.conteo_elecciones_ideologicas(estado).duplicate(true)
	var variante := (
		DialogoIdeologico
		. resolver(
			DialogoIdeologico.SUPERFICIE_OFICINA_CUNADO,
			estado,
		)
	)
	_comprobar(
		variante.get("clave", ""),
		"IDEOLOGIA_924_CUNADO_COLECTIVO",
		"la conversación de oficina deriva de la decisión observable",
	)
	_comprobar(
		DialogoIdeologico.registrar_respuesta(estado, variante),
		true,
		"la primera reacción registra una lectura social",
	)
	_comprobar(
		DialogoIdeologico.registrar_respuesta(estado, variante),
		false,
		"la misma reacción no se duplica",
	)
	_comprobar(
		Prometeo.conteo_elecciones_ideologicas(estado),
		antes,
		"la reacción del NPC no añade otro voto",
	)


func _probar_exposicion_en_careo() -> void:
	var estado := _estado_base()
	_comprobar(
		(
			DialogoIdeologico
			. resolver(
				DialogoIdeologico.SUPERFICIE_CAREO_EXPOSICION,
				estado,
			)
			. is_empty()
		),
		true,
		"sin exposición no aparece un reconocimiento ideológico",
	)
	(
		Prometeo
		. registrar_exposicion_ideologica(
			estado,
			"prensa:diario-central:turnos",
			"prensa:diario-central",
			"centrista",
			2,
			["procedimiento"],
		)
	)
	var variante := (
		DialogoIdeologico
		. resolver(
			DialogoIdeologico.SUPERFICIE_CAREO_EXPOSICION,
			estado,
		)
	)
	_comprobar(
		variante.get("clave", ""),
		"IDEOLOGIA_920_CAREO_EXP_CENTRISTA",
		"la exposición permite reconocer un marco sin elegirlo",
	)
	_comprobar(
		Prometeo.elecciones_ideologicas(estado).size(),
		0,
		"leer prensa no crea una elección política",
	)

	(
		Prometeo
		. registrar_exposicion_ideologica(
			estado,
			"prensa:gaceta-mercantil:turnos",
			"prensa:gaceta-mercantil",
			"neoliberal",
			2,
			["costes"],
		)
	)
	var ultima := (
		DialogoIdeologico
		. resolver(
			DialogoIdeologico.SUPERFICIE_CAREO_EXPOSICION,
			estado,
		)
	)
	_comprobar(
		ultima.get("clave", ""),
		"IDEOLOGIA_920_CAREO_EXP_NEOLIBERAL",
		"si hay varios marcos se usa la exposición más reciente y no el orden del enum",
	)


func _probar_minimo_elecciones() -> void:
	var estado := _estado_base()
	var condicion := {
		"requiere_eleccion": {"eje": "comunismo", "minimo": 2},
	}
	(
		Prometeo
		. registrar_eleccion_ideologica(
			estado,
			"dialogo:fixture:1",
			"dialogo",
			"comunismo",
			"fixture",
		)
	)
	_comprobar(
		DialogoIdeologico.cumple(estado, condicion),
		false,
		"una sola eleccion no satisface minimo dos",
	)
	(
		Prometeo
		. registrar_exposicion_ideologica(
			estado,
			"prensa:fixture",
			"prensa",
			"comunismo",
		)
	)
	_comprobar(
		DialogoIdeologico.cumple(estado, condicion),
		false,
		"la exposicion no completa un minimo de elecciones",
	)
	(
		Prometeo
		. registrar_eleccion_ideologica(
			estado,
			"dialogo:fixture:2",
			"dialogo",
			"comunismo",
			"fixture",
		)
	)
	_comprobar(
		DialogoIdeologico.cumple(estado, condicion),
		true,
		"dos elecciones del eje satisfacen minimo dos",
	)


func _probar_condiciones_de_memoria() -> void:
	var estado := _estado_base()
	var condicion := {
		"actor_recuerda": {"actor": "cunado", "evento": "expediente:fixture"},
	}
	_comprobar(
		DialogoIdeologico.cumple(estado, condicion),
		false,
		"un actor no recuerda un evento ausente de sus lecturas",
	)
	(
		Prometeo
		. registrar_lectura_social(
			estado,
			"cunado",
			"expediente:fixture",
			"comentario",
			["fixture"],
		)
	)
	_comprobar(
		DialogoIdeologico.cumple(estado, condicion),
		true,
		"actor_recuerda consulta el canal social separado",
	)


func _probar_companeros_con_memoria() -> void:
	var estado := _estado_base()
	estado["veredictos"][DecisionIdeologicaExpediente.CASO_VERTICAL] = "sospechosoIbarra@1"
	(
		DecisionIdeologicaExpediente
		. resolver(
			estado,
			DecisionIdeologicaExpediente.CASO_VERTICAL,
			"responsabilidad_compartida",
		)
	)

	var primera_becario := (
		DialogoIdeologico
		. resolver_companero(
			DecisionIdeologicaExpediente.ACTOR_BECARIO,
			estado,
		)
	)
	_comprobar(
		primera_becario.get("clave", ""),
		"COMPA_BECARIO_2",
		"el becario tiene una primera reacción contextual",
	)
	_comprobar(
		DialogoIdeologico.registrar_respuesta(estado, primera_becario),
		true,
		"la primera charla registra memoria social autorizada",
	)
	var segunda_becario := (
		DialogoIdeologico
		. resolver_companero(
			DecisionIdeologicaExpediente.ACTOR_BECARIO,
			estado,
		)
	)
	_comprobar(
		segunda_becario.get("clave", ""),
		"COMPA_BECARIO_3",
		"la segunda charla avanza a una secuela por memoria",
	)
	_comprobar(
		DialogoIdeologico.registrar_respuesta(estado, segunda_becario),
		false,
		"la secuela no duplica memoria ni elecciones",
	)

	var primera_jubilacion := (
		DialogoIdeologico
		. resolver_companero(
			DecisionIdeologicaExpediente.ACTOR_JUBILACION,
			estado,
		)
	)
	_comprobar(
		primera_jubilacion.get("clave", ""),
		"COMPA_JUBILACION_2",
		"otro compañero tiene una lectura propia del mismo hecho",
	)
	_comprobar(
		DialogoIdeologico.registrar_respuesta(estado, primera_jubilacion),
		true,
		"cada actor conserva su memoria por separado",
	)
	var segunda_jubilacion := (
		DialogoIdeologico
		. resolver_companero(
			DecisionIdeologicaExpediente.ACTOR_JUBILACION,
			estado,
		)
	)
	_comprobar(
		segunda_jubilacion.get("clave", ""),
		"COMPA_JUBILACION_3",
		"la jubilación también progresa a una secuela distinta",
	)

	_comprobar(
		DialogoIdeologico.resolver_companero("telefono", estado).is_empty(),
		true,
		"un actor sin superficie no inventa conocimiento",
	)
	_comprobar(
		(
			DecisionIdeologicaExpediente
			. registrar_lectura_social(
				estado,
				DecisionIdeologicaExpediente.CASO_VERTICAL,
				"telefono",
			)
		),
		false,
		"un actor no autorizado no adquiere la decisión por telepatía",
	)
	_comprobar(
		Prometeo.elecciones_ideologicas(estado).size(),
		1,
		"las conversaciones no añaden nuevas elecciones",
	)
	_comprobar(
		estado["pistas_descubiertas"],
		["pista1@1"],
		"las ramas sociales no alteran pistas",
	)


func _comprobar(actual, esperado, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #920: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
