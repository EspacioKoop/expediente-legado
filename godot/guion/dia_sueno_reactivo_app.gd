## Controller hijo para el corte onírico de #400 y la transición casa→sueño de #395.
##
## Observa el mundo ya construido por Dia. En casa sustituye únicamente la
## conexión automática de la cama por una cinemática 3D y, cuando ésta termina
## o se salta, devuelve el mismo evento al `_al_pisar_salida` real de Dia. En
## sueño conserva su responsabilidad previa: montar dressing reactivo.
## No cambia la cadena de herencia ni duplica Jornada, sellos o guardado.
extends Node

var _mundo_vestido_id := 0
var _cinematica_sueno: Node3D = null
var _dia_transicion: Node = null
var _salida_sueno: Area3D = null
var _hud_prioridades_previo := true


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_vestido_id:
		return

	_mundo_vestido_id = mundo_id
	var fase := String(dia.jornada.get("fase", ""))
	if fase == "casa":
		_preparar_transicion_sueno(dia, mundo)
		return
	if fase != "sueño":
		return
	var escenas: Array = dia.jornada.get("sueno_escenas", [])
	if escenas.is_empty():
		return
	(
		SuenoUtileria
		. montar(
			mundo,
			String(escenas[0]),
			int(dia.jornada.get("dia", 1)),
			dia._raiz(),
		)
	)


## Toma solo el callback que Dia conectó al trigger de dormir. Otros listeners
## del Area3D, si aparecen en cortes futuros, se conservan.
func _preparar_transicion_sueno(dia: Node, mundo: Node3D) -> void:
	var salida := _buscar_salida_sueno(mundo)
	if salida == null:
		return
	for conexion in salida.body_entered.get_connections():
		var callback: Callable = conexion.get("callable", Callable())
		if callback.is_valid() and callback.get_object() == dia:
			salida.body_entered.disconnect(callback)
	salida.body_entered.connect(_al_pisar_cama.bind(dia, salida))


func _buscar_salida_sueno(nodo: Node) -> Area3D:
	for hijo in nodo.get_children():
		if hijo is Area3D and String(hijo.get_meta("destino", "")) == "sueño":
			return hijo
		var encontrada := _buscar_salida_sueno(hijo)
		if encontrada != null:
			return encontrada
	return null


func _al_pisar_cama(cuerpo: Node3D, dia: Node, salida: Area3D) -> void:
	if cuerpo != dia._caminante:
		return
	# Un guardado pendiente conserva prioridad absoluta. Como ya retiramos la
	# conexión automática, reenviamos inmediatamente el evento al dueño real.
	if dia.partida.guardado_pendiente or dia._pantalla != null:
		dia._al_pisar_salida(cuerpo, salida)
		return
	if _cinematica_sueno != null:
		return

	_dia_transicion = dia
	_salida_sueno = salida
	# `fase` sigue siendo casa durante todo el rodaje. Parar el process de Dia
	# congela pasos/gato; el reproductor es otro nodo y sigue avanzando.
	dia.set_process(false)
	dia._caminante.set_physics_process(false)
	dia._hud.visible = false
	var prioridades := dia.get_node_or_null("HUDPrioridades")
	if prioridades != null:
		_hud_prioridades_previo = bool(prioridades.get("visible"))
		prioridades.set("visible", false)

	_cinematica_sueno = load("res://escenas/cinematica.tscn").instantiate()
	dia.add_child(_cinematica_sueno)
	_cinematica_sueno.terminada.connect(_terminar_transicion_sueno)
	var vistas := Cinematica.vistas_de(dia.partida.estado, SuenoCinematica.ID)
	_cinematica_sueno.reproducir(
		SuenoCinematica.planos_de(vistas), SuenoCinematica.ID, dia.partida.estado
	)


func _terminar_transicion_sueno() -> void:
	if _cinematica_sueno == null:
		return
	_cinematica_sueno.queue_free()
	_cinematica_sueno = null

	var dia := _dia_transicion
	var salida := _salida_sueno
	_dia_transicion = null
	_salida_sueno = null
	if dia == null or not is_instance_valid(dia) or not is_instance_valid(salida):
		return

	# Fin normal y skip llegan aquí por la misma señal `terminada`. Solo ahora
	# devolvemos el evento al flujo oficial: dia_clima registra su sello y la
	# cadena existente acaba en Jornada.dormir(), política, montaje y guardado.
	dia.set_process(true)
	dia._al_pisar_salida(dia._caminante, salida)
	dia._caminante.set_physics_process(true)
	dia._hud.visible = true
	var prioridades := dia.get_node_or_null("HUDPrioridades")
	if prioridades != null:
		prioridades.set("visible", _hud_prioridades_previo)
