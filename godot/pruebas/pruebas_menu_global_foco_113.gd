extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var menu := root.get_node_or_null("MenuGlobal")
	_comprobar(menu != null, "MenuGlobal existe como autoload real")
	if menu == null:
		_terminar()
		return

	menu._fondo.visible = true
	menu._panel_principal.visible = true
	menu._panel_opciones.visible = false
	menu._panel_sellos.visible = false
	menu._panel_historial.visible = false
	menu._panel_incidencias.visible = false
	await process_frame

	var principal: Array[Control] = menu._encadenar_foco_panel(menu._panel_principal)
	_comprobar(principal.size() >= 5, "el panel principal expone una cadena completa")
	_probar_cadena(principal, "principal")

	menu._mostrar_opciones()
	await process_frame
	var opciones: Array[Control] = menu._controles_foco(menu._panel_opciones)
	_comprobar(opciones.size() >= 8, "Opciones incluye controles navegables de ajustes y remapeo")
	_probar_cadena(opciones, "opciones")
	_comprobar(
		menu.get_viewport().gui_get_focus_owner() == opciones[0],
		"abrir Opciones enfoca el primer control disponible",
	)

	menu._mostrar_sellos()
	await process_frame
	menu._mostrar_principal(menu._sellos)
	await process_frame
	_comprobar(
		menu.get_viewport().gui_get_focus_owner() == menu._sellos,
		"volver desde Sellos restaura el lanzador Sellos",
	)

	menu._mostrar_historial()
	await process_frame
	menu._mostrar_principal(menu._historial_boton)
	await process_frame
	_comprobar(
		menu.get_viewport().gui_get_focus_owner() == menu._historial_boton,
		"volver desde Historial restaura el lanzador Historial",
	)

	menu._fondo.visible = false
	_terminar()


func _probar_cadena(controles: Array[Control], nombre: String) -> void:
	if controles.is_empty():
		return
	for indice in controles.size():
		var actual := controles[indice]
		var siguiente := controles[(indice + 1) % controles.size()]
		var anterior := controles[(indice - 1 + controles.size()) % controles.size()]
		_comprobar(
			actual.get_node_or_null(actual.focus_neighbor_bottom) == siguiente,
			"%s: abajo avanza al siguiente control" % nombre,
		)
		_comprobar(
			actual.get_node_or_null(actual.focus_neighbor_top) == anterior,
			"%s: arriba vuelve al control anterior" % nombre,
		)
	_comprobar(
		controles[-1].get_node_or_null(controles[-1].focus_neighbor_bottom) == controles[0],
		"%s: la navegación inferior envuelve al inicio" % nombre,
	)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO MenuGlobalFoco113: " + nombre)


func _terminar() -> void:
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)
