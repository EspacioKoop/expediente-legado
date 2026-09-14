## Remates del careo: dos lecturas visuales del mismo expediente ya firmado.
##
## No hay texto de victoria ni de caso resuelto. Ganar significa aguantar el
## careo; perder significa salir de él peor. El expediente aparece en ambos
## remates porque el veredicto ya estaba fijado antes de empezar el duelo.
class_name DueloRemateCinematica
extends RefCounted

const ID_VICTORIA := "duelo-remate-victoria"
const ID_DERROTA := "duelo-remate-derrota"

const COLOR_PAPEL := Color(0.78, 0.75, 0.64)
const COLOR_TINTA := Color(0.16, 0.14, 0.12)
const COLOR_FIGURA := Color(0.48, 0.47, 0.44)


## El remate es deliberadamente 2D y estático: además de ser provisional según
## el roadmap de v0.7, no introduce movimiento de cámara y por tanto conserva
## su lectura también con reducción de movimiento.
static func planos_de(gano: bool, vistas: int = 0) -> Array:
	var figura := _figura_victoria() if gano else _figura_derrota()
	return (
		Cinematica
		. resolver(
			[
				{
					"tipo": "2d",
					"segundos": 1.2,
					"figura": figura,
					"desde": Vector2.ZERO,
					"hasta": Vector2.ZERO,
				},
				{
					"tipo": "2d",
					"segundos": 1.0,
					"figura": _expediente(),
					"desde": Vector2.ZERO,
					"hasta": Vector2.ZERO,
				},
			],
			{},
			vistas
		)
	)


static func id_de(gano: bool) -> String:
	return ID_VICTORIA if gano else ID_DERROTA


static func _expediente() -> Array:
	return [
		{"rect": Rect2(-90, -55, 180, 110), "color": COLOR_PAPEL},
		{"rect": Rect2(-66, -28, 132, 8), "color": COLOR_TINTA},
		{"rect": Rect2(-66, -4, 92, 8), "color": COLOR_TINTA},
		{"rect": Rect2(30, 17, 38, 24), "color": COLOR_TINTA},
	]


static func _figura_victoria() -> Array:
	var piezas := _expediente()
	(
		piezas
		. append_array(
			[
				{"rect": Rect2(-18, -135, 36, 52), "color": COLOR_FIGURA},
				{"rect": Rect2(-32, -83, 64, 105), "color": COLOR_FIGURA},
			]
		)
	)
	return piezas


static func _figura_derrota() -> Array:
	var piezas := _expediente()
	(
		piezas
		. append_array(
			[
				{"rect": Rect2(-92, 82, 52, 36), "color": COLOR_FIGURA},
				{"rect": Rect2(-40, 91, 112, 58), "color": COLOR_FIGURA},
			]
		)
	)
	return piezas
