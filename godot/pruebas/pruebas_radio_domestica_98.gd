extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_programacion_narrativa()
	_probar_audio_y_transporte()
	_probar_radio_deliberada()
	_probar_exposicion_ideologica()
	_probar_tir_na_nog_deliberado()
	_probar_cassette_deliberado()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_programacion_narrativa() -> void:
	var radio := MinicadenaDomestica98.new()
	root.add_child(radio)
	radio.configurar({"dia": 1, "acciones": Jornada.ACCIONES_POR_DIA})
	var emisoras := radio.emisoras()
	var audio := radio.get_node_or_null("MusicaPuntual") as AudioStreamPlayer3D
	_comprobar(emisoras.size(), 4, "hay cuatro emisoras declarativas")
	_comprobar(audio != null, "la minicadena monta una salida de audio 3D")
	if audio != null:
		_comprobar(audio.bus, &"Musica", "la salida reutiliza el bus común de música")
		_comprobar(audio.stream is AudioStreamWAV, "la cama audible es procedural y local")
		_comprobar(
			is_equal_approx(audio.unit_size, MinicadenaDomestica98.AUDIO_UNIT_SIZE),
			"la atenuación parte de escala doméstica explícita",
		)
		_comprobar(
			is_equal_approx(audio.max_distance, MinicadenaDomestica98.AUDIO_MAX_DISTANCE),
			"la minicadena deja de mezclarse fuera de la habitación",
		)
		_comprobar(
			is_equal_approx(
				audio.panning_strength, MinicadenaDomestica98.AUDIO_PANNING_STRENGTH
			),
			"el paneo está limitado para una fuente doméstica cercana",
		)
	_comprobar(
		MinicadenaDomestica98.hora_narrativa({"dia": 1, "acciones": Jornada.ACCIONES_POR_DIA}),
		"08:16",
		"la programación parte de la hora narrativa de Jornada",
	)
	_comprobar(
		MinicadenaDomestica98.hora_narrativa({"dia": 1, "acciones": 0}),
		"16:16",
		"consumir acciones avanza la franja sin reloj real",
	)
	var manana := MinicadenaDomestica98.seleccionar_programa(
		emisoras[0], {"dia": 1, "acciones": Jornada.ACCIONES_POR_DIA}
	)
	var tarde := MinicadenaDomestica98.seleccionar_programa(emisoras[0], {"dia": 1, "acciones": 0})
	_comprobar(manana.get("id", ""), "boletin_barrio", "la mañana selecciona su boletín")
	_comprobar(tarde.get("id", ""), "mesa_local", "la tarde selecciona otra programación")
	radio.queue_free()


func _probar_audio_y_transporte() -> void:
	var radio := MinicadenaDomestica98.new()
	root.add_child(radio)
	radio.configurar({"dia": 1, "acciones": Jornada.ACCIONES_POR_DIA})
	var volumen_inicial := radio.volumen_local_db()
	radio.cambiar_volumen()
	_comprobar(
		radio.volumen_local_db() != volumen_inicial,
		"el volumen físico cambia la ganancia local del aparato",
	)
	var audio := radio.get_node_or_null("MusicaPuntual") as AudioStreamPlayer3D
	if audio != null:
		_comprobar(
			audio.volume_db,
			radio.volumen_local_db(),
			"la ganancia local se aplica al reproductor sin tocar preferencias globales",
		)

	radio.alternar_encendido()
	_comprobar(radio.esta_reproduciendo(), "encender inicia reproducción diegética")
	radio.alternar_reproduccion()
	_comprobar(not radio.esta_reproduciendo(), "el transporte puede pausar")
	if audio != null:
		_comprobar(audio.stream_paused, "pausar conserva la posición del stream")
	_comprobar(not radio.escuchar_actual(), "una escucha pausada no cuenta como atención")
	radio.alternar_reproduccion()
	_comprobar(radio.esta_reproduciendo(), "el transporte puede reanudar")
	if audio != null:
		_comprobar(not audio.stream_paused, "reanudar continúa el mismo stream")

	radio.alternar_cassette()
	_comprobar(
		radio.contenido_actual().get("id", ""),
		"cara_a_1",
		"la cinta entra por el primer segmento",
	)
	radio.cambiar_emisora()
	_comprobar(
		radio.contenido_actual().get("id", ""),
		"cara_a_2",
		"el sintonizador actúa como avance de pista cuando hay cassette",
	)
	radio.queue_free()


