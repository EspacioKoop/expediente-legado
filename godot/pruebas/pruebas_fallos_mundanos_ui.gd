extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var raiz := Control.new()
	get_root().add_child(raiz)

	var previo := Button.new()
	previo.text = "Anterior"
	raiz.add_child(previo)

	var panel := FalloMundanoSigaPanel.new()
	raiz.add_child(panel)
	await process_frame

	previo.grab_focus()
	await process_frame
	_comprobar(panel.presentar("shareware_expirado", "licencia_expirada"), "presenta fallo conocido")
	await process_frame
	_comprobar(panel.visible, "el aviso queda visible")
	var cerrar := panel.get_node_or_null("Cerrar") as Button
	_comprobar(cerrar != null, "existe salida cerrable")
	_comprobar(cerrar != null and cerrar.focus_mode == Control.FOCUS_ALL, "el cierre acepta teclado")
	_comprobar(get_root().gui_get_focus_owner() == cerrar, "el aviso dirige foco al cierre")
	var detalle := panel.get_node_or_null("Detalle") as Label
	_comprobar(detalle != null and detalle.text.contains("Solución:"), "muestra causa y resolución")

	panel.cerrar()
	await process_frame
	_comprobar(not panel.visible, "cerrar oculta el aviso")
	_comprobar(get_root().gui_get_focus_owner() == previo, "cerrar devuelve el foco anterior")

	_comprobar(
		not panel.presentar("shareware_expirado", "evento_distinto"),
		"un evento distinto no fabrica una incidencia",
	)
	_comprobar(not panel.visible, "un evento inactivo no deja UI residual")

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
