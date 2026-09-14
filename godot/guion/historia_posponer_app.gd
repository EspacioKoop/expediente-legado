## Capa de UI para posponer y madurar una decisión política (#287).
##
## `Historias.postergar()` conserva la decisión pendiente. `HISTORIA_CONTEXTO`
## separa el hallazgo de la votación hasta que exista contexto real nuevo.
extends "res://guion/historia_app.gd"

const HISTORIA_CONTEXTO := preload("res://guion/historia_contexto.gd")
const RUTA_TEXTOS := "res://datos/historia_posponer_textos.json"
const RUTA_TEXTOS_CONTEXTO := "res://datos/historia_contexto_textos.json"

var _posponer: Button
var _contexto_aviso: Label
var _textos_ui: Dictionary = {}
var _textos_contexto: Dictionary = {}


func _mostrar() -> void:
	super._mostrar()
	_asegurar_boton_posponer()
	_asegurar_aviso_contexto()
	var vista := _historias.vista(partida.estado, carta_id)
	var estado_vista := String(vista.get("estado", ""))
	var pendiente := estado_vista == "pendiente" or estado_vista == "pospuesta"

	# Solo una historia pendiente nueva fija el punto de partida. Las partidas
	# antiguas ya pospuestas carecen de instantánea y siguen siendo decidibles.
	if (
		estado_vista == "pendiente"
		and not HISTORIA_CONTEXTO.tiene_registro(partida.estado, carta_id)
	):
		if HISTORIA_CONTEXTO.registrar(partida.estado, carta_id):
			_guardar()

	var contexto_listo := not pendiente or HISTORIA_CONTEXTO.maduro(partida.estado, carta_id)
	_aplicar_contexto(pendiente, contexto_listo)
	_posponer.visible = pendiente
	_posponer.disabled = _sin_guardar
	_enfocar.call_deferred()


func _asegurar_boton_posponer() -> void:
	if _posponer != null:
		return
	_posponer = Button.new()
	_posponer.text = _texto_ui("boton")
	_posponer.tooltip_text = _texto_ui("tooltip")
	_posponer.pressed.connect(_posponer_decision)
	var relato := _opciones.get_parent()
	relato.add_child(_posponer)
	relato.move_child(_posponer, _opciones.get_index() + 1)


func _asegurar_aviso_contexto() -> void:
	if _contexto_aviso != null:
		return
	_contexto_aviso = _linea()
	_contexto_aviso.text = _texto_contexto("pendiente")
	_contexto_aviso.tooltip_text = _texto_contexto("tooltip")
	var relato := _opciones.get_parent()
	relato.add_child(_contexto_aviso)
	relato.move_child(_contexto_aviso, _opciones.get_index())


func _aplicar_contexto(pendiente: bool, contexto_listo: bool) -> void:
	var mostrar_opciones := not pendiente or contexto_listo
	for nodo in _opciones.get_children():
		var boton := nodo as Button
		if boton != null:
			boton.visible = mostrar_opciones
			boton.disabled = _sin_guardar or not mostrar_opciones
	_contexto_aviso.visible = pendiente and not contexto_listo


func _texto_ui(clave: String) -> String:
	if _textos_ui.is_empty():
		var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
		if datos is Dictionary:
			_textos_ui = datos
	return String(_textos_ui.get(clave, ""))


func _texto_contexto(clave: String) -> String:
	if _textos_contexto.is_empty():
		var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS_CONTEXTO))
		if datos is Dictionary:
			_textos_contexto = datos
	return String(_textos_contexto.get(clave, ""))


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
	var botones: Array[Node] = []
	for nodo in _opciones.get_children():
		var opcion := nodo as Button
		if opcion != null and opcion.visible and not opcion.disabled:
			botones.append(opcion)
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
