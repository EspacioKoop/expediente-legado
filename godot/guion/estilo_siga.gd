## El aspecto de SIGA-98: un programa de escritorio de finales de los 90.
##
## Port de `legacy-theme.css`, donde el relieve eran `border-style: outset` e
## `inset`. Aquí se dibuja, porque un StyleBoxFlat solo admite UN color de
## borde y este bisel necesita dos: la luz arriba y a la izquierda, la sombra
## abajo y a la derecha. Invertir esos dos colores es toda la diferencia entre
## un botón que sobresale y un hueco donde va texto — el mismo vocabulario de
## relieve que usa la piel de los muros de la nave en el otro proyecto.
class_name EstiloSiga
extends RefCounted

const GRIS := Color("c0c0c0")  ## el gris de sistema de la época
const GRIS_CLARO := Color("dfdfdf")  ## la luz del bisel
const GRIS_OSCURO := Color("808080")  ## su sombra
const NEGRO := Color("000000")
const BLANCO := Color("ffffff")
const AZUL_TITULO := Color("000080")  ## la barra de título activa
const AZUL_ENLACE := Color("0000aa")
const AMARILLO_VISTO := Color("c8c800")  ## una frase gatillo ya leída
const GRIS_TEXTO := Color("808080")

const GROSOR := 2


## Dibuja el bisel sobre un rectángulo. [param saliente] a false lo hunde.
static func dibujar_bisel(lienzo: CanvasItem, rect: Rect2, fondo: Color, saliente: bool) -> void:
	var luz := GRIS_CLARO if saliente else GRIS_OSCURO
	var sombra := GRIS_OSCURO if saliente else GRIS_CLARO
	lienzo.draw_rect(rect, fondo)
	for i in GROSOR:
		var d := float(i)
		# Arriba e izquierda.
		lienzo.draw_line(
			rect.position + Vector2(d, d), rect.position + Vector2(rect.size.x - d, d), luz
		)
		lienzo.draw_line(
			rect.position + Vector2(d, d), rect.position + Vector2(d, rect.size.y - d), luz
		)
		# Abajo y derecha.
		lienzo.draw_line(
			rect.position + Vector2(d, rect.size.y - 1.0 - d),
			rect.position + Vector2(rect.size.x - d, rect.size.y - 1.0 - d),
			sombra
		)
		lienzo.draw_line(
			rect.position + Vector2(rect.size.x - 1.0 - d, d),
			rect.position + Vector2(rect.size.x - 1.0 - d, rect.size.y - d),
			sombra
		)


## El tema de toda la interfaz.
##
## Lo que delata la época no es tanto la forma de la letra como el SUAVIZADO:
## una tipografía moderna con antialiasing y posicionamiento subpíxel se ve
## limpia y contemporánea aunque el marco sea gris con biseles. Apagando las
## dos cosas y forzando el hinting, los trazos caen en la rejilla de píxeles y
## el texto se lee como el de un programa de 1998 — sin traer al repositorio ni
## un fichero de fuente.
## La de la interfaz. Las de sistema de la época primero; en cualquier máquina
## donde no estén, la que haya. Que la elección degrade es lo que evita traer un
## binario al repositorio.
static func fuente() -> SystemFont:
	return _sin_suavizar(["MS Sans Serif", "Tahoma", "Verdana", "DejaVu Sans", "Sans-Serif"])


## La del cuerpo de un documento: monoespaciada, porque es un volcado de un
## sistema de texto y no una página maquetada.
##
## Sale de dentro de `tema()` al llegar su segundo consumidor: las frases que el
## sueño escribe en las paredes (#87) van en la letra del documento del que
## salen, que es media parte de reconocerlas.
static func fuente_mono() -> SystemFont:
	return _sin_suavizar(["Courier New", "DejaVu Sans Mono", "Liberation Mono", "Monospace"])


static func _sin_suavizar(nombres: Array) -> SystemFont:
	var tipo := SystemFont.new()
	tipo.font_names = PackedStringArray(nombres)
	tipo.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	tipo.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	tipo.hinting = TextServer.HINTING_NORMAL
	tipo.allow_system_fallback = true
	return tipo


static func tema() -> Theme:
	var fuente := fuente()
	var mono := fuente_mono()
	var tema := Theme.new()
	tema.default_font = fuente
	tema.default_font_size = 14
	tema.set_font("mono_font", "RichTextLabel", mono)
	return tema
