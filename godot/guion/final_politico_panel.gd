## Epílogo político accesible para el clímax de Hastur (#1103 / #925).
##
## Presenta hechos de la vuelta antes de sintetizar el patrón. No anima ni
## bloquea el teclado: el botón recibe foco y la acción semántica cancelar
## también permite continuar.
class_name FinalPoliticoPanel
extends Control

signal continuar_solicitado

const RUTA_TEXTOS := "res://datos/final_politico_textos.json"

var _resumen: Dictionary = {}
var _textos: Dictionary = {}
var _boton: Button


func configurar(resumen: Dictionary) -> void:
	_resumen = resumen.duplicate(true)


func _ready() -> void:
	_textos = _cargar_textos()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_construir()


func bloquear(bloqueado: bool) -> void:
	if is_instance_valid(_boton):
		_boton.disabled = bloqueado


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancelar"):
		get_viewport().set_input_as_handled()
		continuar_solicitado.emit()


static func _cargar_textos() -> Dictionary:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
	return (datos as Dictionary).duplicate(true) if datos is Dictionary else {}


func _t(clave: String, fallback: String = "") -> String:
	return String(_textos.get(clave, fallback if not fallback.is_empty() else clave))


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.035, 0.03, 0.05, 0.94)
	add_child(fondo)

	var caja := VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	caja.position = Vector2(-380, -260)
	caja.custom_minimum_size = Vector2(760, 520)
	caja.add_theme_constant_override("separation", 12)
	add_child(caja)

	var ribbon := _etiqueta(_t("ribbon"))
	ribbon.name = "Ribbon"
	caja.add_child(ribbon)

	var patron := String(_resumen.get("patron", FinalPolitico.PATRON_SIN_REGISTRO))
	var titulo := _etiqueta(_t("titulo_%s" % patron))
	titulo.name = "Titulo"
	titulo.add_theme_font_size_override("font_size", 24)
	caja.add_child(titulo)

	var cuerpo := _etiqueta(_t("texto_%s" % patron))
	cuerpo.name = "Sintesis"
	caja.add_child(cuerpo)

	var dominantes: Array = _resumen.get("dominantes", [])
	var lectura := _etiqueta(_texto_dominantes(dominantes))
	lectura.name = "Dominantes"
	caja.add_child(lectura)

	var hechos_titulo := _etiqueta(_t("hechos_titulo"))
	hechos_titulo.name = "HechosTitulo"
	caja.add_child(hechos_titulo)

	var ejemplos: Array = _resumen.get("ejemplos", [])
	if ejemplos.is_empty():
		caja.add_child(_etiqueta(_t("hechos_vacio")))
	else:
		for ejemplo in ejemplos:
			caja.add_child(_etiqueta(_texto_ejemplo(ejemplo)))

	_boton = Button.new()
	_boton.name = "Continuar"
	_boton.theme = EstiloSiga.tema()
	_boton.text = _t("continuar")
	_boton.accessibility_name = _boton.text
	_boton.pressed.connect(func(): continuar_solicitado.emit())
	caja.add_child(_boton)
	_boton.grab_focus()


func _texto_dominantes(dominantes: Array) -> String:
	if dominantes.is_empty():
		return _t("dominantes_vacio")
	var nombres := []
	for eje in dominantes:
		nombres.append(_nombre_eje(String(eje)))
	if nombres.size() == 1:
		return _t("dominante_uno") % nombres[0]
	return _t("dominante_plural") % ", ".join(nombres)


func _texto_ejemplo(ejemplo: Dictionary) -> String:
	var contexto := String(ejemplo.get("contexto", "")).replace("-", " ").capitalize()
	var eje := _nombre_eje(String(ejemplo.get("eje", "")))
	return _t("hecho_formato") % [contexto, eje]


func _nombre_eje(eje: String) -> String:
	var ejes = _textos.get("ejes", {})
	if ejes is Dictionary:
		return String((ejes as Dictionary).get(eje, eje))
	return eje


func _etiqueta(texto: String) -> Label:
	var marca := Label.new()
	marca.text = texto
	marca.theme = EstiloSiga.tema()
	marca.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	marca.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marca.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	marca.add_theme_color_override("font_outline_color", EstiloSiga.NEGRO)
	marca.add_theme_constant_override("outline_size", 4)
	return marca
