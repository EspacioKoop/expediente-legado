## La carta debe desembocar en una ventana real, incluso si se salta el vídeo.
class_name PruebasHistoria
extends RefCounted

const ESCENA := preload("res://escenas/historia.tscn")


static func catalogo(comprobar: Callable) -> void:
	var historias := Historias.new()
	comprobar.call("la pantalla dispone del catálogo", historias.cargar(), true)
	for carta in historias.catalogo:
		var estado := Partida.nueva()
		var pendiente := historias.vista(estado, carta)
		comprobar.call("cada historia ofrece cuatro opciones", pendiente["opciones"].size(), 4)
		for opcion in pendiente["opciones"]:
			comprobar.call("cada opción tiene texto", opcion["texto"].is_empty(), false)


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
	pantalla.guardar = func(): return false
	arbol.root.add_child(pantalla)
	pantalla.popup_centered_clamped(Vector2i(900, 600), 0.9)
	await arbol.process_frame
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
