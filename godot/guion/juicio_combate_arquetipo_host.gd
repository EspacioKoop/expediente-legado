## Traducción pura de la política de arquetipos (#1771) a primitivas del duelo
## onírico de JuicioCombate3D.
##
## JuicioCombateArquetipos decide la intención; esta capa responde a lo que el
## host necesita saber en cada fotograma: si la figura lleva arquetipo, hacia
## dónde gira mientras guarda, si el jugador la flanquea y si un golpe concreto
## queda bloqueado. No monta nodos, no toca determinación ni consecuencias.
##
## Primer corte: solo el bloqueador. El hostigador necesita un aviso en línea y
## el enjambre varios cuerpos, y ninguno cabe todavía en el duelo 1 contra 1.
class_name JuicioCombateArquetipoHost
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")

## Arquetipos que el host sabe representar. Elegir otro dejaría una política
## viva sin cuerpo que la muestre.
const SOPORTADOS := [ARQUETIPOS.BLOQUEADOR]

## Medio arco frontal de la guardia: ±60° respecto a donde mira la figura.
## Fuera de ese cono el golpe entra por el flanco.
const COSENO_ARCO_FRONTAL := 0.5

## Giro máximo mientras guarda, en rad/s. El jugador rodea a ~3 rad/s a la
## distancia de golpe del rival, así que flanquear exige moverse con intención
## pero nunca precisión extrema.
const GIRO_GUARDIA := 1.6


## Arquetipo de una figura onírica concreta, estable para la misma partida.
##
## Solo el plano del sueño recibe arquetipos: la realidad y la ventanilla ritual
## conservan su duelo clásico. Una figura sin id tampoco se inventa uno.
static func elegir(id_figura: String, raiz: int, plano: String) -> String:
	var id := id_figura.strip_edges()
	if plano != CombateContextual.PLANO_SUENO or id.is_empty():
		return ""
	# La mitad de las figuras conservan el duelo clásico: la variedad viene de
	# alternar cuerpos, no de convertir todos los sueños en el mismo muro.
	var tirada := Azar.derivar_texto(raiz, "combate", "arquetipo_1771:%s" % id)
	return ARQUETIPOS.BLOQUEADOR if tirada % 2 == 0 else ""


static func soportado(tipo: String) -> bool:
	return SOPORTADOS.has(tipo)


static func flanqueado(
	posicion_rival: Vector3, rotacion_y_rival: float, posicion_jugador: Vector3
) -> bool:
	var hacia := posicion_jugador - posicion_rival
	hacia.y = 0.0
	if hacia.length() < 0.01:
		return false
	var frente := Vector3(sin(rotacion_y_rival), 0.0, cos(rotacion_y_rival))
	return frente.dot(hacia.normalized()) < COSENO_ARCO_FRONTAL


## Contexto que JuicioCombateArquetipos.avanzar espera para el bloqueador.
static func contexto(
	posicion_rival: Vector3,
	rotacion_y_rival: float,
	posicion_jugador: Vector3,
	guardia_rota: bool,
) -> Dictionary:
	return {
		"flanqueado": flanqueado(posicion_rival, rotacion_y_rival, posicion_jugador),
		"guardia_rota": guardia_rota,
	}


## Orientación tras un fotograma. La figura sigue al jugador a ritmo limitado,
## salvo en la apertura: ahí se queda mirando donde estaba para que la ventana
## sea legible. Recuperar también gira; si no, quien se planta a la espalda
## volvería a encontrar la guardia de cara a la nada y la tendría abierta para
## siempre.
static func girar(
	unidad: Dictionary,
	rotacion_y_rival: float,
	posicion_rival: Vector3,
	posicion_jugador: Vector3,
	delta: float,
) -> float:
	if String(unidad.get("tipo", "")) != ARQUETIPOS.BLOQUEADOR:
		return rotacion_y_rival
	if String(unidad.get("estado", "")) == ARQUETIPOS.APERTURA:
		return rotacion_y_rival
	var hacia := posicion_jugador - posicion_rival
	hacia.y = 0.0
	if hacia.length() < 0.01:
		return rotacion_y_rival
	var objetivo := atan2(hacia.x, hacia.z)
	var diferencia := wrapf(objetivo - rotacion_y_rival, -PI, PI)
	var paso := GIRO_GUARDIA * maxf(0.0, delta)
	return rotacion_y_rival + clampf(diferencia, -paso, paso)


## Qué hace la guardia con un golpe que ya alcanza a la figura.
##
## Un golpe fuerte de frente no hace daño pero rompe la guardia: es la vía
## para no tener que esperar ni rodear. Por el flanco, o fuera de la guardia,
## el golpe entra como en el duelo clásico.
static func golpe(unidad: Dictionary, flanco: bool, fuerte: bool) -> Dictionary:
	var resultado := {"bloqueado": false, "rompe_guardia": false}
	if String(unidad.get("tipo", "")) != ARQUETIPOS.BLOQUEADOR:
		return resultado
	if String(unidad.get("estado", "")) != ARQUETIPOS.GUARDIA or flanco:
		return resultado
	resultado["bloqueado"] = true
	resultado["rompe_guardia"] = fuerte
	return resultado


## La apertura es la ventana del jugador: mientras dura, la figura no empieza
## un ataque propio. En guardia y recuperación sí puede, como el rival clásico.
static func permite_iniciar_ataque(unidad: Dictionary) -> bool:
	if String(unidad.get("tipo", "")) != ARQUETIPOS.BLOQUEADOR:
		return true
	return String(unidad.get("estado", "")) != ARQUETIPOS.APERTURA


## Contexto que JuicioCombateArquetipos.avanzar espera para el hostigador:
## distancia en plano y rumbo hacia el jugador, con la misma convención de
## `girar` (0 mira hacia +Z). Con distancia casi cero no hay rumbo legible:
## se fija 0.0 para que la política tenga un valor estable sin NaN ni tirones.
static func contexto_hostigador(
	posicion_hostigador: Vector3,
	posicion_jugador: Vector3,
) -> Dictionary:
	var hacia := posicion_jugador - posicion_hostigador
	hacia.y = 0.0
	var distancia := hacia.length()
	var rumbo := 0.0
	if distancia >= 0.01:
		rumbo = atan2(hacia.x, hacia.z)
	return {"distancia": distancia, "rumbo_objetivo": rumbo}


## Dirección 3D de la línea de ataque a partir de un rumbo congelado. Durante
## `telegrafiar` la política congela `rumbo_bloqueado`, así que la línea debe
## salir solo de ese ángulo: si el jugador se mueve después, la línea no gira.
static func direccion_linea(rumbo_bloqueado: float) -> Vector3:
	return Vector3(sin(rumbo_bloqueado), 0.0, cos(rumbo_bloqueado))
