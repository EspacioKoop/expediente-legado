extends SceneTree

const CONTROLADOR := preload("res://guion/dia_sueno_reactivo_app.gd")

var _pasadas := 0
var _fallos := 0


class DiaFalso:
	extends Node

	var jornada := {"fase": "sueño", "leido_hoy": ["doc-a", "doc-b"]}
	var partida := Partida.new()
	var guardados := 0
	var _mundo: Node3D = null

	func _guardar_o_avisar(_mensaje: String) -> bool:
		guardados += 1
		return true


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	var dia := DiaFalso.new()
	root.add_child(dia)
	dia.partida.estado = Partida.nueva()
	GrabacionOniricaEstado.iniciar_cinta(dia.partida.estado, 10.0)
	_comprobar(
		bool(
			GrabacionOniricaEstado.registrar_toma(dia.partida.estado, _toma("doc-a", 0.8)).get("ok")
		),
		"primera toma entra en cinta",
	)
	_comprobar(
		bool(
			GrabacionOniricaEstado.registrar_toma(dia.partida.estado, _toma("doc-b", 0.2)).get("ok")
		),
		"segunda toma entra en cinta",
	)
	_comprobar(
		GrabacionOniricaEstado.seleccion_actual(dia.partida.estado).is_empty(),
		"registrar sigue sin autoseleccionar",
	)

	var controlador := CONTROLADOR.new()
	dia.add_child(controlador)
	# Godot reactiva el procesado al entrar en el árbol si el guion define
	# _process; se apaga después para que el HUD solo cambie cuando la prueba lo pide.
	controlador.process_mode = Node.PROCESS_MODE_DISABLED
	controlador.set_process(false)
	controlador._asegurar_hud_camara()
	controlador._actualizar_hud_camara(dia)
	await process_frame

	var selector := controlador._hud_tomas
	_comprobar(selector != null, "HUD crea selector de tomas")
	if selector == null:
		_terminar(dia)
		return

	_comprobar(selector.get_child_count() == 2, "muestra exactamente las dos tomas")
	var primera := selector.get_child(0) as Button
	var segunda := selector.get_child(1) as Button
	_comprobar(
		primera != null and primera.text == "1✓", "la toma válida se identifica sin copy nuevo"
	)
	_comprobar(
		segunda != null and segunda.text == "2~", "la contaminada se distingue sin reinterpretarla"
	)
	_comprobar(
		primera != null and primera.focus_mode == Control.FOCUS_ALL,
		"botones admiten foco de teclado o mando",
	)
	_comprobar(
		segunda != null and segunda.focus_mode == Control.FOCUS_ALL,
		"segunda toma admite foco de teclado o mando",
	)
	_comprobar(
		not primera.button_pressed and not segunda.button_pressed, "no hay selección implícita"
	)

	# asegurar_en_estado sustituye el contenedor por una copia en cada llamada:
	# hay que releerlo tras cada pulsación, no conservar una referencia vieja.
	var tomas_antes := JSON.stringify(_tomas(dia))
	primera.pressed.emit()
	await process_frame
	_comprobar(
		_toma_seleccionada(dia) == 0,
		"pulsar 1 selecciona explícitamente la primera",
	)
	_comprobar(dia.guardados == 1, "selección explícita guarda una vez")
	# Seleccionar reconstruye el HUD y libera los botones anteriores al siguiente frame.
	# Relee las referencias antes de emitir otra pulsación para no usar un nodo ya liberado.
	selector = controlador._hud_tomas
	primera = selector.get_child(0) as Button
	segunda = selector.get_child(1) as Button
	_comprobar(
		JSON.stringify(_tomas(dia)) == tomas_antes,
		"seleccionar no reevalúa ni modifica las tomas",
	)
	_comprobar(
		(
			String(GrabacionOniricaEstado.seleccion_actual(dia.partida.estado).get("estado", ""))
			== GrabacionOniricaContrato.ESTADO_VALIDA
		),
		"estado seleccionado procede de la evaluación persistida",
	)

	segunda.pressed.emit()
	await process_frame
	_comprobar(
		_toma_seleccionada(dia) == 1,
		"pulsar 2 cambia la selección explícitamente",
	)
	_comprobar(dia.guardados == 2, "cambiar selección persiste una vez")
	_comprobar(
		(
			String(GrabacionOniricaEstado.seleccion_actual(dia.partida.estado).get("estado", ""))
			== GrabacionOniricaContrato.ESTADO_CONTAMINADA
		),
		"también puede elegirse una toma contaminada sin ocultarla",
	)

	controlador._hud_tomas_firma = ""
	controlador._actualizar_hud_camara(dia)
	await process_frame
	selector = controlador._hud_tomas
	primera = selector.get_child(0) as Button
	segunda = selector.get_child(1) as Button
	_comprobar(
		not primera.button_pressed and segunda.button_pressed, "HUD refleja la selección persistida"
	)

	_terminar(dia)


func _toma(original_id: String, proporcion: float) -> Dictionary:
	return {
		"original_id": original_id,
		"original_identificado": true,
		"frase_completa": true,
		"tiempo_sujeto": 2.0 * proporcion,
		"duracion_total": 2.0,
		"figura_detecto_camara": false,
		"hubo_corte": false,
	}


func _toma_seleccionada(dia: DiaFalso) -> int:
	var contenedor := GrabacionOniricaEstado.asegurar_en_estado(dia.partida.estado)
	return int(contenedor.get("toma_seleccionada", -1))


func _tomas(dia: DiaFalso) -> Array:
	var contenedor := GrabacionOniricaEstado.asegurar_en_estado(dia.partida.estado)
	return (contenedor["cinta"] as Dictionary).get("tomas", [])


func _terminar(dia: Node) -> void:
	dia.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)
