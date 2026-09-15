## Regresión de integración para #280: la transición casa -> sueño tiene que
## atravesar los Area3D y controllers de la escena real, no llamar directamente
## a Dia._al_pisar_salida como hacen algunos helpers unitarios.
extends SceneTree

const ESCENA_DIA := preload("res://escenas/dia.tscn")
const SEMILLA := 280280

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	if OS.get_environment("LEGADO_PRUEBAS_AISLADAS") != "1":
		push_error("Esta prueba necesita un directorio de usuario aislado")
		quit(1)
		return

	var por_salto: Dictionary = await _recorrer(true)
	var por_fin: Dictionary = await _recorrer(false)

	_comprobar(
		por_salto.get("jornada", {}) == por_fin.get("jornada", {}),
		"saltar y terminar dejan la misma jornada",
	)
	_comprobar(
		por_salto.get("vistas", {}) == por_fin.get("vistas", {}),
		"saltar y terminar anotan las mismas vistas",
	)
	_comprobar(
		por_salto.get("vistas", {}).get(SuenoCinematica.ID, 0) == 1,
		"la cama cuenta exactamente una vista",
	)
	_comprobar(
		por_salto.get("vistas", {}).get(EntradaSuenoCinematica.ID, 0) == 1,
		"la entrada al sueño cuenta exactamente una vista",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _recorrer(saltar: bool) -> Dictionary:
	_preparar_partida_en_casa()

	var dia = ESCENA_DIA.instantiate()
	root.add_child(dia)
	# Un frame monta casa; el siguiente deja al controller hijo sustituir el
	# callback directo de Dia por el enganche cinematográfico real.
	await process_frame
	await process_frame

	var controller = dia.get_node_or_null("CinematicaSuenoController")
	_comprobar(controller != null, "la escena trae CinematicaSuenoController")
	if controller == null:
		dia.queue_free()
		await process_frame
		return {}

	var salida := _salida_hacia(dia._mundo, "sueño")
	_comprobar(salida != null, "la casa montada trae la salida real hacia sueño")
	if salida == null:
		dia.queue_free()
		await process_frame
		return {}

	var engancha_controller := false
	var engancha_dia := false
	for conexion in salida.body_entered.get_connections():
		var callback: Callable = conexion.get("callable", Callable())
		if not callback.is_valid():
			continue
		engancha_controller = engancha_controller or callback.get_object() == controller
		engancha_dia = engancha_dia or callback.get_object() == dia
	_comprobar(engancha_controller, "la salida real está interceptada por el controller")
	_comprobar(not engancha_dia, "la salida real ya no salta el controller llamando a Dia")

	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, SuenoCinematica.ID) == 0,
		"una partida nueva no trae la cinemática de cama premarcada",
	)
	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, EntradaSuenoCinematica.ID) == 0,
		"una partida nueva no trae la entrada al sueño premarcada",
	)

	# Es el mismo evento que produciría CharacterBody3D al entrar en el Area3D.
	salida.emit_signal("body_entered", dia._caminante)
	var cinematica_cama = controller.get("_cinematica_sueno")
	_comprobar(cinematica_cama != null, "pisar la cama abre la primera cinemática")
	_comprobar(dia.jornada.get("fase", "") == "casa", "la regla de dormir espera a la cama")
	_comprobar(not dia._caminante.is_physics_processing(), "la cama bloquea movimiento del jugador")

	if cinematica_cama != null:
		_finalizar(cinematica_cama, saltar)

	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, SuenoCinematica.ID) == 1,
		"terminar la cama anota su primera vista",
	)
	_comprobar(dia.jornada.get("fase", "") == "sueño", "el callback real ejecuta la regla de dormir")
	_comprobar(dia._entrada_sueno != null, "dormir encadena la entrada a la sala onírica")
	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, EntradaSuenoCinematica.ID) == 0,
		"la segunda cinemática no se marca hasta terminar",
	)
	_comprobar(dia._mundo.process_mode == Node.PROCESS_MODE_DISABLED, "el sueño queda congelado durante la entrada")
	_comprobar(not dia._caminante.is_physics_processing(), "la entrada mantiene bloqueado al jugador")

	var entrada = dia._entrada_sueno
	if entrada != null:
		_finalizar(entrada, saltar)

	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, EntradaSuenoCinematica.ID) == 1,
		"terminar la entrada anota su primera vista",
	)
	_comprobar(dia._entrada_sueno == null, "el callback retira el reproductor al terminar")
	_comprobar(dia._mundo.process_mode == Node.PROCESS_MODE_INHERIT, "el mundo vuelve a procesar al recuperar control")
	_comprobar(dia._caminante.is_physics_processing(), "el jugador recupera movimiento después de la entrada")
	_comprobar(dia._hud.visible, "el HUD vuelve después de la transición")

	var resultado := {
		"jornada": dia.jornada.duplicate(true),
		"vistas": dia.partida.estado.get("cinematicas_vistas", {}).duplicate(true),
	}
	dia.queue_free()
	await process_frame
	return resultado


func _preparar_partida_en_casa() -> void:
	var estado := Partida.nueva()
	estado["semilla"] = SEMILLA
	estado["jornada"] = Jornada.nueva(SEMILLA)
	estado["jornada"]["fase"] = "casa"
	var partida := Partida.new()
	partida.estado = estado
	_comprobar(partida.guardar(), "la partida aislada de la prueba se puede preparar")


func _finalizar(reproductor, saltar: bool) -> void:
	if saltar:
		reproductor.saltar()
		return
	# Avanza por el camino temporal normal sin esperar varios segundos reales.
	# `_process` solo consume un plano por llamada, así que el bucle sigue
	# atravesando `_siguiente()` y `_terminar()` como lo haría el reloj.
	var guardia := 0
	while bool(reproductor.get("_reproduciendo")) and guardia < 16:
		reproductor.call("_process", 999.0)
		guardia += 1
	_comprobar(guardia < 16, "el fin temporal de la cinemática no se atasca")


func _salida_hacia(nodo: Node, destino: String) -> Area3D:
	for hijo in nodo.get_children():
		if hijo is Area3D and String(hijo.get_meta("destino", "")) == destino:
			return hijo
		var encontrada := _salida_hacia(hijo, destino)
		if encontrada != null:
			return encontrada
	return null


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
