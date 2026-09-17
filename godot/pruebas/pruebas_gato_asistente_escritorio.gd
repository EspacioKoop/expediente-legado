extends SceneTree

## Regresión de #802: el asistente forma parte del contenido adoptado por OS98.
## Si vuelve a montarse como hermano del Visor en el CanvasLayer, el escritorio
## puede dibujarse por encima y Prometeo desaparece aunque el nodo siga vivo.

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
	var asistente := Control.new()
	asistente.name = "AsistenteSiga"
	visor.add_child(asistente)
	_comprobar(asistente.get_parent() == visor, "Prometeo nace dentro del Visor")

	escritorio.adoptar_aplicacion(
		"siga-98", "SIGA-98", visor, func() -> Control: return Control.new()
	)
	await process_frame

	_comprobar(escritorio._ventanas.has("siga-98"), "OS98 adopta SIGA como ventana")
	var panel: Control = escritorio._ventanas["siga-98"]["panel"]
	_comprobar(
		panel.is_ancestor_of(asistente),
		"Prometeo viaja con el Visor dentro de Ventana_siga-98",
	)
	_comprobar(asistente.is_visible_in_tree(), "Prometeo queda visible tras envolver SIGA")

	escritorio.minimizar("siga-98")
	await process_frame
	_comprobar(not asistente.is_visible_in_tree(), "Prometeo se oculta al minimizar SIGA")

	escritorio.restaurar("siga-98")
	await process_frame
	_comprobar(asistente.is_visible_in_tree(), "Prometeo reaparece al restaurar SIGA")

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
