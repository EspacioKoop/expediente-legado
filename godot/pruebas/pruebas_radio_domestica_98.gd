extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_programacion_narrativa()
	_probar_radio_deliberada()
	_probar_cassette_deliberado()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_programacion_narrativa() -> void:
	var radio := MinicadenaDomestica98.new()
	root.add_child(radio)
	radio.configurar({"dia": 1, "acciones": Jornada.ACCIONES_POR_DIA})
	var emisoras := radio.emisoras()
	_comprobar(emisoras.size(), 3, "hay tres emisoras declarativas")
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
