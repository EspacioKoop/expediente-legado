## Smoke headless del visor de publicaciones (#674).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var escena := load("res://escenas/visor_publicacion.tscn") as PackedScene
	var visor := escena.instantiate() as VisorPublicacion
	root.add_child(visor)
	await process_frame

	var jornada := Jornada.nueva(674, 1)
	jornada["dia"] = 3
	jornada["fase"] = "casa"

	_comprobar(visor.abrir(jornada, "revista_umbral_98"), "abre publicación conocida")
	await process_frame
	_comprobar(visor.visible, "el visor queda visible")
	_comprobar(visor.pieza_actual_id() == "portada", "empieza por la primera pieza")
	_comprobar(visor.tamano_texto() == 22, "tamaño inicial legible")
	_comprobar(visor.tiene_foco_lectura(), "el foco inicial queda en el contenido")
	_comprobar(
		Publicaciones98.contenido_visto(jornada, "revista_umbral_98") == ["portada"],
		"mostrar la portada registra una única lectura",
	)
	_comprobar(
		SemillasOniricas.familias_activas(jornada).is_empty(),
		"abrir y leer una pieza no activa semilla",
	)

	var pagina_abajo := InputEventKey.new()
	pagina_abajo.keycode = KEY_PAGEDOWN
	pagina_abajo.pressed = true
	visor._unhandled_input(pagina_abajo)
	_comprobar(visor.pieza_actual_id() == "dossier", "PageDown avanza una pieza")
	_comprobar(
		Publicaciones98.contenido_visto(jornada, "revista_umbral_98").size() == 2,
		"navegar registra una segunda pieza distinta",
	)
	_comprobar(
		SemillasOniricas.familias_activas(jornada).is_empty(),
		"leer suficiente todavía no activa sin cerrar",
	)

	var pagina_arriba := InputEventKey.new()
	pagina_arriba.keycode = KEY_PAGEUP
	pagina_arriba.pressed = true
	visor._unhandled_input(pagina_arriba)
	_comprobar(visor.pieza_actual_id() == "portada", "PageUp retrocede una pieza")
	_comprobar(
		Publicaciones98.contenido_visto(jornada, "revista_umbral_98").size() == 2,
		"volver atrás no duplica progreso",
	)

	visor.ampliar_texto()
	_comprobar(visor.tamano_texto() == 26, "A+ amplía lectura")
	visor.ampliar_texto()
	visor.ampliar_texto()
	visor.ampliar_texto()
	_comprobar(visor.tamano_texto() == 30, "el tamaño máximo queda acotado")
	visor.reducir_texto()
	_comprobar(visor.tamano_texto() == 26, "A− reduce lectura")

	var cierre := visor.cerrar()
	_comprobar(not visor.visible, "cerrar oculta la ventana")
	_comprobar(bool(cierre.get("semilla_activada", false)), "cerrar tras dos piezas activa #442")
	_comprobar(
		SemillasOniricas.familias_activas(jornada) == ["minotauro"],
		"la familia activada sigue siendo la declarada",
	)

	var repetido := visor.cerrar()
	_comprobar(bool(repetido.get("repetido", false)), "cerrar dos veces es inocuo")
	_comprobar(
		SemillasOniricas.familias_activas(jornada) == ["minotauro"],
		"el doble cierre no añade otra familia",
	)

	var jornada_prensa := Jornada.nueva(675, 1)
	jornada_prensa["dia"] = 3
	jornada_prensa["fase"] = "casa"
	_comprobar(
		visor.abrir(jornada_prensa, "periodico_tarde_98", "local"),
		"puede abrir una pieza inicial concreta",
	)
	await process_frame
	_comprobar(visor.pieza_actual_id() == "local", "respeta la pieza inicial")

	var piezas_prensa: Array = Publicaciones98.por_id("periodico_tarde_98").get("piezas", [])
	var indice_local := -1
	for indice in range(piezas_prensa.size()):
		if String(piezas_prensa[indice].get("id", "")) == "local":
			indice_local = indice
			break
	_comprobar(indice_local >= 0, "la pieza inicial existe en el catálogo")
	var siguiente_prensa := String(piezas_prensa[indice_local + 1].get("id", ""))

	var hombro_derecho := InputEventJoypadButton.new()
	hombro_derecho.button_index = JOY_BUTTON_RIGHT_SHOULDER
	hombro_derecho.pressed = true
	visor._unhandled_input(hombro_derecho)
	_comprobar(visor.pieza_actual_id() == siguiente_prensa, "R1 avanza con mando")

	var hombro_izquierdo := InputEventJoypadButton.new()
	hombro_izquierdo.button_index = JOY_BUTTON_LEFT_SHOULDER
	hombro_izquierdo.pressed = true
	visor._unhandled_input(hombro_izquierdo)
	_comprobar(visor.pieza_actual_id() == "local", "L1 retrocede con mando")

	var cerrar_mando := InputEventJoypadButton.new()
	cerrar_mando.button_index = JOY_BUTTON_B
	cerrar_mando.pressed = true
	visor._unhandled_input(cerrar_mando)
	_comprobar(not visor.visible, "B cierra con mando")
	_comprobar(
		SemillasOniricas.familias_activas(jornada_prensa).is_empty(),
		"prensa general sigue sin contaminar sueño",
	)

	_comprobar(not visor.abrir({}, "no_existe"), "rechaza publicación inexistente")

	visor.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
