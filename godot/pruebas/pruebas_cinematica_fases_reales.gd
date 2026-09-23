## Regresión de integración para #280: las cinemáticas de cambio de fase tienen
## que atravesar los enganches de la escena real, no limitarse a probar catálogos
## o llamar directamente a Dia._al_pisar_salida como hacen algunos helpers.
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

	await _probar_entrada_de_vuelta()
	await _probar_inicio_de_jornada()

	var trayecto_por_salto: Dictionary = await _recorrer_archivo_trayecto(true)
	var trayecto_por_fin: Dictionary = await _recorrer_archivo_trayecto(false)
	_comprobar(
		trayecto_por_salto.get("jornada", {}) == trayecto_por_fin.get("jornada", {}),
		"ascensor: saltar y terminar dejan la misma jornada",
	)
	_comprobar(
		trayecto_por_salto.get("vistas", {}) == trayecto_por_fin.get("vistas", {}),
		"ascensor: saltar y terminar anotan las mismas vistas",
	)
	_comprobar(
		trayecto_por_salto.get("vistas", {}).get(AscensorCinematica.ID, 0) == 1,
		"ascensor: la salida real cuenta exactamente una vista",
	)

	var sueno_por_salto: Dictionary = await _recorrer_casa_sueno(true)
	var sueno_por_fin: Dictionary = await _recorrer_casa_sueno(false)
	_comprobar(
		sueno_por_salto.get("jornada", {}) == sueno_por_fin.get("jornada", {}),
		"sueño: saltar y terminar dejan la misma jornada",
	)
	_comprobar(
		sueno_por_salto.get("vistas", {}) == sueno_por_fin.get("vistas", {}),
		"sueño: saltar y terminar anotan las mismas vistas",
	)
	_comprobar(
		sueno_por_salto.get("vistas", {}).get(SuenoCinematica.ID, 0) == 1,
		"sueño: la cama cuenta exactamente una vista",
	)
	_comprobar(
		sueno_por_salto.get("vistas", {}).get(EntradaSuenoCinematica.ID, 0) == 1,
		"sueño: la entrada onírica cuenta exactamente una vista",
	)

	# Las escenas oníricas pueden liberar texturas y RIDs de render de forma diferida.
	# Damos el mismo margen de drenaje que otras regresiones 3D antes de cerrar
	# SceneTree, sin ocultar errores: el wrapper Python sigue rechazando cualquier
	# ERROR real que Godot imprima durante la ejecución o el teardown.
	await create_timer(0.25).timeout
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


## #68: una partida realmente nueva tiene que montar la entrada sobre la oficina
## real, bloquear control y anotar la vista al terminar.
func _probar_entrada_de_vuelta() -> void:
	_preparar_partida("archivo", 1, Jornada.ACCIONES_POR_DIA)

	var dia = ESCENA_DIA.instantiate()
	root.add_child(dia)
	await process_frame

	_comprobar(dia._entrada != null, "entrada: una partida nueva monta la cinemática inicial")
	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, EntradaCinematica.ID) == 0,
		"entrada: la primera vista no viene premarcada",
	)
	_comprobar(not dia._caminante.is_physics_processing(), "entrada: bloquea movimiento")
	_comprobar(not dia._hud.visible, "entrada: oculta el HUD durante la secuencia")

	var entrada = dia._entrada
	if entrada != null:
		_finalizar(entrada, false)

	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, EntradaCinematica.ID) == 1,
		"entrada: terminar anota exactamente una vista",
	)
	_comprobar(dia._entrada == null, "entrada: retira el reproductor al terminar")
	_comprobar(dia._caminante.is_physics_processing(), "entrada: devuelve movimiento")
	_comprobar(dia._hud.visible, "entrada: devuelve el HUD")

	dia.queue_free()
	await process_frame


