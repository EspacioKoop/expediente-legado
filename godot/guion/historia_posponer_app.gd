## Capa de UI para posponer una decisión política sin resolverla (#287).
##
## El contrato vive en `Historias.postergar()`. Esta capa solo lo hace visible,
## lo guarda y mantiene la navegación por foco/mando de la ventana existente.
extends "res://guion/historia_app.gd"

var _posponer: Button


func _mostrar() -> void:
	super._mostrar()
	_asegurar_boton_posponer()
	var vista := _historias.vista(partida.estado, carta_id)
	var estado_vista := String(vista.get("estado", ""))
	_posponer.visible = estado_vista == "pendiente" or estado_vista == "pospuesta"
	_posponer.disabled = _sin_guardar
	_enfocar.call_deferred()


func _asegurar_boton_posponer() -> void:
	if _posponer != null:
		return
	_posponer = Button.new()
	_posponer.text = tr("A7_VOLVER")
	_posponer.pressed.connect(_posponer_decision)
	var relato := _opciones.get_parent()
	relato.add_child(_posponer)
	relato.move_child(_posponer, _opciones.get_index() + 1)


func _posponer_decision() -> void:
	if _sin_guardar:
		return
	if not _historias.postergar(partida.estado, carta_id):
		return
	_guardar()
	_posponer.disabled = _sin_guardar
	if not _sin_guardar:
		_cerrar()


func _enfocar() -> void:
	var botones: Array[Node] = _opciones.get_children()
	if _posponer != null and _posponer.visible and not _posponer.disabled:
		botones.append(_posponer)
	if _reintentar.visible:
		botones.append(_reintentar)
	if not _volver.disabled:
		botones.append(_volver)
	for i in botones.size():
		var boton: Control = botones[i]
		var anterior: Control = botones[(i - 1 + botones.size()) % botones.size()]
		var siguiente: Control = botones[(i + 1) % botones.size()]
		boton.focus_neighbor_top = boton.get_path_to(anterior)
		boton.focus_previous = boton.get_path_to(anterior)
		boton.focus_neighbor_bottom = boton.get_path_to(siguiente)
		boton.focus_next = boton.get_path_to(siguiente)
	if not botones.is_empty():
		botones[0].grab_focus()
