## Plano común de epílogo para recordar cómo se vivió (#100).
##
## No decide ni reescribe el final de investigación. Traduce el contrato puro
## de `RemateVida` a una imagen 2D breve que puede anexarse a cualquier final.
## No hay puntuación, moraleja ni texto retrospectivo: casa, ausencia/presencia
## del gato y precariedad se cuentan únicamente mediante la composición.
class_name RemateVidaCinematica
extends RefCounted

const ID := "remate-vida"

const FONDO := Color("26272b")
const SUELO := Color("57514a")
const PARED := Color("82796d")
const PAPEL := Color("d4d0c8")
const OSCURO := Color("3e3e42")
const GATO := Color("5c5147")
const CAJA := Color("876f50")


## Produce un único plano final reutilizable por político/verdadero/despido.
## `estado` se lee, nunca se modifica. Las partidas anteriores a #100 son
## válidas porque `RemateVida.resumir()` ya define valores compatibles.
static func planos_de(estado: Dictionary, vistas: int = 0) -> Array:
	var resumen := RemateVida.resumir(estado)
	var variante := RemateVida.variante(estado)
	return (
		Cinematica
		. resolver(
			[
				{
					"tipo": "2d",
					"segundos": 1.4,
					"figura": _figura(variante, resumen),
					"desde": Vector2.ZERO,
					"hasta": Vector2.ZERO,
				}
			],
			{},
			vistas
		)
	)


static func _figura(variante: String, resumen: Dictionary) -> Array:
	match variante:
		RemateVida.SIN_HOGAR:
			return _sin_hogar(bool(resumen.get("gato_presente", true)))
		RemateVida.PRECARIA:
			return _casa(bool(resumen.get("gato_presente", true)), true)
		_:
			return _casa(bool(resumen.get("gato_presente", true)), false)


## La misma habitación sirve para estable y precaria. La diferencia no se
## explica: en precariedad la mesa queda desnuda y, si el gato se fue, no se
## dibuja. Así su ausencia pesa sin regalarle una cinemática propia.
static func _casa(gato_presente: bool, precaria: bool) -> Array:
	var figura := [
		{"rect": Rect2(-190, -95, 380, 190), "color": FONDO},
		{"rect": Rect2(-190, 48, 380, 47), "color": SUELO},
		{"rect": Rect2(-145, -58, 112, 106), "color": PARED},
		{"rect": Rect2(35, 14, 118, 34), "color": SUELO},
	]
	if not precaria:
		figura.append({"rect": Rect2(52, -2, 82, 12), "color": PAPEL})
	if gato_presente:
		figura.append_array(_gato(Vector2(-4, 25)))
	return figura


## Perder la casa cambia el lugar, no el veredicto. Cajas y bolsa sustituyen a
## la habitación; el gato aparece solo si seguía presente en el estado real.
static func _sin_hogar(gato_presente: bool) -> Array:
	var figura := [
		{"rect": Rect2(-190, -95, 380, 190), "color": FONDO},
		{"rect": Rect2(-190, 48, 380, 47), "color": OSCURO},
		{"rect": Rect2(-120, -5, 92, 53), "color": CAJA},
		{"rect": Rect2(-18, 13, 70, 35), "color": CAJA},
		{"rect": Rect2(83, 1, 42, 47), "color": PAPEL},
	]
	if gato_presente:
		figura.append_array(_gato(Vector2(145, 25)))
	return figura


static func _gato(origen: Vector2) -> Array:
	return [
		{"rect": Rect2(origen.x - 24, origen.y, 48, 24), "color": GATO},
		{"rect": Rect2(origen.x - 12, origen.y - 20, 24, 22), "color": GATO},
		{"rect": Rect2(origen.x - 18, origen.y - 27, 9, 10), "color": GATO},
		{"rect": Rect2(origen.x + 9, origen.y - 27, 9, 10), "color": GATO},
	]