## #69: un comienzo de jornada posterior usa su hook real y no se confunde con
## la entrada de una nueva vida laboral.
func _probar_inicio_de_jornada() -> void:
	_preparar_partida("archivo", 2, Jornada.ACCIONES_POR_DIA)

	var dia = ESCENA_DIA.instantiate()
	root.add_child(dia)
	await process_frame
	await process_frame

	_comprobar(dia._entrada == null, "jornada: el día 2 no repite la entrada de vuelta")
	_comprobar(
		dia._inicio_jornada != null,
		"jornada: el comienzo del día 2 monta su cinemática real",
	)
	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, InicioJornadaCinematica.ID) == 0,
		"jornada: la primera vista no viene premarcada",
	)
	_comprobar(not dia._caminante.is_physics_processing(), "jornada: bloquea movimiento")
	_comprobar(not dia._hud.visible, "jornada: oculta el HUD")

	var inicio = dia._inicio_jornada
	if inicio != null:
		_finalizar(inicio, true)

	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, InicioJornadaCinematica.ID) == 1,
		"jornada: saltar anota exactamente una vista",
	)
	_comprobar(dia._inicio_jornada == null, "jornada: retira el reproductor al terminar")
	_comprobar(dia._caminante.is_physics_processing(), "jornada: devuelve movimiento")
	_comprobar(dia._hud.visible, "jornada: devuelve el HUD")

	dia.queue_free()
	await process_frame


## Salida real de oficina: el Area3D tiene que pasar por DiaAscensorApp, asentar
## trayecto, presentar el selector y montar el ascensor antes de devolver control.
func _recorrer_archivo_trayecto(saltar: bool) -> Dictionary:
	# Sin acciones no se abre #69 y representa además el momento normal de fichar.
	_preparar_partida("archivo", 2, 0)

	var dia = ESCENA_DIA.instantiate()
	root.add_child(dia)
	await process_frame
	await process_frame

	var salida := _salida_archivo_trayecto(dia._mundo)
	_comprobar(salida != null, "ascensor: la oficina trae una salida real hacia trayecto")
	if salida == null:
		dia.queue_free()
		await process_frame
		return {}

	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, AscensorCinematica.ID) == 0,
		"ascensor: una partida preparada no trae la bajada premarcada",
	)

	# #790: cruzar el umbral ya no dispara nada. El Area3D conserva el contrato
	# de destino para las capas existentes, pero deja de monitorizar cuerpos y de
	# bloquear el raycast que apunta al Interactuable3D de la puerta.
	_comprobar(not salida.monitoring, "ascensor: el umbral ya no sale por proximidad")
	_comprobar(not salida.monitorable, "ascensor: el trigger antiguo no tapa la interacción")

	var puerta: Interactuable3D = dia._puerta_salida_oficina
	_comprobar(puerta != null, "ascensor: la oficina monta una puerta interactuable")
	if puerta == null:
		dia.queue_free()
		await process_frame
		return {}

	_comprobar(puerta.habilitado, "ascensor: la puerta empieza disponible")
	puerta.interactuar(dia._caminante)
	_comprobar(
		dia.jornada.get("fase", "") == "archivo",
		"ascensor: interactuar todavía no cambia de fase sin confirmar",
	)
	_comprobar(dia._confirmacion_salida != null, "ascensor: interactuar abre confirmación")
	_comprobar(not puerta.habilitado, "ascensor: el modal evita reabrir la misma puerta")
	_comprobar(
		not dia._caminante.is_physics_processing(),
		"ascensor: confirmar salida bloquea movimiento",
	)

	var confirmacion: ConfirmationDialog = dia._confirmacion_salida
	if confirmacion != null:
		confirmacion.emit_signal("canceled")
	_comprobar(
		dia.jornada.get("fase", "") == "archivo",
		"ascensor: quedarse conserva la fase de oficina",
	)
	_comprobar(dia._confirmacion_salida == null, "ascensor: cancelar retira el modal")
	_comprobar(puerta.habilitado, "ascensor: cancelar vuelve a habilitar la puerta")
	_comprobar(
		dia._caminante.is_physics_processing(),
		"ascensor: cancelar devuelve movimiento",
	)

	puerta.interactuar(dia._caminante)
	confirmacion = dia._confirmacion_salida
	_comprobar(confirmacion != null, "ascensor: la puerta puede confirmarse tras cancelar")
	if confirmacion != null:
		confirmacion.emit_signal("confirmed")
	_comprobar(
		dia.jornada.get("fase", "") == "trayecto",
		"ascensor: confirmar la puerta asienta trayecto antes de la presentación",
	)
	_comprobar(dia._selector_ruta != null, "ascensor: la salida real abre el selector de ruta")
	_comprobar(
		not dia._caminante.is_physics_processing(), "ascensor: el selector bloquea movimiento"
	)
	_comprobar(not dia._hud.visible, "ascensor: el selector oculta el HUD")

	# ConfirmationDialog ya está cubierto por UI; aquí seguimos la misma callback
	# que ejecuta su botón "Ascensor" para validar el enganche cinematográfico.
	dia._iniciar_ascensor()
	var ascensor = dia._ascensor
	_comprobar(ascensor != null, "ascensor: elegir la ruta monta la escena 3D real")
	_comprobar(dia._selector_ruta == null, "ascensor: el selector se retira al elegir")

	if ascensor != null:
		_finalizar(ascensor, saltar)

	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, AscensorCinematica.ID) == 1,
		"ascensor: terminar anota exactamente una vista",
	)
	_comprobar(dia._ascensor == null, "ascensor: el reproductor se retira al terminar")
	_comprobar(dia._caminante.is_physics_processing(), "ascensor: devuelve movimiento")
	_comprobar(dia._hud.visible, "ascensor: devuelve el HUD")

	var resultado := {
		"jornada": dia.jornada.duplicate(true),
		"vistas": dia.partida.estado.get("cinematicas_vistas", {}).duplicate(true),
	}
	dia.queue_free()
	await process_frame
	return resultado


