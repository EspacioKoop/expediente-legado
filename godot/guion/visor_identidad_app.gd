## Identidad visual por expediente (#431).
##
## Es un componente de presentación, no otra rama del visor. `visor_anexos_app`
## lo monta sobre la costura estable del visor y le entrega solo controles y
## datos: aquí no existen pistas, acciones, acusaciones ni guardado.
extends RefCounted

const RUTA_IDENTIDADES := "res://datos/identidad_expedientes.json"
const IDENTIDAD_FALLBACK := {
	"codigo": "SIGA",
	"acento": "#4B6284",
	"icono": "",
	"lamina": "",
	"sujeto": "",
}

var _identidades: Dictionary = {}
var _texturas_identidad: Dictionary = {}
var _banda: PanelContainer
var _icono: TextureRect
var _titulo: Label
var _codigo: Label
var _portada_fila: HBoxContainer
var _sujeto: TextureRect
var _portada: TextureRect


func montar(columna: Control, caso: Dictionary) -> void:
	if _banda != null:
		actualizar(caso)
		return

	_banda = PanelContainer.new()
	_banda.custom_minimum_size.y = 58.0

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)

	_icono = TextureRect.new()
	_icono.custom_minimum_size = Vector2(42, 42)
	_icono.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fila.add_child(_icono)

	var textos := VBoxContainer.new()
	_titulo = _etiqueta("", EstiloSiga.NEGRO)
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_codigo = _etiqueta("", EstiloSiga.GRIS_TEXTO)
	textos.add_child(_titulo)
	textos.add_child(_codigo)
	fila.add_child(textos)

	_banda.add_child(fila)
	columna.add_child(_banda)
	columna.move_child(_banda, 0)

	_portada_fila = HBoxContainer.new()
	_portada_fila.custom_minimum_size.y = 124.0
	_portada_fila.add_theme_constant_override("separation", 8)

	_sujeto = TextureRect.new()
	_sujeto.custom_minimum_size = Vector2(88, 124)
	_sujeto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sujeto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sujeto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portada_fila.add_child(_sujeto)

	_portada = TextureRect.new()
	_portada.custom_minimum_size = Vector2(0, 124)
	_portada.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_portada.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portada.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portada.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portada_fila.add_child(_portada)

	columna.add_child(_portada_fila)
	columna.move_child(_portada_fila, 1)
	actualizar(caso)


func aplicar_archivo(archivo: ItemList, casos: Array) -> void:
	_asegurar_identidades()
	if archivo == null:
		return
	var cantidad := mini(casos.size(), archivo.get_item_count())
	for i in cantidad:
		var ficha: Dictionary = casos[i]
		var textura := _textura_de(_identidad_de(String(ficha.get("id", ""))), "icono")
		if textura != null:
			archivo.set_item_icon(i, textura)


func actualizar(caso: Dictionary) -> void:
	if _banda == null or caso.is_empty():
		return
	var identidad := _identidad_de(String(caso.get("id", "")))
	var acento := Color.from_string(
		String(identidad.get("acento", IDENTIDAD_FALLBACK["acento"])), EstiloSiga.AZUL_TITULO
	)
	_banda.add_theme_stylebox_override("panel", _estilo(acento))

	_icono.texture = _textura_de(identidad, "icono")
	_icono.visible = _icono.texture != null
	_titulo.text = tr(String(caso.get("titulo", "")))

	var anio := "--"
	if caso.get("anioSuceso") != null:
		anio = str(int(caso["anioSuceso"]))
	_codigo.text = "%s   ·   %s" % [String(identidad.get("codigo", "SIGA")), anio]

	if _sujeto != null:
		_sujeto.texture = _textura_de(identidad, "sujeto")
		_sujeto.visible = _sujeto.texture != null
	if _portada != null:
		_portada.texture = _textura_de(identidad, "lamina")
		_portada.visible = _portada.texture != null
	if _portada_fila != null:
		_portada_fila.visible = _hay_portada()


func mostrar_portada(visible: bool) -> void:
	if _portada_fila != null:
		_portada_fila.visible = visible and _hay_portada()


func _hay_portada() -> bool:
	return (
		(_sujeto != null and _sujeto.texture != null)
		or (_portada != null and _portada.texture != null)
	)


func _asegurar_identidades() -> void:
	if not _identidades.is_empty():
		return
	if not FileAccess.file_exists(RUTA_IDENTIDADES):
		return
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_IDENTIDADES))
	if datos is Dictionary:
		_identidades = datos


func _identidad_de(caso_id: String) -> Dictionary:
	_asegurar_identidades()
	var dato: Variant = _identidades.get(caso_id, IDENTIDAD_FALLBACK)
	if dato is Dictionary:
		return dato
	return IDENTIDAD_FALLBACK


func _textura_de(identidad: Dictionary, campo: String) -> Texture2D:
	var ruta := String(identidad.get(campo, ""))
	if ruta.is_empty() or not ResourceLoader.exists(ruta):
		return null
	if not _texturas_identidad.has(ruta):
		_texturas_identidad[ruta] = load(ruta)
	return _texturas_identidad[ruta] as Texture2D


func _etiqueta(texto: String, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_font_size_override("font_size", 14)
	return etiqueta


func _estilo(acento: Color) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = acento.lightened(0.82)
	caja.border_width_left = 5
	caja.border_width_top = 1
	caja.border_width_right = 1
	caja.border_width_bottom = 1
	caja.border_color = acento
	caja.content_margin_left = 8
	caja.content_margin_right = 8
	caja.content_margin_top = 6
	caja.content_margin_bottom = 6
	caja.set_corner_radius_all(0)
	return caja