func _probar_radio_deliberada() -> void:
	var jornada := {"dia": 2, "acciones": 0}
	var radio := MinicadenaDomestica98.new()
	root.add_child(radio)
	radio.configurar(jornada)
	_comprobar(not radio.esta_encendida(), "la minicadena empieza apagada")
	_comprobar(radio.transcripcion_actual(), "", "apagada no expone contenido como si sonara")
	_comprobar(not radio.escuchar_actual(), "apagada no cuenta como escucha")

	radio.alternar_encendido()
	radio.cambiar_emisora()
	radio.cambiar_emisora()
	_comprobar(radio.esta_encendida(), "el aparato se puede encender")
	_comprobar(
		radio.emisora_actual().get("id", ""),
		"frecuencia_cultural",
		"el sintonizador recorre las emisoras",
	)
	_comprobar(
		radio.contenido_actual().get("id", ""),
		"alas_sobre_el_desierto",
		"la franja doméstica selecciona el espacio cultural",
	)
	_comprobar(not radio.escuchar_actual(), "un gesto breve no completa el contenido cultural")
	_comprobar(
		not SemillasOniricas.familias_activas(jornada).has("simurgh"),
		"encender y tocar una vez no activa la semilla",
	)
	_comprobar(radio.escuchar_actual(), "la segunda atención completa el fragmento")
	_comprobar(
		SemillasOniricas.familias_activas(jornada).has("simurgh"),
		"la escucha deliberada usa el contrato común de semillas",
	)
	radio.queue_free()


func _probar_exposicion_ideologica() -> void:
	var radio := MinicadenaDomestica98.new()
	root.add_child(radio)
	var jornada := {"dia": 1, "acciones": 0}
	radio.configurar(jornada)
	var programa := radio.programa_actual(jornada)
	var exposicion: Dictionary = programa.get("exposicion_ideologica", {})
	_comprobar(
		exposicion.get("hecho_id", ""),
		"turnos-atencion-planta4",
		"la radio reutiliza el hecho base que aparece en prensa",
	)
	var estado := {"historias_cartas": {"el-sol": "centrista"}}
	var elecciones_antes := Prometeo.conteo_elecciones_ideologicas(estado)
	_comprobar(
		MinicadenaDomestica98.registrar_exposicion_de_contenido(estado, programa, 1),
		"completar el programa registra exposición mediante Prometeo",
	)
	_comprobar(
		not MinicadenaDomestica98.registrar_exposicion_de_contenido(estado, programa, 1),
		"la misma escucha no duplica el evento de exposición",
	)
	var exposiciones: Array = estado.get(Prometeo.CLAVE_EXPOSICION_IDEOLOGICA, [])
	_comprobar(exposiciones.size(), 1, "la radio escribe únicamente una exposición")
	_comprobar(
		Prometeo.conteo_elecciones_ideologicas(estado),
		elecciones_antes,
		"escuchar radio no modifica las elecciones ideológicas",
	)
	radio.queue_free()


func _probar_tir_na_nog_deliberado() -> void:
	var jornada := {"dia": 4, "acciones": 0}
	var radio := MinicadenaDomestica98.new()
	root.add_child(radio)
	radio.configurar(jornada)
	radio.alternar_encendido()
	for _paso in range(3):
		radio.cambiar_emisora()
	_comprobar(
		radio.emisora_actual().get("id", ""),
		"radio_oeste_98",
		"el sintonizador alcanza la emisora cultural atlántica",
	)
	_comprobar(
		radio.contenido_actual().get("id", ""),
		"islas_fuera_del_tiempo",
		"la franja de tarde expone la pieza que siembra Tír na nÓg",
	)
	_comprobar(not radio.escuchar_actual(), "una escucha breve no activa Tír na nÓg")
	_comprobar(
		not SemillasOniricas.familias_activas(jornada).has("tir_na_nog"),
		"la presencia del programa no activa la familia por sí sola",
	)
	_comprobar(radio.escuchar_actual(), "la segunda atención completa la pieza")
	_comprobar(
		SemillasOniricas.familias_activas(jornada).has("tir_na_nog"),
		"la escucha deliberada activa Tír na nÓg por el contrato común",
	)
	radio.queue_free()


func _probar_cassette_deliberado() -> void:
	var jornada := {"dia": 3, "acciones": 0}
	var radio := MinicadenaDomestica98.new()
	root.add_child(radio)
	radio.configurar(jornada)
	radio.alternar_encendido()
	radio.alternar_cassette()
	_comprobar(radio.cassette_insertada(), "se puede insertar el cassette simulado")
	_comprobar(radio.fuente_actual(), "cassette", "el cassette sustituye a la radio como fuente")
	_comprobar(
		radio.contenido_actual().get("id", ""),
		"cara_a_1",
		"la cinta comienza por su primer segmento",
	)
	_comprobar(radio.escuchar_actual(), "un segmento sin semilla puede completarse")
	_comprobar(
		radio.contenido_actual().get("id", ""),
		"cara_a_2",
		"completar un segmento avanza la cinta",
	)
	_comprobar(
		not radio.escuchar_actual(), "la pieza cultural de la cinta exige atención sostenida"
	)
	_comprobar(
		not SemillasOniricas.familias_activas(jornada).has("duat"),
		"la escucha incompleta del cassette no activa Duat",
	)
	_comprobar(radio.escuchar_actual(), "completar el segundo paso termina el segmento")
	_comprobar(
		SemillasOniricas.familias_activas(jornada).has("duat"),
		"el cassette puede activar una semilla deliberada",
	)
	radio.alternar_cassette()
	_comprobar(radio.fuente_actual(), "radio", "retirar la cinta devuelve la radio")
	radio.queue_free()


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Radio doméstica 98: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