## #74/#395: casa -> sueño atraviesa el Area3D real y el controller dedicado,
## encadenando cama y entrada onírica sin alterar el estado entre skip y fin.
func _recorrer_casa_sueno(saltar: bool) -> Dictionary:
	_preparar_partida("casa", 1, Jornada.ACCIONES_POR_DIA)

	var dia = ESCENA_DIA.instantiate()
	root.add_child(dia)
	# Un frame monta casa; el siguiente deja al controller hijo sustituir el
	# callback directo de Dia por el enganche cinematográfico real.
	await process_frame
	await process_frame

	var controller = dia.get_node_or_null("CinematicaSuenoController")
	_comprobar(controller != null, "sueño: la escena trae CinematicaSuenoController")
	if controller == null:
		dia.queue_free()
		await process_frame
		return {}

	var salida := _salida_hacia(dia._mundo, "sueño")
	_comprobar(salida != null, "sueño: la casa montada trae la salida real hacia sueño")
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
	_comprobar(engancha_controller, "sueño: la salida real está interceptada por el controller")
	_comprobar(not engancha_dia, "sueño: la salida real no salta el controller llamando a Dia")

	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, SuenoCinematica.ID) == 0,
		"sueño: una partida preparada no trae la cama premarcada",
	)
	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, EntradaSuenoCinematica.ID) == 0,
		"sueño: una partida preparada no trae la entrada onírica premarcada",
	)

	# Es el mismo evento que produciría CharacterBody3D al entrar en el Area3D.
	salida.emit_signal("body_entered", dia._caminante)
	var cinematica_cama = controller.get("_cinematica_sueno")
	_comprobar(cinematica_cama != null, "sueño: pisar la cama abre la primera cinemática")
	_comprobar(dia.jornada.get("fase", "") == "casa", "sueño: la regla de dormir espera a la cama")
	_comprobar(not dia._caminante.is_physics_processing(), "sueño: la cama bloquea movimiento")

	if cinematica_cama != null:
		_finalizar(cinematica_cama, saltar)

	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, SuenoCinematica.ID) == 1,
		"sueño: terminar la cama anota su primera vista",
	)
	_comprobar(dia._pantalla != null, "sueño: terminar la cama abre la preparación nocturna")
	_comprobar(
		dia.jornada.get("fase", "") == "casa",
		"sueño: la preparación mantiene la jornada en casa hasta confirmar",
	)
	_comprobar(
		dia._entrada_sueno == null,
		"sueño: la entrada onírica no empieza antes de confirmar la preparación",
	)

	var preparacion = null
	if dia._pantalla != null and dia._pantalla.get_child_count() > 0:
		preparacion = dia._pantalla.get_child(0)
	_comprobar(
		preparacion != null and preparacion.has_signal("confirmada"),
		"sueño: la pantalla expone la confirmación de memoria nocturna",
	)
	if preparacion != null:
		preparacion.call("_emitir_confirmacion")

	_comprobar(
		dia.jornada.get("fase", "") == "sueño",
		"sueño: confirmar la preparación ejecuta la regla de dormir",
	)
	_comprobar(dia._entrada_sueno != null, "sueño: dormir encadena la entrada a la sala onírica")
	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, EntradaSuenoCinematica.ID) == 0,
		"sueño: la segunda cinemática no se marca hasta terminar",
	)
	_comprobar(
		dia._mundo.process_mode == Node.PROCESS_MODE_DISABLED,
		"sueño: el mundo queda congelado durante la entrada"
	)
	_comprobar(
		not dia._caminante.is_physics_processing(),
		"sueño: la entrada mantiene bloqueado al jugador"
	)

	var entrada = dia._entrada_sueno
	if entrada != null:
		_finalizar(entrada, saltar)

	_comprobar(
		Cinematica.vistas_de(dia.partida.estado, EntradaSuenoCinematica.ID) == 1,
		"sueño: terminar la entrada anota su primera vista",
	)
	_comprobar(dia._entrada_sueno == null, "sueño: el callback retira el reproductor al terminar")
	_comprobar(
		dia._mundo.process_mode == Node.PROCESS_MODE_INHERIT,
		"sueño: el mundo vuelve a procesar al recuperar control"
	)
	_comprobar(
		dia._caminante.is_physics_processing(),
		"sueño: el jugador recupera movimiento después de la entrada"
	)
	_comprobar(dia._hud.visible, "sueño: el HUD vuelve después de la transición")

	var resultado := {
		"jornada": dia.jornada.duplicate(true),
		"vistas": dia.partida.estado.get("cinematicas_vistas", {}).duplicate(true),
	}
	dia.queue_free()
	await process_frame
	return resultado


