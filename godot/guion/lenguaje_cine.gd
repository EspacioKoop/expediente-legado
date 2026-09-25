## El lenguaje de cine común a todas las cinemáticas (#395).
##
## El reproductor ya unificaba ritmo, rótulo y salto; lo que no tenía era
## CINE: rodaba con la cámara de juego —75° de campo, todo nítido, cuadro
## 16:9 lleno— y por eso un plano de cinemática se leía como el juego con la
## cámara quieta. Aquí están las cuatro decisiones que lo cambian, como datos y
## funciones puras para que se prueben sin pantalla:
##
## - **Formato panorámico** 2,39:1. Las franjas entran al empezar y salen al
##   terminar, y el cambio de formato es lo que avisa de que el control ya no es
##   del jugador. El rótulo va DENTRO de la franja inferior, como un subtítulo,
##   y no encima de la imagen.
## - **Óptica**: focal más cerrada (50° de campo vertical en lugar de los 75°
##   del gran angular del juego) y profundidad de campo con el foco en lo que la
##   cámara mira: el fondo se suaviza y el sujeto se separa. No más cerrada: los
##   planos se compusieron a 75° y la franja ya recorta arriba y abajo; a 40° el
##   monitor de la entrada llenaba medio cuadro.
## - **Cámara en mano**: una deriva lenta de centímetros, determinista, para que
##   un plano quieto no parezca un fotograma congelado.
## - **Grano y viñeta**, sutiles: la textura de la imagen de cine, no un filtro.
##
## Un plano puede ajustar la óptica con `fov` y `foco` (distancia en metros);
## si no, la hereda. La reducción de movimiento quita la mano y deja las franjas
## puestas sin animarlas: el formato no se mueve, se enmarca.
class_name LenguajeCine
extends RefCounted

const RELACION_PANORAMICA := 2.39
## Cuánto tardan las franjas en entrar o salir.
const SEGUNDOS_FRANJAS := 0.8
const FOV := 50.0
## Profundidad de campo: lo que cae más lejos que el sujeto se desenfoca a
## partir de este margen, y lo que queda delante a partir de este otro.
const MARGEN_FONDO := 1.5
const MARGEN_DELANTE := 0.6
const DESENFOQUE := 0.08
## Amplitud de la cámara en mano, en metros, y su ritmo, en hercios. Menos de
## un centímetro y medio: se nota como vida, no como temblor.
const AMPLITUD_MANO := 0.012
const RITMO_MANO := 0.23
const GRANO := 0.045
const VINETA := 0.35


## Alto de CADA franja, en píxeles, para un cuadro de [param tamano]. Cero si
## la pantalla ya es más panorámica que el formato de cine.
static func alto_franja(tamano: Vector2) -> float:
	if tamano.x <= 0.0 or tamano.y <= 0.0:
		return 0.0
	var alto_imagen := tamano.x / RELACION_PANORAMICA
	return maxf(0.0, (tamano.y - alto_imagen) / 2.0)


## Cuánto han entrado las franjas (0 fuera, 1 del todo) a [param segundos] de
## empezar la cinemática y a [param restantes] de acabar. Con reducción de
## movimiento están puestas desde el primer fotograma y hasta el último.
static func apertura_franjas(segundos: float, restantes: float, reducir: bool) -> float:
	if reducir:
		return 1.0
	var entrada := clampf(segundos / SEGUNDOS_FRANJAS, 0.0, 1.0)
	var salida := clampf(restantes / SEGUNDOS_FRANJAS, 0.0, 1.0)
	return _suave(minf(entrada, salida))


static func fov_de(plano: Dictionary) -> float:
	return clampf(float(plano.get("fov", FOV)), 15.0, 90.0)


## Distancia de foco de un plano: la que declare, o la que hay de la cámara a
## lo que mira, que es casi siempre el sujeto.
static func foco_de(plano: Dictionary, camara: Vector3, mira: Vector3) -> float:
	if plano.has("foco"):
		return maxf(0.1, float(plano["foco"]))
	return maxf(0.1, camara.distance_to(mira))


## Desplazamiento de la cámara en mano a [param segundos] del plano. Suma de
## senos de periodos no múltiplos: no se repite a la vista y es igual en cada
## pase, que es lo que permite repetir una partida (#147).
static func mano(segundos: float, reducir: bool) -> Vector3:
	if reducir:
		return Vector3.ZERO
	var t := segundos * TAU * RITMO_MANO
	return (
		Vector3(
			sin(t) * 0.6 + sin(t * 2.3 + 1.1) * 0.4,
			sin(t * 1.7 + 0.4) * 0.5 + sin(t * 3.1) * 0.2,
			sin(t * 0.8 + 2.0) * 0.3
		)
		* AMPLITUD_MANO
	)


## Atributos de cámara con la profundidad de campo de un plano.
static func atributos(foco: float) -> CameraAttributesPractical:
	var atributos := CameraAttributesPractical.new()
	atributos.dof_blur_far_enabled = true
	atributos.dof_blur_far_distance = foco + MARGEN_FONDO
	atributos.dof_blur_far_transition = foco
	atributos.dof_blur_near_enabled = foco > MARGEN_DELANTE * 2.0
	atributos.dof_blur_near_distance = maxf(0.05, foco - MARGEN_DELANTE)
	atributos.dof_blur_near_transition = MARGEN_DELANTE
	atributos.dof_blur_amount = DESENFOQUE
	return atributos


static func _suave(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)
