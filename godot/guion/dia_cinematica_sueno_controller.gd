## Controller hijo dedicado a la transición casa→sueño de #395.
##
## Intercepta únicamente el trigger de dormir cuando el mundo activo es casa,
## reproduce la secuencia 3D y devuelve el MISMO evento al `_al_pisar_salida`
## oficial al terminar o saltar. No decide economía, política, sueño ni guardado.
extends Node

var _mundo_preparado_id := 0
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
	if mundo_id == _mundo_preparado_id:
		return
	_mundo_preparado_id = mundo_id

	if String(dia.jornada.get("fase", "")) != "casa":
		return
	_preparar_transicion_sueno(dia, mundo)


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
	# Si el flujo principal ya está bloqueado por guardado/modal, conserva su
	# prioridad y reenvía inmediatamente el evento al dueño real.
	if dia.partida.guardado_pendiente or dia._pantalla != null:
		dia._al_pisar_salida(cuerpo, salida)
		return
	if _cinematica_sueno != null:
		return

	_dia_transicion = dia
	_salida_sueno = salida
	# La fase sigue siendo casa durante todo el rodaje. Parar el process de Dia
	# congela pasos/gato; el reproductor es otro nodo y continúa avanzando.
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

	# Fin normal y skip convergen aquí. El controller solo reenvía el evento; el
	# flujo principal sigue siendo dueño de sellos, política, montaje y guardado.
	dia.set_process(true)
	dia._al_pisar_salida(dia._caminante, salida)
	dia._caminante.set_physics_process(true)
	dia._hud.visible = true
	var prioridades := dia.get_node_or_null("HUDPrioridades")
	if prioridades != null:
		prioridades.set("visible", _hud_prioridades_previo)
