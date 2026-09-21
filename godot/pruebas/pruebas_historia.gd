## La carta debe desembocar en una ventana real, incluso si se salta el vídeo.
class_name PruebasHistoria
extends RefCounted

const ESCENA := preload("res://escenas/historia.tscn")
const HISTORIA_CONTEXTO := preload("res://guion/historia_contexto.gd")


static func catalogo(comprobar: Callable) -> void:
	var historias := Historias.new()
	comprobar.call("la pantalla dispone del catálogo", historias.cargar(), true)
	for carta in historias.catalogo:
		var estado := Partida.nueva()
		var pendiente := historias.vista(estado, carta)
		comprobar.call("cada historia ofrece cuatro opciones", pendiente["opciones"].size(), 4)
		for opcion in pendiente["opciones"]:
			comprobar.call("cada opción tiene texto", opcion["texto"].is_empty(), false)

	_contrato_ideologico(comprobar)
	_contexto_narrativo(comprobar)
	_historial_acumulativo(comprobar)


static func _historial_acumulativo(comprobar: Callable) -> void:
	var historias := Historias.new()
	comprobar.call("el historial carga el catálogo", historias.cargar(), true)
	var estado := Partida.nueva()
	estado["jornada"]["dia"] = 4
	estado["jornada"]["vuelta"] = 2
	estado["jornada"]["fase"] = "archivo"

	comprobar.call(
		"el primer aplazamiento se registra", historias.postergar(estado, "la-justicia"), true
	)
	comprobar.call(
		"un segundo aplazamiento de la misma decisión también cuenta",
		historias.postergar(estado, "la-justicia"),
		true
	)
	comprobar.call(
		"el contador conserva dos aplazamientos",
		historias.veces_pospuesta(estado, "la-justicia"),
		2
	)
	var presion := historias.presion_indecision(estado)
	comprobar.call("dos aplazamientos activan reiteración", presion["nivel"], 1)
	comprobar.call("la presión no resuelve la historia", historias.pendientes(estado), 8)

	historias.resolver(estado, "la-justicia", "centrista")
	var diario := historias.historial(estado)
	comprobar.call("el diario conserva los tres eventos", diario.size(), 3)
	comprobar.call("el último evento es la decisión", diario[-1]["tipo"], "resuelta")
	comprobar.call("el diario conserva el día", diario[-1]["dia"], 4)
	comprobar.call("el diario conserva la vuelta", diario[-1]["vuelta"], 2)
	comprobar.call("resolver limpia la marca pendiente", historias.esta_pospuesta(estado, "la-justicia"), false)


static func _contexto_narrativo(comprobar: Callable) -> void:
	var por_cierre := Partida.nueva()
	por_cierre["jornada"]["dia"] = 3
	por_cierre["jornada"]["fase"] = "archivo"
	por_cierre["jornada"]["leidos_total"] = ["folio-previo"]
	por_cierre["pistas_descubiertas"] = ["pista-previa"]
	por_cierre["veredictos"] = {"caso-previo": "sospechoso"}
	HISTORIA_CONTEXTO.registrar(por_cierre, "la-justicia")
	comprobar.call(
		"sin hechos posteriores la decisión sigue inmadura",
		HISTORIA_CONTEXTO.maduro(por_cierre, "la-justicia"),
		false
	)
	por_cierre["veredictos"]["caso-nuevo"] = "otro-sospechoso"
	comprobar.call(
		"cerrar otro expediente recontextualiza la decisión",
		HISTORIA_CONTEXTO.maduro(por_cierre, "la-justicia"),
		true
	)

	var por_fase := Partida.nueva()
	por_fase["jornada"]["dia"] = 4
	por_fase["jornada"]["fase"] = "archivo"
	HISTORIA_CONTEXTO.registrar(por_fase, "el-carro")
	por_fase["jornada"]["fase"] = "trayecto"
	comprobar.call(
		"fichar y dejar el archivo recontextualiza la decisión",
		HISTORIA_CONTEXTO.maduro(por_fase, "el-carro"),
		true
	)

	var por_dia := Partida.nueva()
	por_dia["jornada"]["dia"] = 5
	por_dia["jornada"]["fase"] = "archivo"
	HISTORIA_CONTEXTO.registrar(por_dia, "la-luna")
	por_dia["jornada"]["dia"] = 6
	comprobar.call(
		"un día nuevo recontextualiza la decisión",
		HISTORIA_CONTEXTO.maduro(por_dia, "la-luna"),
		true
	)

	var legado := Partida.nueva()
	legado[HISTORIA_CONTEXTO.CLAVE] = {"la-estrella": {"leidos": [], "pistas": []}}
	legado["veredictos"] = {"caso-viejo": "sospechoso"}
	legado["jornada"]["dia"] = 9
	legado["jornada"]["fase"] = "trayecto"
	comprobar.call(
		"un snapshot antiguo no madura por dimensiones que no registró",
		HISTORIA_CONTEXTO.maduro(legado, "la-estrella"),
		false
	)


