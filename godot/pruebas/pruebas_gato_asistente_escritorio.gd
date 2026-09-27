extends SceneTree

## Regresión de #787/#802: el bocadillo sigue siendo contenido de SIGA, pero
## el avatar se promueve al shell OS98 y no desaparece al minimizar la app.

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var techo := Control.new()
	techo.name = "TechoPrueba"
	techo.size = Vector2(1024, 768)
	root.add_child(techo)

	var escritorio := EscritorioSiga.new()
	techo.add_child(escritorio)
	await process_frame

	var visor := Control.new()
	visor.name = "Visor"
	visor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var conjunto := HBoxContainer.new()
	conjunto.name = "AsistenteSiga"
	visor.add_child(conjunto)
	var avatar := GatoAsistente2D.new()
	avatar.name = "GatoAsistente"
	avatar.configurar(GatoAyuda.COMPLETA, false)
	conjunto.add_child(avatar)
	await process_frame
	_comprobar(avatar.get_parent() == conjunto, "Prometeo nace junto al bocadillo de SIGA")

	escritorio.adoptar_aplicacion(
		"siga-98", "SIGA-98", visor, func() -> Control: return Control.new()
	)
	await process_frame

	_comprobar(escritorio._ventanas.has("siga-98"), "OS98 adopta SIGA como ventana")
	var panel: Control = escritorio._ventanas["siga-98"]["panel"]
	_comprobar(panel.is_ancestor_of(conjunto), "el bocadillo viaja dentro de Ventana_siga-98")
	_comprobar(panel.is_ancestor_of(avatar), "el avatar empieza dentro de SIGA antes del handoff")

	avatar.reparent(escritorio, false)
	avatar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	avatar.position = Vector2(760, 520)
	avatar.z_index = GatoAsistentePaseoOs98.Z_ASISTENTE

	var paseo := GatoAsistentePaseoOs98.new()
	escritorio.add_child(paseo)
	paseo.configurar(avatar, escritorio, false)
	await process_frame

	_comprobar(avatar.get_parent() == escritorio, "Prometeo pasa a pertenecer al shell OS98")
	_comprobar(panel.is_ancestor_of(conjunto), "el texto contextual permanece dentro de SIGA")
	_comprobar(not panel.is_ancestor_of(avatar), "el avatar ya no depende de la ventana SIGA")

	escritorio.minimizar("siga-98")
	await process_frame
	_comprobar(not conjunto.is_visible_in_tree(), "el bocadillo se oculta al minimizar SIGA")
	_comprobar(avatar.is_visible_in_tree(), "Prometeo sigue visible al minimizar SIGA")

	var destino_a := paseo.siguiente_destino()
	var destino_b := paseo.siguiente_destino()
	_comprobar(destino_a != destino_b, "el paseo alterna destinos intermedios")
	_comprobar(
		destino_a.x >= 0.0 and destino_a.x + avatar.size.x <= escritorio.size.x,
		"el paseo mantiene el avatar dentro del ancho del escritorio",
	)
	var barra := escritorio.get_node_or_null("BarraInferior") as Control
	_comprobar(
		barra != null and destino_a.y + avatar.size.y <= barra.position.y,
		"el paseo respeta la barra de tareas",
	)

	paseo.configurar(avatar, escritorio, true)
	_comprobar(not paseo.is_processing(), "reducción de movimiento detiene el paseo")

	escritorio.restaurar("siga-98")
	await process_frame
	_comprobar(conjunto.is_visible_in_tree(), "el bocadillo reaparece al restaurar SIGA")
	_comprobar(avatar.is_visible_in_tree(), "el avatar sigue siendo presencia del shell")

	avatar.configurar(GatoAyuda.COMPLETA, false)
	avatar._tiempo = 7.60
	_comprobar(
		avatar._frame_actual() == GatoAsistente2D.FRAME_LOAF,
		"la secuencia usa la pose loaf como in-between",
	)
	avatar._tiempo = 10.90
	_comprobar(
		avatar._frame_actual() == GatoAsistente2D.FRAME_ESPALDA,
		"la secuencia usa espalda durante el giro",
	)
	avatar._tiempo = 2.75
	_comprobar(
		avatar._frame_actual() == GatoAsistente2D.FRAME_PARPADEO,
		"la secuencia conserva microparpadeos",
	)
	avatar.configurar(GatoAyuda.COMPLETA, true)
	avatar._tiempo = 7.60
	_comprobar(
		avatar._frame_actual() == GatoAsistente2D.FRAME_IDLE,
		"reducción de movimiento congela también los nuevos in-betweens",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	techo.queue_free()
	await process_frame
	quit(1 if _fallos else 0)


func _comprobar(actual: bool, nombre: String) -> void:
	if actual:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO gato asistente OS98: %s" % nombre)
