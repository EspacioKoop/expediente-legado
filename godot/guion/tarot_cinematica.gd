## Encontrar una carta de tarot escondida en un documento.
##
## Ocho frases del archivo esconden una carta. Pulsar una es el único momento
## en que este juego **tiene color**: el resto es el gris de sistema de
## `EstiloSiga`, y por eso los colores de aquí se declaran en este módulo y no
## en la paleta común. Si el color se volviera un recurso compartido, dejaría
## de significar que has encontrado algo.
##
## Desde #395 el volteo es 3D: la carta tiene dos caras sobre la mesa del
## archivo y la cámara la rodea (ver `decorado`).
##
## Los planos se declaran en el formato común de `Cinematica` y los reproduce
## el reproductor común: este módulo solo aporta el plano de rodaje.
class_name TarotCinematica
extends RefCounted

## El identificador con el que se anotan las vistas. Una sola cinemática para
## las ocho cartas: lo que cambia es el rótulo, no el rodaje. Así la octava
## carta se ve corta, que es justo lo que se quiere de un momento que se repite.
const ID := "tarot-hallazgo"

## La carta, en píxeles de la época: 500 px por metro en el decorado.
const ANCHO := 180.0
const ALTO := 260.0

## El arte final de #645 entra por ID canónico. Mientras ese fichero no exista
## se conserva exactamente el frontal geométrico del corte 3D de #395.
const RUTA_FRENTE := "res://assets/tarot/%s.png"
const RESOLUCION_FRENTE := Vector2i(200, 375)

## El dorso es del gris de sistema: todavía no ha pasado nada.
const DORSO := Color("606070")
const DORSO_MARCA := Color("484858")

## Y el frontal no. Este es el color del juego.
const FRENTE := Color("e8c46a")
const FRENTE_MARCA := Color("8e2f4a")

## El canto, en el instante en que la carta está de perfil.
const CANTO := Color("d8d8dc")

## La carta flota sobre la mesa del archivo, de pie. Tiene dos caras de verdad
## —el dorso mira a -z y el frontal a +z— y el volteo es la cámara dándole la
## vuelta: dorso, canto y frontal son tres posiciones alrededor de la misma
## carta, que es lo que en 2D había que fingir estrechando un rectángulo.
const CENTRO := Vector3(0.0, 1.12, 0.1)
const GROSOR := 0.01

## Un plano dura lo que dura. Se pueden saltar todos, siempre.
const PLANOS := [
	{
		# El dorso, quieto. Lo que hay antes de saber qué has encontrado.
		"tipo": "3d",
		"nombre": "reverso",
		"camara": CENTRO + Vector3(0.15, 0.05, -1.05),
		"mira": CENTRO,
		"segundos": 0.7,
		"rotulo": "",
		"voz": "",
	},
	{
		# De perfil: la carta ya no es un dorso y todavía no es una carta.
		"tipo": "3d",
		"nombre": "canto",
		"camara": CENTRO + Vector3(1.0, 0.02, 0.0),
		"mira": CENTRO,
		"segundos": 0.35,
		"rotulo": "",
		"voz": "",
	},
	{
		# El frontal, con su nombre. El único color del juego.
		"tipo": "3d",
		"nombre": "frontal",
		"camara": CENTRO + Vector3(-0.1, 0.05, 0.95),
		"mira": CENTRO,
		"segundos": 1.9,
		"rotulo": "TAROT_ROTULO",
		"voz": "TAROT_VOZ",
	},
	{
		# El remate: la cámara se aparta y la carta queda sobre el puesto,
		# dejando paso a su historia.
		"tipo": "3d",
		"nombre": "entrega",
		"camara": CENTRO + Vector3(0.0, 0.45, 1.7),
		"mira": CENTRO + Vector3(0, -0.1, 0),
		"segundos": 0.7,
		"rotulo": "TAROT_ROTULO",
		"voz": "",
	},
]


## El plano de rodaje ya resuelto para una carta.
##
## Devuelve copias —las hace `Cinematica.resolver`, en profundidad—, así que
## reproducir una cinemática no puede estropear la siguiente.
static func planos_de(carta: Dictionary, vistas: int = 0) -> Array:
	var decorado := decorado(String(carta.get("id", "")))
	var planos := []
	for declarado in PLANOS:
		var plano: Dictionary = declarado.duplicate(true)
		plano["decorado"] = decorado
		planos.append(plano)

	var nombre: String = carta.get("nombre", "")
	if nombre.is_empty():
		nombre = TranslationServer.translate("TAROT_SIN_NOMBRE")
	return Cinematica.resolver(planos, {"carta": nombre}, vistas)


## La mesa con la carta encima. El frontal se enciende: es el único color
## del juego y tiene que verse aunque la oficina esté en penumbra.
##
## Si existe el PNG canónico de la carta, una superficie UV se coloca apenas
## por delante del frontal geométrico. Si no existe, no se añade nada: el
## placeholder de #395 sigue siendo el fallback y el juego no depende de LFS.
static func decorado(carta_id: String = "") -> Dictionary:
	var ancho := ANCHO / 500.0
	var alto := ALTO / 500.0
	var margen := 0.12
	var cara := func(z: float, tam: Vector3, color: Color, emisivo: bool = false) -> Dictionary:
		return {
			"pos": Vector3(CENTRO.x, CENTRO.y, CENTRO.z + z),
			"tam": tam,
			"color": color,
			"emisivo": emisivo,
		}
	var piezas := [
		cara.call(0.0, Vector3(ancho, alto, GROSOR * 2.0), CANTO),
		cara.call(-GROSOR, Vector3(ancho, alto, 0.004), DORSO),
		cara.call(-GROSOR - 0.003, Vector3(ancho - margen, alto - margen, 0.002), DORSO_MARCA),
		cara.call(GROSOR, Vector3(ancho, alto, 0.004), FRENTE, true),
		cara.call(
			GROSOR + 0.003, Vector3(ancho - margen, alto - margen, 0.002), FRENTE_MARCA, true
		),
	]
	var mesa := MesaCinematica.con(
		piezas,
		[
			{
				"pos": CENTRO + Vector3(0, 0.5, 0.6),
				"color": FRENTE,
				"energia": 1.2,
				"alcance": 3.0,
				"carcasa": false
			}
		]
	)

	var ruta_frontal := "" if carta_id.is_empty() else RUTA_FRENTE % carta_id
	if not ruta_frontal.is_empty() and ResourceLoader.exists(ruta_frontal):
		var alto_arte := alto - margen
		var ancho_arte := alto_arte * float(RESOLUCION_FRENTE.x) / float(RESOLUCION_FRENTE.y)
		mesa["pantallas"] = [
			{
				"pos": CENTRO + Vector3(0, 0, GROSOR + 0.006),
				"tam": Vector2(ancho_arte, alto_arte),
				"fichero": ruta_frontal,
				"resolucion": RESOLUCION_FRENTE,
			}
		]
	return mesa