static func _contrato_ideologico(comprobar: Callable) -> void:
	var estado := Partida.nueva()
	estado["historias_cartas"] = {"la-luna": "centrista"}

	comprobar.call(
		"una decisión nueva entra en la huella",
		Prometeo.registrar_eleccion_ideologica(
			estado,
			"expediente:caso9:resolucion",
			"expediente",
			"neoliberal",
			"caso9",
			1,
			["riesgo", "laboral", "riesgo"]
		),
		true
	)
	comprobar.call(
		"repetir el mismo evento no duplica la decisión",
		Prometeo.registrar_eleccion_ideologica(
			estado, "expediente:caso9:resolucion", "expediente", "comunismo"
		),
		false
	)
	comprobar.call(
		"el prefijo de Tarot está reservado a historias_cartas",
		Prometeo.registrar_eleccion_ideologica(estado, "tarot:la-luna", "expediente", "comunismo"),
		false
	)

	comprobar.call(
		"leer un medio registra exposición",
		Prometeo.registrar_exposicion_ideologica(
			estado, "prensa:diario-a:1", "prensa", "comunismo", 1, ["laboral"]
		),
		true
	)
	comprobar.call(
		"un NPC puede registrar su lectura sin votar por el jugador",
		Prometeo.registrar_lectura_social(
			estado, "cunado", "expediente:caso9:resolucion", "desacuerdo", ["oficina"]
		),
		true
	)

	var elecciones := Prometeo.elecciones_ideologicas(estado)
	comprobar.call("Tarot y decisiones nuevas comparten una vista", elecciones.size(), 2)
	comprobar.call(
		"las etiquetas de una decisión se normalizan",
		elecciones[1]["etiquetas"],
		["laboral", "riesgo"]
	)
	comprobar.call(
		"exposición y lectura social no cuentan como elecciones",
		Prometeo.conteo_elecciones_ideologicas(estado),
		{"comunismo": 0, "socialdemocrata": 0, "centrista": 1, "neoliberal": 1}
	)
	comprobar.call(
		"un empate transversal conserva la pluralidad",
		Prometeo.ejes_dominantes(estado),
		["centrista", "neoliberal"]
	)

	Prometeo.reiniciar_exposicion_ideologica_diaria(estado)
	comprobar.call(
		"cambiar de día limpia solo la exposición",
		[
			estado[Prometeo.CLAVE_EXPOSICION_IDEOLOGICA],
			Prometeo.elecciones_ideologicas(estado).size(),
			estado[Prometeo.CLAVE_LECTURAS_SOCIALES].size()
		],
		[[], 2, 1]
	)

	Prometeo.reiniciar_vuelta(estado, Partida.VIDA_MAXIMA)
	comprobar.call(
		"una nueva vuelta limpia las tres capas ideológicas activas",
		[
			estado[Prometeo.CLAVE_ELECCIONES_IDEOLOGICAS],
			estado[Prometeo.CLAVE_EXPOSICION_IDEOLOGICA],
			estado[Prometeo.CLAVE_LECTURAS_SOCIALES],
			estado["historias_cartas"]
		],
		[[], [], [], {}]
	)


