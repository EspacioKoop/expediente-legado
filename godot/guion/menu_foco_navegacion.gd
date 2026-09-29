## Navegación de foco reutilizable para menús (#113).
##
## Mantiene un orden vertical y circular estable para teclado y mando incluso
## cuando la geometría final del panel contiene columnas o scroll.
extends RefCounted


static func controles(panel: Control) -> Array[Control]:
	var resultado: Array[Control] = []
	for nodo in panel.find_children("*", "Control", true, false):
		var control := nodo as Control
		if control == null or control.focus_mode == Control.FOCUS_NONE:
			continue
		if not (control is BaseButton or control is HSlider):
			continue
		if control is BaseButton and (control as BaseButton).disabled:
			continue
		if not control.is_visible_in_tree():
			continue
		resultado.append(control)
	return resultado


static func encadenar(panel: Control) -> Array[Control]:
	var resultado := controles(panel)
	if resultado.is_empty():
		return resultado
	for indice in resultado.size():
		var actual := resultado[indice]
		var anterior := resultado[(indice - 1 + resultado.size()) % resultado.size()]
		var siguiente := resultado[(indice + 1) % resultado.size()]
		actual.focus_neighbor_top = actual.get_path_to(anterior)
		actual.focus_previous = actual.get_path_to(anterior)
		actual.focus_neighbor_bottom = actual.get_path_to(siguiente)
		actual.focus_next = actual.get_path_to(siguiente)
	return resultado


static func enfocar_primero(panel: Control, respaldo: Control) -> void:
	var resultado := encadenar(panel)
	if not resultado.is_empty():
		resultado[0].grab_focus()
	elif is_instance_valid(respaldo):
		respaldo.grab_focus()
