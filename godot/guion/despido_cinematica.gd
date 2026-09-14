## Reasignación: salir del puesto y empezar otra vida laboral.
##
## Cuando esta escena empieza, `Acusacion.perder_vida` ya ha aplicado y guardado
## el cambio de vuelta. La cinemática no reinicia nada: enseña que la persona
## sale, que el expediente firmado se queda en la mesa y que lo personal cruza
## a la vida siguiente.
class_name DespidoCinematica
extends RefCounted

const ID := "despido-reasignacion"

const PAPEL := Color("dedbd2")
const TINTA := Color("3e3e42")
const MESA := Color("726756")
const FIGURA := Color("77736b")
const ESCOLTA := Color("4b4b4b")
const GATO := Color("5c5147")


## v0.7 usa un corte 2D provisional, como el resto de cinemáticas de la fase.
## `gato_presente` solo decide si aparece la pequeña silueta que recuerda que
## sigue siendo tuyo; si ya se había ido, la escena no lo resucita visualmente.
## `voz_cunado` es una CLAVE de traducción y solo aparece durante la salida: el
## cuñado es la única persona que rompe el silencio del despido (#81).
static func planos_de(gato_presente: bool, vistas: int = 0, voz_cunado: String = "") -> Array:
	return (
		Cinematica
		. resolver(
			[
				{
					"tipo": "2d",
					"segundos": 1.15,
					"figura": _puesto_que_queda(),
					"desde": Vector2.ZERO,
					"hasta": Vector2.ZERO,
				},
				{
					"tipo": "2d",
					"segundos": 1.25,
					"figura": _salida_acompanada(),
					"desde": Vector2.ZERO,
					"hasta": Vector2.ZERO,
					"voz": voz_cunado,
				},
				{
					"tipo": "2d",
					"segundos": 1.1,
					"figura": _nuevo_dia(gato_presente),
					"desde": Vector2.ZERO,
					"hasta": Vector2.ZERO,
				},
			],
			{},
			vistas
		)
	)


## La carpeta sellada permanece físicamente en el puesto: cambia la persona,
## no el veredicto que dejó firmado.
static func _puesto_que_queda() -> Array:
	return [
		{"rect": Rect2(-180, 58, 360, 34), "color": MESA},
		{"rect": Rect2(-92, -30, 184, 88), "color": PAPEL},
		{"rect": Rect2(-66, -6, 112, 7), "color": TINTA},
		{"rect": Rect2(22, 18, 46, 24), "color": TINTA},
	]


## Dos figuras escoltan a la persona hacia fuera. No hay celebración ni caída:
## la misma composición sirve como castigo y, tras perder la casa, como alivio.
static func _salida_acompanada() -> Array:
	return [
		{"rect": Rect2(-28, -72, 56, 116), "color": FIGURA},
		{"rect": Rect2(-116, -62, 42, 104), "color": ESCOLTA},
		{"rect": Rect2(74, -62, 42, 104), "color": ESCOLTA},
		{"rect": Rect2(-160, 44, 320, 18), "color": TINTA},
	]


## Una credencial limpia sustituye a la anterior. El pequeño gato solo aparece
## si seguía presente antes del despido; es continuidad personal, no laboral.
static func _nuevo_dia(gato_presente: bool) -> Array:
	var figura := [
		{"rect": Rect2(-96, -58, 192, 116), "color": PAPEL},
		{"rect": Rect2(-68, -30, 92, 8), "color": TINTA},
		{"rect": Rect2(-68, -6, 136, 8), "color": TINTA},
		{"rect": Rect2(-68, 18, 72, 8), "color": TINTA},
	]
	if gato_presente:
		(
			figura
			. append_array(
				[
					{"rect": Rect2(116, 18, 48, 28), "color": GATO},
					{"rect": Rect2(126, -2, 24, 24), "color": GATO},
					{"rect": Rect2(112, -8, 12, 14), "color": GATO},
					{"rect": Rect2(150, -8, 12, 14), "color": GATO},
				]
			)
		)
	return figura
