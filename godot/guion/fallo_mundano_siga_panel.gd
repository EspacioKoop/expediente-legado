## Presentación inline de una incidencia mundana del OS98 (#668).
##
## No es modal, no anima ni captura teclado. Al mostrarse mueve el foco al botón
## de cierre y al cerrarse intenta devolverlo al control que lo tenía antes.
class_name FalloMundanoSigaPanel
extends VBoxContainer

signal cerrado

var _titulo: Label
var _detalle: Label
var _cerrar_boton: Button
var _foco_previo: Control


func _ready() -> void:
	name = "IncidenciaMundana"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visible = false

	_titulo = Label.new()
	_titulo.name = "Titulo"
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_titulo)

	_detalle = Label.new()
	_detalle.name = "Detalle"
	_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_detalle)

	_cerrar_boton = Button.new()
	_cerrar_boton.name = "Cerrar"
	_cerrar_boton.text = "Cerrar aviso"
	_cerrar_boton.focus_mode = Control.FOCUS_ALL
	_cerrar_boton.pressed.connect(cerrar)
	add_child(_cerrar_boton)


func presentar(id: String, evento: String) -> bool:
	var incidencia := FallosMundanosOs98.evaluar(id, {"evento": evento})
	if not bool(incidencia.get("activo", false)):
		cerrar(false)
		return false

	var foco := get_viewport().gui_get_focus_owner()
	_foco_previo = foco as Control if foco is Control else null
	_titulo.text = "Incidencia normal · %s" % id.replace("_", " ")
	_detalle.text = (
		"%s\n\nSolución: %s"
		% [
			String(incidencia.get("causa", "")),
			String(incidencia.get("resolucion", "")),
		]
	)
	visible = true
	_cerrar_boton.grab_focus.call_deferred()
	return true


func cerrar(devolver_foco: bool = true) -> void:
	visible = false
	if devolver_foco and is_instance_valid(_foco_previo) and _foco_previo.is_visible_in_tree():
		_foco_previo.grab_focus.call_deferred()
	_foco_previo = null
	cerrado.emit()
