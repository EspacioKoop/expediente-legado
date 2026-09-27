class_name SenalCompositorUI
extends CanvasLayer

## Compositor local de #377.
##
## Nunca ofrece un campo de texto: genera botones únicamente a partir del
## catálogo cerrado de SenalVocabulario y vuelve a validar antes de emitir.

signal publicar_solicitada(anchor_id: String, plantilla_id: String, tokens: Array)
signal cerrado

const SenalVocabulario = preload("res://guion/red/senal_vocabulario.gd")

const TEXTO_TITULO := "Dejar señal"
const TEXTO_CANCELAR := "Cancelar"
const TEXTO_ERROR := "No se pudo publicar la señal."
const TEXTO_OFFLINE := "Sin conexión: la señal no se ha enviado."

var _anchor_id := ""
var _conocimiento: Array = []
var _opciones: Array[Dictionary] = []
var _centro: CenterContainer
var _lista: VBoxContainer
var _estado_label: Label
var _abierto := false


func _ready() -> void:
	layer = 80
	_construir_ui()


func abrir(anchor_id: String, conocimiento: Array = []) -> Dictionary:
	if not SenalVocabulario.ANCHORS.has(anchor_id):
		return {"ok": false, "status": "unknown_anchor"}
	_anchor_id = anchor_id
	_conocimiento = conocimiento.duplicate()
	_opciones = _generar_opciones(anchor_id, _conocimiento)
	if _opciones.is_empty():
		return {"ok": false, "status": "no_options"}
	_reconstruir_botones()
	_estado_label.text = ""
	_centro.visible = true
	_abierto = true
	return {"ok": true, "status": "open", "options": _opciones.size()}


func cerrar() -> void:
	if not _abierto:
		return
	_abierto = false
	if _centro != null:
		_centro.visible = false
	cerrado.emit()


func seleccionar_opcion(indice: int) -> Dictionary:
	if not _abierto:
		return {"ok": false, "status": "closed"}
	if indice < 0 or indice >= _opciones.size():
		return {"ok": false, "status": "invalid_option"}
	var opcion: Dictionary = _opciones[indice]
	publicar_solicitada.emit(
		_anchor_id,
		String(opcion["plantilla_id"]),
		(opcion["tokens"] as Array).duplicate(),
	)
	return {"ok": true, "status": "requested"}


func resolver_publicacion(resultado: Dictionary) -> void:
	if bool(resultado.get("ok", false)) and String(resultado.get("status", "")) != "discarded_offline":
		cerrar()
		return
	if _estado_label == null:
		return
	if String(resultado.get("status", "")) == "discarded_offline":
		_estado_label.text = _traducir("signal.compose.offline", TEXTO_OFFLINE)
	else:
		_estado_label.text = _traducir("signal.compose.error", TEXTO_ERROR)


func estado() -> Dictionary:
	var textos: Array[String] = []
	for opcion in _opciones:
		textos.append(String(opcion.get("texto", "")))
	return {
		"abierto": _abierto,
		"anchor_id": _anchor_id,
		"opciones": _opciones.size(),
		"textos": textos,
	}


func opciones() -> Array[Dictionary]:
	return _opciones.duplicate(true)


func _construir_ui() -> void:
	_centro = CenterContainer.new()
	_centro.name = "Centro"
	_centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_centro.visible = false
	add_child(_centro)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(460.0, 0.0)
	_centro.add_child(panel)

	_lista = VBoxContainer.new()
	_lista.name = "Opciones"
	panel.add_child(_lista)

	var titulo := Label.new()
	titulo.name = "Titulo"
	titulo.text = _traducir("signal.compose.title", TEXTO_TITULO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lista.add_child(titulo)

	_estado_label = Label.new()
	_estado_label.name = "Estado"
	_estado_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista.add_child(_estado_label)

	var cancelar := Button.new()
	cancelar.name = "Cancelar"
	cancelar.text = _traducir("signal.compose.cancel", TEXTO_CANCELAR)
	cancelar.pressed.connect(cerrar)
	_lista.add_child(cancelar)


func _reconstruir_botones() -> void:
	for hijo in _lista.get_children():
		if hijo.name.begins_with("Opcion_"):
			_lista.remove_child(hijo)
			hijo.queue_free()

	var cancelar := _lista.get_node("Cancelar")
	var indice := 0
	for opcion in _opciones:
		var boton := Button.new()
		boton.name = "Opcion_%02d" % indice
		boton.text = String(opcion["texto"])
		boton.pressed.connect(seleccionar_opcion.bind(indice))
		_lista.add_child(boton)
		_lista.move_child(boton, cancelar.get_index())
		indice += 1


func _generar_opciones(anchor_id: String, conocimiento: Array) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for plantilla_id in SenalVocabulario.PLANTILLAS:
		var plantilla: Dictionary = SenalVocabulario.PLANTILLAS[plantilla_id]
		var categorias: Array = plantilla["categorias"]
		_combinar_tokens(
			anchor_id,
			String(plantilla_id),
			categorias,
			conocimiento,
			0,
			[],
			salida,
		)
	salida.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return String(a["texto"]) < String(b["texto"])
	)
	return salida


func _combinar_tokens(
	anchor_id: String,
	plantilla_id: String,
	categorias: Array,
	conocimiento: Array,
	indice: int,
	actuales: Array,
	salida: Array[Dictionary],
) -> void:
	if indice >= categorias.size():
		var payload := {
			"anchor_id": anchor_id,
			"plantilla_id": plantilla_id,
			"tokens": actuales.duplicate(),
		}
		var validacion := SenalVocabulario.validar_payload(payload, conocimiento)
		if not validacion["ok"]:
			return
		var renderizado := SenalVocabulario.renderizar(payload, conocimiento)
		if not renderizado["ok"]:
			return
		salida.append(
			{
				"plantilla_id": plantilla_id,
				"tokens": actuales.duplicate(),
				"texto": String(renderizado["text"]),
			}
		)
		return

	for token_id in SenalVocabulario.TOKENS:
		var siguientes := actuales.duplicate()
		siguientes.append(String(token_id))
		_combinar_tokens(
			anchor_id,
			plantilla_id,
			categorias,
			conocimiento,
			indice + 1,
			siguientes,
			salida,
		)


func _traducir(clave: String, fallback: String) -> String:
	var traducido := TranslationServer.translate(clave)
	if traducido == clave:
		return fallback
	return traducido