static func recorrer(arbol: SceneTree, comprobar: Callable) -> void:
	var visor = load("res://escenas/visor.tscn").instantiate()
	arbol.root.add_child(visor)
	visor.partida.estado = Partida.nueva()
	await arbol.process_frame
	for saltada in [false, true]:
		var carta := "la-justicia" if not saltada else "el-carro"
		visor._al_encontrar_carta(carta)
		var reproductor = visor.get_child(visor.get_child_count() - 1)
		if saltada:
			reproductor.saltar()
		else:
			while reproductor._reproduciendo:
				reproductor._process(100.0)
		await arbol.process_frame
		var pantalla = visor.get_child(visor.get_child_count() - 1)
		comprobar.call("terminar o saltar abre la historia", pantalla is Window, true)
		comprobar.call("la historia corresponde a la carta", pantalla.carta_id, carta)
		comprobar.call("pendiente muestra cuatro opciones", pantalla._opciones.get_child_count(), 4)
		comprobar.call("el relato no está vacío", pantalla._texto.text.is_empty(), false)
		comprobar.call(
			"sin contexto la primera opción se oculta",
			pantalla._opciones.get_child(0).visible,
			false
		)
		comprobar.call("sin contexto el foco va a posponer", pantalla._posponer.has_focus(), true)

		# Una pista nueva posterior a la instantánea madura la decisión. A partir
		# de aquí se conserva la regresión histórica de teclado y mando.
		var pistas: Array = pantalla.partida.estado.get("pistas_descubiertas", []).duplicate()
		pistas.append("contexto-prueba-%s" % carta)
		pantalla.partida.estado["pistas_descubiertas"] = pistas
		pantalla._mostrar()
		await arbol.process_frame
		comprobar.call(
			"contexto nuevo vuelve a mostrar las opciones",
			pantalla._opciones.get_child(0).visible,
			true
		)
		comprobar.call(
			"el foco empieza en las opciones", pantalla._opciones.get_child(0).has_focus(), true
		)
		var boton: Button = pantalla._opciones.get_child(0)
		comprobar.call(
			"el mando puede pasar a la segunda opción",
			boton.get_node(boton.focus_neighbor_bottom),
			pantalla._opciones.get_child(1)
		)
		var tecla := InputEventKey.new()
		tecla.keycode = KEY_DOWN
		tecla.pressed = true
		pantalla.push_input(tecla)
		await arbol.process_frame
		comprobar.call(
			"flecha abajo mueve el foco", pantalla._opciones.get_child(1).has_focus(), true
		)
		tecla.pressed = false
		pantalla.push_input(tecla)
		var mando := InputEventJoypadButton.new()
		mando.button_index = JOY_BUTTON_DPAD_UP
		mando.pressed = true
		pantalla.push_input(mando)
		await arbol.process_frame
		comprobar.call("la cruceta vuelve a la primera opción", boton.has_focus(), true)
		mando.pressed = false
		pantalla.push_input(mando)
		if saltada:
			mando.button_index = JOY_BUTTON_A
			mando.pressed = true
			pantalla.push_input(mando)
		else:
			tecla.keycode = KEY_ENTER
			tecla.pressed = true
			pantalla.push_input(tecla)
			await arbol.process_frame
			tecla.pressed = false
			pantalla.push_input(tecla)
		await arbol.process_frame
		comprobar.call("elegir retira las opciones", pantalla._opciones.get_child_count(), 0)
		comprobar.call("elegir muestra la secuela", pantalla._secuela.text.is_empty(), false)
		var releida := Partida.new()
		releida.cargar()
		comprobar.call(
			"la elección sobrevive a recargar",
			releida.estado["historias_cartas"].get(carta),
			"comunismo"
		)
		pantalla._volver.pressed.emit()
		await arbol.process_frame
		visor.partida.estado = releida.estado
		visor._al_encontrar_carta(carta)
		await arbol.process_frame
		pantalla = visor.get_child(visor.get_child_count() - 1)
		comprobar.call("reabrir no vuelve a preguntar", pantalla._opciones.get_child_count(), 0)
		comprobar.call("reabrir mantiene la secuela", pantalla._secuela.text.is_empty(), false)
		mando.button_index = JOY_BUTTON_B
		mando.pressed = true
		pantalla.push_input(mando)
		await arbol.process_frame
		comprobar.call("B cierra la historia", is_instance_valid(pantalla), false)
		comprobar.call("volver devuelve el foco al expediente", visor._lista.has_focus(), true)
	visor.queue_free()
	await arbol.process_frame
	await _fallo_guardado(arbol, comprobar)


static func _fallo_guardado(arbol: SceneTree, comprobar: Callable) -> void:
	var pantalla = ESCENA.instantiate()
	pantalla.partida = Partida.new()
	pantalla.partida.estado = Partida.nueva()
	pantalla.carta_id = "la-justicia"
	# Registrar el contexto inicial sí puede guardarse; el fallo que queremos
	# probar ocurre al confirmar la elección ya madura.
	pantalla.guardar = func(): return true
	arbol.root.add_child(pantalla)
	pantalla.popup_centered_clamped(Vector2i(900, 600), 0.9)
	await arbol.process_frame
	var pistas: Array = pantalla.partida.estado.get("pistas_descubiertas", []).duplicate()
	pistas.append("contexto-prueba-guardado")
	pantalla.partida.estado["pistas_descubiertas"] = pistas
	pantalla._mostrar()
	await arbol.process_frame
	pantalla.guardar = func(): return false
	pantalla._opciones.get_child(1).pressed.emit()
	await arbol.process_frame
	comprobar.call(
		"el fallo de guardado se anuncia",
		pantalla._aviso.text,
		TranslationServer.translate("ARCHIVO_ERROR_GUARDAR")
	)
	comprobar.call("el fallo permite reintentar", pantalla._reintentar.visible, true)
	comprobar.call("no se cierra con una elección sin guardar", pantalla._volver.disabled, true)
	comprobar.call("no se vuelve a votar tras el fallo", pantalla._opciones.get_child_count(), 0)
	pantalla.guardar = Callable()
	pantalla._reintentar.pressed.emit()
	await arbol.process_frame
	comprobar.call("reintentar guarda y permite volver", pantalla._volver.disabled, false)
	var releida := Partida.new()
	releida.cargar()
	comprobar.call(
		"reintentar conserva la primera elección",
		releida.estado["historias_cartas"].get("la-justicia"),
		"centrista"
	)
	pantalla.queue_free()
	await arbol.process_frame