func _preparar_partida(fase: String, dia_numero: int, acciones: int) -> void:
	var estado := Partida.nueva()
	estado["semilla"] = SEMILLA
	estado["jornada"] = Jornada.nueva(SEMILLA)
	estado["jornada"]["fase"] = fase
	estado["jornada"]["dia"] = dia_numero
	estado["jornada"]["acciones"] = acciones
	var partida := Partida.new()
	partida.estado = estado
	_comprobar(partida.guardar(), "la partida aislada de la prueba se puede preparar")


func _finalizar(reproductor, saltar: bool) -> void:
	if saltar:
		reproductor.saltar()
		return
	# Avanza por el camino temporal normal sin esperar varios segundos reales.
	# _process solo consume un plano por llamada, así que el bucle sigue
	# atravesando _siguiente() y _terminar() como lo haría el reloj.
	var guardia := 0
	while bool(reproductor.get("_reproduciendo")) and guardia < 16:
		reproductor.call("_process", 999.0)
		guardia += 1
	_comprobar(guardia < 16, "el fin temporal de la cinemática no se atasca")


func _salida_archivo_trayecto(nodo: Node) -> Area3D:
	for hijo in nodo.get_children():
		if (
			hijo is Area3D
			and String(hijo.get_meta("destino", "")) == "trayecto"
			and String(hijo.get_meta("frase", "")).is_empty()
			and String(hijo.get_meta("duelo", "")).is_empty()
		):
			return hijo
		var encontrada := _salida_archivo_trayecto(hijo)
		if encontrada != null:
			return encontrada
	return null


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
