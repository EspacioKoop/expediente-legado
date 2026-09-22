## Lenguaje visual semántico de las superficies del HUD (#397).
##
## HUDLayer decide qué superficie gana la atención; este módulo decide cómo se
## distingue cada rol sin convertir el árbitro en un tema monolítico. La
## diferencia no depende solo del color: tutorial y diálogo también ocupan
## posiciones distintas y usan jerarquías tipográficas diferentes.
class_name HUDEstilo
extends RefCounted

const FONDO_TUTORIAL := Color("e8edf7")
const TEXTO_TUTORIAL := Color("111111")
const TITULO_TUTORIAL := Color("000080")

const FONDO_DIALOGO := Color("10151f")
const TEXTO_DIALOGO := Color("f4f4f0")
const HABLANTE_DIALOGO := Color("b8d4ff")
const BORDE_DIALOGO := Color("6d7f99")


static func caja_tutorial() -> StyleBoxFlat:
	return EstiloSiga.caja_saliente(FONDO_TUTORIAL)


static func caja_dialogo() -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = FONDO_DIALOGO
	caja.border_color = BORDE_DIALOGO
	caja.set_border_width_all(1)
	caja.set_corner_radius_all(0)
	caja.content_margin_left = 12.0
	caja.content_margin_top = 8.0
	caja.content_margin_right = 12.0
	caja.content_margin_bottom = 8.0
	caja.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	caja.shadow_size = 3
	caja.shadow_offset = Vector2(0, 2)
	return caja
