## Encontrar una carta de tarot escondida en un documento.
##
## Ocho frases del archivo esconden una carta. Pulsar una es el único momento
## en que este juego **tiene color**: el resto es el gris de sistema de
## `EstiloSiga`, y por eso los colores de aquí se declaran en este módulo y no
## en la paleta común. Si el color se volviera un recurso compartido, dejaría
## de significar que has encontrado algo.
##
## El volteo no lo hace el reproductor: no sabe escalar una figura, solo
## moverla. Se hace como se hacía en una máquina de la época —tres planos con
## la carta cada vez más estrecha, hasta el canto— y funciona por el mismo
## motivo por el que funcionaba entonces: a esa velocidad, el ojo lo completa.
##
## Los planos se declaran en el formato común de `Cinematica` y los reproduce
## el reproductor común: este módulo solo aporta el plano de rodaje.
class_name TarotCinematica
extends RefCounted

## El identificador con el que se anotan las vistas. Una sola cinemática para
## las ocho cartas: lo que cambia es el rótulo, no el rodaje. Así la octava
## carta se ve corta, que es justo lo que se quiere de un momento que se repite.
const ID := "tarot-hallazgo"

## La carta, medida desde el centro del lienzo.
const ANCHO := 180.0
const ALTO := 260.0

## Y subida, porque el rótulo del reproductor ocupa la banda inferior: centrada
## a secas, el nombre de la carta se montaba sobre su borde de abajo.
const ALZADA := 56.0

## El dorso es del gris de sistema: todavía no ha pasado nada.
const DORSO := Color("606070")
const DORSO_MARCA := Color("484858")

## Y el frontal no. Este es el color del juego.
const FRENTE := Color("e8c46a")
const FRENTE_MARCA := Color("8e2f4a")

## El canto, en el instante en que la carta está de perfil.
const CANTO := Color("d8d8dc")

## Un plano dura lo que dura. Se pueden saltar todos, siempre.
##
## Cada plano declara su `ancho` y su `cara`; la `figura` en el formato del
## reproductor se construye al resolver, porque una constante no puede llamar
## a una función. `planos_de` es la única superficie pública: estos planos, por
## sí solos, todavía no son un rodaje válido.
const PLANOS := [
	{
		# El dorso, quieto. Lo que hay antes de saber qué has encontrado.
		"tipo": "2d",
		"nombre": "reverso",
		"cara": "dorso",
		"ancho": ANCHO,
		"desde": Vector2(0.0, 18.0),
		"hasta": Vector2(0.0, 0.0),
		"segundos": 0.7,
		"rotulo": "",
		"voz": "",
	},
	{
		# De perfil: la carta ya no es un dorso y todavía no es una carta.
		"tipo": "2d",
		"nombre": "canto",
		"cara": "canto",
		"ancho": 16.0,
		"desde": Vector2(0.0, 0.0),
		"hasta": Vector2(0.0, 0.0),
		"segundos": 0.22,
		"rotulo": "",
		"voz": "",
	},
	{
		# El frontal, con su nombre. El único color del juego.
		"tipo": "2d",
		"nombre": "frontal",
		"cara": "frente",
		"ancho": ANCHO,
		"desde": Vector2(0.0, 0.0),
		"hasta": Vector2(0.0, 0.0),
		"segundos": 1.9,
		"rotulo": "TAROT_ROTULO",
		"voz": "TAROT_VOZ",
	},
	{
		# El remate: la carta se levanta y deja paso a su historia.
		"tipo": "2d",
		"nombre": "entrega",
		"cara": "frente",
		"ancho": ANCHO,
		"desde": Vector2(0.0, 0.0),
		"hasta": Vector2(0.0, -30.0),
		"segundos": 0.7,
		"rotulo": "TAROT_ROTULO",
		"voz": "",
	},
]

## Los colores de cada cara, para no repartir condicionales por el rodaje.
const CARAS := {
	"dorso": [DORSO, DORSO_MARCA],
	"canto": [CANTO, CANTO],
	"frente": [FRENTE, FRENTE_MARCA],
}


## El plano de rodaje ya resuelto para una carta.
##
## Devuelve copias —las hace `Cinematica.resolver`, en profundidad—, así que
## reproducir una cinemática no puede estropear la siguiente.
static func planos_de(carta: Dictionary, vistas: int = 0) -> Array:
	var planos := []
	for declarado in PLANOS:
		var plano: Dictionary = declarado.duplicate(true)
		var colores: Array = CARAS[plano["cara"]]
		plano["figura"] = _carta(float(plano["ancho"]), colores[0], colores[1])
		plano.erase("cara")
		plano.erase("ancho")
		planos.append(plano)

	var nombre: String = carta.get("nombre", "")
	if nombre.is_empty():
		nombre = TranslationServer.translate("TAROT_SIN_NOMBRE")
	return Cinematica.resolver(planos, {"carta": nombre}, vistas)


static func _carta(ancho: float, fondo: Color, marca: Color) -> Array:
	## Un rectángulo de fondo y otro dentro: sin el interior, el dorso y el
	## frontal serían dos rectángulos planos y el volteo no se leería.
	var margen := minf(14.0, ancho / 4.0)
	return [
		{"rect": Rect2(-ancho / 2.0, -ALTO / 2.0 - ALZADA, ancho, ALTO), "color": fondo},
		{
			"rect":
			Rect2(
				-ancho / 2.0 + margen,
				-ALTO / 2.0 - ALZADA + margen,
				ancho - margen * 2.0,
				ALTO - margen * 2.0
			),
			"color": marca,
		},
	]
