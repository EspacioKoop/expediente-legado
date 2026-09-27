extends SceneTree

## UI de crear/unirse a sala privada de #383: foco, mando y códigos.

const MinijuegoSalaPanel = preload("res://guion/red/minijuego_sala_panel.gd")

var pasadas := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var panel := MinijuegoSalaPanel.new()
	root.add_child(panel)
	await process_frame

	panel.abrir("Golf de pasillo", 1)
	await process_frame
	_comprobar("panel visible al abrir", panel.visible, true)

	var titulo := panel.find_child("TituloSala", true, false) as Label
	var codigo := panel.find_child("CodigoSala", true, false) as LineEdit
	var estado := panel.find_child("EstadoSala", true, false) as Label
	var crear := panel.find_child("CrearSala", true, false) as Button
	var unirse := panel.find_child("UnirseSala", true, false) as Button
	var volver := panel.find_child("VolverSala", true, false) as Button
	_comprobar("título identifica minijuego", titulo.text.contains("Golf de pasillo"), true)
	_comprobar("campo de código existe", codigo != null, true)
	_comprobar("crear acepta foco", crear.focus_mode, Control.FOCUS_ALL)
	_comprobar("unirse acepta foco", unirse.focus_mode, Control.FOCUS_ALL)
	_comprobar("volver acepta foco", volver.focus_mode, Control.FOCUS_ALL)
	_comprobar("foco inicial en crear", root.gui_get_focus_owner(), crear)

	var creados: Array[String] = []
	panel.crear_sala_solicitada.connect(func(valor: String): creados.append(valor))
	panel._crear_sala()
	_comprobar("crear emite una vez", creados.size(), 1)
	_comprobar("código creado tiene seis", creados[0].length(), 6)
	_comprobar("código creado es válido", MinijuegoSalaPanel.codigo_valido(creados[0]), true)
	_comprobar("campo refleja código", codigo.text, creados[0])
	_comprobar("estado anuncia código", estado.text.contains(creados[0]), true)

	var unidos: Array[String] = []
	panel.unirse_sala_solicitada.connect(func(valor: String): unidos.append(valor))
	codigo.text = " ab2cde "
	panel._unirse_sala()
	_comprobar("normaliza mayúsculas", panel.codigo_actual(), "AB2CDE")
	_comprobar("unirse emite código normalizado", unidos, ["AB2CDE"])

	codigo.text = "O0I1"
	panel._unirse_sala()
	_comprobar("código ambiguo no emite", unidos.size(), 1)
	_comprobar("código ambiguo muestra error", estado.text.is_empty(), false)

	panel.mostrar_estado("connecting")
	_comprobar("estado conexión legible", estado.text.is_empty(), false)
	panel.mostrar_estado("online", {"room_id": "ABC234"})
	_comprobar("online muestra sala", estado.text.contains("ABC234"), true)
	panel.mostrar_estado("incompatible_rules", {"local": 1, "remote": 2})
	_comprobar("incompatibilidad muestra versiones", estado.text.contains("v1"), true)
	_comprobar("incompatibilidad muestra remota", estado.text.contains("v2"), true)
	panel.mostrar_estado("timeout")
	_comprobar("timeout no promete progreso remoto", estado.text.contains("progreso"), true)

	var cancelaciones := [0]
	panel.cancelar_solicitado.connect(func(): cancelaciones[0] += 1)
	panel._volver.pressed.emit()
	_comprobar("volver emite cancelación", cancelaciones[0], 1)

	panel.cerrar()
	_comprobar("cerrar oculta panel", panel.visible, false)
	panel.queue_free()
	await process_frame
	_terminar()


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])


func _terminar() -> void:
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)
