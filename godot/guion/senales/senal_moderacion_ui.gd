class_name SenalModeracionUI
extends CanvasLayer

## Acciones locales cerradas sobre una señal visible de #377.
## No contiene texto libre ni modifica Partida: solo solicita ocultar/reportar
## el event_id que ya ha pasado la validación de SenalServicio.

signal ocultar_solicitado(event_id: String)
signal reportar_solicitado(event_id: String)
signal cerrado

const TEXTO_TITULO := "Señal de otro jugador"
const TEXTO_OCULTAR := "Ocultar"
const TEXTO_REPORTAR := "Reportar y ocultar"
const TEXTO_CANCELAR := "Cancelar"

var _event_id := ""
var _centro: CenterContainer
var _texto: Label
var _boton_ocultar: Button
var _abierto := false


func _ready() -> void:
	layer = 81
	_construir_ui()


func abrir(event_id: String, texto: String = "") -> Dictionary:
	var normalizado := event_id.strip_edges()
	if normalizado.is_empty():
		return {"ok": false, "status": "invalid_event_id"}
	_event_id = normalizado
	_texto.text = texto.strip_edges()
	_texto.visible = not _texto.text.is_empty()
	_centro.visible = true
	_abierto = true
	if _boton_ocultar != null:
		_boton_ocultar.grab_focus()
	return {"ok": true, "status": "open"}


func _unhandled_input(event: InputEvent) -> void:
	if _abierto and event.is_action_pressed("ui_cancel"):
		cerrar()
		get_viewport().set_input_as_handled()


func cerrar() -> void:
	if not _abierto:
		return
	_abierto = false
	_event_id = ""
	if _centro != null:
		_centro.visible = false
	cerrado.emit()


func solicitar_ocultar() -> Dictionary:
	if not _abierto or _event_id.is_empty():
		return {"ok": false, "status": "closed"}
	ocultar_solicitado.emit(_event_id)
	return {"ok": true, "status": "requested"}


func solicitar_reportar() -> Dictionary:
	if not _abierto or _event_id.is_empty():
		return {"ok": false, "status": "closed"}
	reportar_solicitado.emit(_event_id)
	return {"ok": true, "status": "requested"}


func estado() -> Dictionary:
	return {
		"abierto": _abierto,
		"event_id": _event_id,
		"texto": _texto.text if _texto != null else "",
	}


func _construir_ui() -> void:
	_centro = CenterContainer.new()
	_centro.name = "Centro"
	_centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_centro.visible = false
	add_child(_centro)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(360.0, 0.0)
	_centro.add_child(panel)

	var lista := VBoxContainer.new()
	lista.name = "Acciones"
	panel.add_child(lista)

	var titulo := Label.new()
	titulo.name = "Titulo"
	titulo.text = _traducir("signal.moderate.title", TEXTO_TITULO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lista.add_child(titulo)

	_texto = Label.new()
	_texto.name = "TextoSenal"
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(_texto)

	_boton_ocultar = Button.new()
	_boton_ocultar.name = "Ocultar"
	_boton_ocultar.text = _traducir("signal.moderate.hide", TEXTO_OCULTAR)
	_boton_ocultar.pressed.connect(solicitar_ocultar)
	lista.add_child(_boton_ocultar)

	var reportar := Button.new()
	reportar.name = "Reportar"
	reportar.text = _traducir("signal.moderate.report", TEXTO_REPORTAR)
	reportar.pressed.connect(solicitar_reportar)
	lista.add_child(reportar)

	var cancelar := Button.new()
	cancelar.name = "Cancelar"
	cancelar.text = _traducir("signal.moderate.cancel", TEXTO_CANCELAR)
	cancelar.pressed.connect(cerrar)
	lista.add_child(cancelar)


func _traducir(clave: String, fallback: String) -> String:
	var traducido := TranslationServer.translate(clave)
	if traducido == clave:
		return fallback
	return traducido
