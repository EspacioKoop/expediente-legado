## Identidad visual por expediente (#431).
##
## Conserva el visor documental y sus mecánicas; esta capa solo hace que cada
## carpeta tenga una firma visual propia. El catálogo decide icono, código y
## acento, de modo que añadir un expediente no exige otra rama de UI.
extends "res://guion/visor_anexos_app.gd"

const RUTA_IDENTIDADES := "res://datos/identidad_expedientes.json"
const IDENTIDAD_FALLBACK := {
	"codigo": "SIGA",
	"acento": "#4B6284",
	"icono": "",
}

var _identidades: Dictionary = {}
var _texturas_identidad: Dictionary = {}
var _banda_identidad: PanelContainer
var _icono_identidad: TextureRect
var _titulo_identidad: Label
var _codigo_identidad: Label


func _columna_documento() -> Control:
	var columna: Control = super._columna_documento()

	_banda_identidad = PanelContainer.new()
	_banda_identidad.custom_minimum_size.y = 58.0

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)

	_icono_identidad = TextureRect.new()
	_icono_identidad.custom_minimum_size = Vector2(42, 42)
	_icono_identidad.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_icono_identidad.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fila.add_child(_icono_identidad)

	var textos := VBoxContainer.new()
	_titulo_identidad = _etiqueta("", EstiloSiga.NEGRO)
	_titulo_identidad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_codigo_identidad = _etiqueta("", EstiloSiga.GRIS_OSCURO)
	textos.add_child(_titulo_identidad)
	textos.add_child(_codigo_identidad)
	fila.add_child(textos)

	_banda_identidad.add_child(fila)
	columna.add_child(_banda_identidad)
	columna.move_child(_banda_identidad, 0)
	_actualizar_identidad()
	return columna


func _refrescar_archivo() -> void:
	super._refrescar_archivo()
	_asegurar_identidades()
	if _archivo == null:
		return
	var cantidad := mini(contenido.casos.size(), _archivo.get_item_count())
	for i in cantidad:
		var ficha: Dictionary = contenido.casos[i]
		var textura := _textura_de(_identidad_de(String(ficha.get("id", ""))))
		if textura != null:
			_archivo.set_item_icon(i, textura)


func _al_elegir_caso(indice: int) -> void:
	super._al_elegir_caso(indice)
	_actualizar_identidad()


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


func _textura_de(identidad: Dictionary) -> Texture2D:
	var ruta := String(identidad.get("icono", ""))
	if ruta.is_empty() or not ResourceLoader.exists(ruta):
		return null
	if not _texturas_identidad.has(ruta):
		_texturas_identidad[ruta] = load(ruta)
	return _texturas_identidad[ruta] as Texture2D


func _actualizar_identidad() -> void:
	if _banda_identidad == null or caso.is_empty():
		return
	var identidad := _identidad_de(String(caso.get("id", "")))
	var acento := Color.from_string(
		String(identidad.get("acento", IDENTIDAD_FALLBACK["acento"])), EstiloSiga.AZUL_TITULO
	)
	_banda_identidad.add_theme_stylebox_override("panel", _estilo_identidad(acento))

	_icono_identidad.texture = _textura_de(identidad)
	_icono_identidad.visible = _icono_identidad.texture != null
	_titulo_identidad.text = tr(String(caso.get("titulo", "")))

	var anio := "--"
	if caso.get("anioSuceso") != null:
		anio = str(int(caso["anioSuceso"]))
	_codigo_identidad.text = "%s   ·   %s" % [String(identidad.get("codigo", "SIGA")), anio]


func _estilo_identidad(acento: Color) -> StyleBoxFlat:
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
