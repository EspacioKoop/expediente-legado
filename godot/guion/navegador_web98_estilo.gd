## Tema visual local del Navegador Web98 (#791).
## Mantiene la identidad fuera de NavegadorSiga para no mezclar presentación con navegación.
extends RefCounted

const FONDO_CROMO := Color("#d7d1c4")
const FONDO_CROMO_HOVER := Color("#eee9de")
const FONDO_CROMO_PULSADO := Color("#c2bbad")
const FONDO_DIRECCION := Color("#fff7d6")
const FONDO_PAGINA := Color("#fbfaf2")
const FONDO_LATERAL := Color("#e5eaf0")
const BORDE_WEB98 := Color("#6f6a5e")
const FOCO_WEB98 := Color("#315d91")
const TINTA_WEB98 := Color("#27251f")
const TINTA_SECUNDARIA_WEB98 := Color("#52606e")


static func estilizar_boton_cromo(boton: Button, nombre: String = "") -> void:
	if not nombre.is_empty():
		boton.name = nombre
	boton.add_theme_color_override("font_color", TINTA_WEB98)
	boton.add_theme_color_override("font_focus_color", TINTA_WEB98)
	boton.add_theme_stylebox_override(
		"normal", caja_web98(FONDO_CROMO, BORDE_WEB98, 1, 1, 7.0, 4.0)
	)
	boton.add_theme_stylebox_override(
		"hover", caja_web98(FONDO_CROMO_HOVER, BORDE_WEB98, 1, 1, 7.0, 4.0)
	)
	boton.add_theme_stylebox_override(
		"pressed", caja_web98(FONDO_CROMO_PULSADO, BORDE_WEB98, 1, 1, 7.0, 4.0)
	)
	boton.add_theme_stylebox_override(
		"focus", caja_web98(FONDO_CROMO_HOVER, FOCO_WEB98, 2, 1, 6.0, 3.0)
	)


static func estilizar_linea_web98(linea: LineEdit) -> void:
	linea.add_theme_color_override("font_color", TINTA_WEB98)
	linea.add_theme_color_override("caret_color", FOCO_WEB98)
	linea.add_theme_color_override("selection_color", Color("#b8cce5"))
	linea.add_theme_stylebox_override(
		"normal", caja_web98(FONDO_DIRECCION, BORDE_WEB98, 1, 1, 7.0, 4.0)
	)
	linea.add_theme_stylebox_override(
		"focus", caja_web98(FONDO_DIRECCION, FOCO_WEB98, 2, 1, 6.0, 3.0)
	)


static func estilizar_lista_web98(lista: ItemList, fondo: Color) -> void:
	lista.add_theme_color_override("font_color", TINTA_WEB98)
	lista.add_theme_color_override("font_selected_color", Color("#f7fbff"))
	lista.add_theme_stylebox_override("panel", caja_web98(fondo, BORDE_WEB98, 1, 1, 6.0, 5.0))
	lista.add_theme_stylebox_override("focus", caja_web98(fondo, FOCO_WEB98, 2, 1, 5.0, 4.0))


static func estilizar_pagina(pagina: RichTextLabel) -> void:
	pagina.add_theme_color_override("default_color", TINTA_WEB98)
	pagina.add_theme_color_override("selection_color", Color("#b8cce5"))
	pagina.add_theme_stylebox_override(
		"normal", caja_web98(FONDO_PAGINA, BORDE_WEB98, 1, 1, 9.0, 7.0)
	)
	pagina.add_theme_stylebox_override(
		"focus", caja_web98(FONDO_PAGINA, FOCO_WEB98, 2, 1, 8.0, 6.0)
	)


static func caja_web98(
	fondo: Color,
	borde: Color,
	ancho: int,
	radio: int,
	margen_horizontal: float,
	margen_vertical: float
) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = borde
	caja.border_width_left = ancho
	caja.border_width_top = ancho
	caja.border_width_right = ancho
	caja.border_width_bottom = ancho
	caja.corner_radius_top_left = radio
	caja.corner_radius_top_right = radio
	caja.corner_radius_bottom_left = radio
	caja.corner_radius_bottom_right = radio
	caja.content_margin_left = margen_horizontal
	caja.content_margin_top = margen_vertical
	caja.content_margin_right = margen_horizontal
	caja.content_margin_bottom = margen_vertical
	return caja
